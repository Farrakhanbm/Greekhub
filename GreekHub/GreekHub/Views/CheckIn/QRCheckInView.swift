import SwiftUI
import AVFoundation

// MARK: - Officer QR Display View

struct EventQRView: View {
    let event: ChapterEvent
    @StateObject private var vm = CheckInViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showCheckIns = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)

                HStack {
                    Button("Done") { dismiss() }
                        .font(.ghCallout).foregroundColor(.ghGold)
                    Spacer()
                    Text("Check-In QR").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Done").font(.ghCallout).foregroundColor(.clear)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Event info
                        VStack(spacing: 6) {
                            Text(event.title)
                                .font(.ghTitle2)
                                .foregroundColor(.ghText)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.ghGold)
                                Text("+\(event.pointValue) pts on scan")
                                    .font(.ghCaption)
                                    .foregroundColor(.ghGold)
                            }
                        }
                        .padding(.top, 8)

                        // QR code
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 260, height: 260)
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)

                            if let qr = vm.qrImage {
                                Image(uiImage: qr)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                ProgressView().tint(.ghTextMuted)
                            }
                        }

                        Text("Display this on your phone at the door.\nMembers scan to check in and earn points.")
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        // Who's checked in
                        Button {
                            showCheckIns.toggle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.fill.checkmark")
                                    .font(.system(size: 14))
                                    .foregroundColor(.ghGreen)
                                Text("View check-ins")
                                    .font(.ghCallout)
                                    .foregroundColor(.ghText)
                                Spacer()
                                Image(systemName: showCheckIns ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.ghTextMuted)
                            }
                            .padding(14)
                            .ghCard()
                        }
                        .padding(.horizontal, 4)

                        // Keep screen on hint
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.ghGold)
                            Text("Turn off auto-lock in Settings → Display to keep this visible.")
                                .font(.ghCaption)
                                .foregroundColor(.ghTextMuted)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear { vm.generateQR(for: event) }
    }
}

// MARK: - Member QR Scanner View

struct QRScannerView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm       = CheckInViewModel()
    @StateObject private var scanner  = QRScannerCoordinator()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera feed
            if vm.scanResult == .idle || vm.scanResult == .scanning {
                CameraPreviewView(coordinator: scanner)
                    .ignoresSafeArea()
                    .onAppear {
                        scanner.onCodeScanned = { code in
                            vm.processScannedCode(code, user: authVM.currentUser)
                        }
                        scanner.startSession()
                    }
                    .onDisappear { scanner.stopSession() }

                // Overlay
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(20)
                        Spacer()
                    }

                    Spacer()

                    // Scan frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.ghGold, lineWidth: 2.5)
                            .frame(width: 240, height: 240)

                        // Corner accents
                        ForEach(0..<4, id: \.self) { i in
                            CornerAccent()
                                .rotationEffect(.degrees(Double(i) * 90))
                        }
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Text(vm.scanResult == .scanning ? "Checking in..." : "Point camera at event QR code")
                            .font(.ghHeadline)
                            .foregroundColor(.white)
                        if vm.scanResult == .scanning {
                            ProgressView().tint(.ghGold)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }

            // Result overlay
            if case .success(let title, let pts) = vm.scanResult {
                ScanResultView(
                    icon: "checkmark.circle.fill",
                    color: .ghGreen,
                    headline: "Checked in!",
                    detail: "\(title)",
                    badge: "+\(pts) pts"
                ) {
                    vm.resetScan()
                    dismiss()
                }
            }

            if case .alreadyCheckedIn(let title) = vm.scanResult {
                ScanResultView(
                    icon: "checkmark.seal.fill",
                    color: .ghGold,
                    headline: "Already checked in",
                    detail: title,
                    badge: nil
                ) {
                    vm.resetScan()
                    dismiss()
                }
            }

            if case .error(let msg) = vm.scanResult {
                ScanResultView(
                    icon: "xmark.circle.fill",
                    color: .ghRed,
                    headline: "Check-in failed",
                    detail: msg,
                    badge: nil
                ) {
                    vm.resetScan()
                }
            }
        }
    }
}

// MARK: - Scan Result Overlay

struct ScanResultView: View {
    let icon: String
    let color: Color
    let headline: String
    let detail: String
    let badge: String?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundColor(color)

                VStack(spacing: 8) {
                    Text(headline)
                        .font(.ghTitle)
                        .foregroundColor(.white)

                    Text(detail)
                        .font(.ghCallout)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(color)
                    }
                }

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.ghHeadline)
                        .foregroundColor(.black)
                        .frame(width: 160, height: 50)
                        .background(color)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: true)
    }
}

// MARK: - Corner accent shape

struct CornerAccent: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: -120, y: -120))
            path.addLine(to: CGPoint(x: -100, y: -120))
            path.move(to: CGPoint(x: -120, y: -120))
            path.addLine(to: CGPoint(x: -120, y: -100))
        }
        .stroke(Color.ghGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .frame(width: 240, height: 240)
    }
}

// MARK: - AVFoundation Camera

class QRScannerCoordinator: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var hasScanned = false

    let session = AVCaptureSession()

    func startSession() {
        hasScanned = false
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            guard
                let device = AVCaptureDevice.default(for: .video),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { return }

            self.session.addInput(input)
            let output = AVCaptureMetadataOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.qr]
            }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stopSession() {
        session.stopRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasScanned,
              let obj    = objects.first as? AVMetadataMachineReadableCodeObject,
              let string = obj.stringValue
        else { return }
        hasScanned = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onCodeScanned?(string)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let coordinator: QRScannerCoordinator

    func makeUIView(context: Context) -> UIView {
        let view   = UIView()
        let layer  = AVCaptureVideoPreviewLayer(session: coordinator.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame        = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Check-In Button on Event Detail

struct CheckInButton: View {
    let event: ChapterEvent
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showScanner = false

    var body: some View {
        Button {
            showScanner = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 16))
                Text("Scan to Check In")
                    .font(.ghHeadline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.ghGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView().environmentObject(authVM)
        }
    }
}
