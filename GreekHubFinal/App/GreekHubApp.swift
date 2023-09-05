import SwiftUI
import FirebaseCore

@main
struct GreekHubApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isCheckingAuth {
                    SplashView()
                } else if authVM.isLoggedIn {
                    MainTabView()
                        .environmentObject(authVM)
                } else {
                    LoginView()
                        .environmentObject(authVM)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.3), value: authVM.isLoggedIn)
        }
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.ghGold.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Circle()
                        .stroke(Color.ghGold.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 90, height: 90)
                    Text("ΓΗ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.ghGold)
                }
                ProgressView().tint(.ghGold)
            }
        }
    }
}
