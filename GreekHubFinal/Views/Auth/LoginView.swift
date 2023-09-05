import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email        = ""
    @State private var password     = ""
    @State private var showPassword = false
    @State private var showRegister = false
    @State private var showReset    = false
    @State private var resetEmail   = ""
    @FocusState private var focus: LoginField?

    enum LoginField { case email, password }

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.ghGold.opacity(0.15)).frame(width: 90, height: 90)
                            Circle().stroke(Color.ghGold.opacity(0.4), lineWidth: 1.5).frame(width: 90, height: 90)
                            Text("ΓΗ").font(.system(size: 32, weight: .bold)).foregroundColor(.ghGold)
                        }
                        Text("GreekHub").font(.ghLargeTitle).foregroundColor(.ghText)
                        Text("Your chapter. Connected.").font(.ghCallout).foregroundColor(.ghTextMuted)
                    }
                    .padding(.bottom, 52)

                    VStack(spacing: 16) {
                        GHTextField(label: "Email", placeholder: "your@email.edu", text: $email, isFocused: focus == .email)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                            .focused($focus, equals: .email)

                        GHSecureField(label: "Password", text: $password,
                                      showPassword: $showPassword, isFocused: focus == .password)
                            .focused($focus, equals: .password)

                        if let err = authVM.errorMessage {
                            Text(err).font(.ghCaption).foregroundColor(.ghRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack {
                            Spacer()
                            Button("Forgot password?") { showReset = true }
                                .font(.ghCaption).foregroundColor(.ghGold)
                        }

                        GHPrimaryButton(label: "Sign In", isLoading: authVM.isLoading) {
                            focus = nil
                            authVM.login(email: email, password: password)
                        }
                        .padding(.top, 4)

                        Divider().background(Color.ghBorder).padding(.vertical, 8)

                        Button { showRegister = true } label: {
                            HStack(spacing: 4) {
                                Text("New to GreekHub?").font(.ghCallout).foregroundColor(.ghTextMuted)
                                Text("Request Access").font(.ghCallout).foregroundColor(.ghGold)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(authVM)
        }
        .alert("Reset Password", isPresented: $showReset) {
            TextField("Email address", text: $resetEmail)
                .keyboardType(.emailAddress).autocapitalization(.none)
            Button("Send Reset") { authVM.sendPasswordReset(email: resetEmail) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email and we'll send a reset link.")
        }
    }
}

// MARK: - Register View

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name        = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var chapter     = ""
    @State private var pledgeClass = ""
    @State private var major       = ""
    @State private var year        = "Freshman"

    private let years = ["Freshman", "Sophomore", "Junior", "Senior", "Graduate"]

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)

                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Create Account").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Text("Cancel").font(.ghCallout).foregroundColor(.clear)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        SectionLabel("Account")
                        GHTextField(label: "Full Name",  placeholder: "Marcus Webb",       text: $name)
                        GHTextField(label: "Email",       placeholder: "you@email.edu",     text: $email)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                        GHTextField(label: "Password",   placeholder: "6+ characters",     text: $password)

                        SectionLabel("Chapter Info").padding(.top, 8)
                        GHTextField(label: "Chapter",      placeholder: "Alpha Phi Alpha — Theta", text: $chapter)
                        GHTextField(label: "Pledge Class", placeholder: "Fall 2022",        text: $pledgeClass)
                        GHTextField(label: "Major",        placeholder: "Computer Science", text: $major)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Year").font(.ghCaption).foregroundColor(.ghTextMuted)
                            Picker("Year", selection: $year) {
                                ForEach(years, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        if let err = authVM.errorMessage {
                            Text(err).font(.ghCaption).foregroundColor(.ghRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GHPrimaryButton(label: "Create Account", isLoading: authVM.isLoading) {
                            authVM.register(name: name, email: email, password: password,
                                            chapter: chapter, pledgeClass: pledgeClass,
                                            major: major, year: year)
                        }
                        .padding(.top, 8).padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24).padding(.top, 20)
                }
            }
        }
        .onChange(of: authVM.isLoggedIn) { loggedIn in
            if loggedIn { dismiss() }
        }
    }
}

// MARK: - Reusable Form Components

struct GHTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.ghTextMuted)
                }
                .foregroundColor(.ghText)
                .padding()
                .background(Color.ghSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isFocused ? Color.ghGold.opacity(0.6) : Color.ghBorder,
                                lineWidth: isFocused ? 1 : 0.5)
                )
        }
    }
}

struct GHSecureField: View {
    let label: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
            HStack {
                Group {
                    if showPassword {
                        TextField("", text: $text)
                            .placeholder(when: text.isEmpty) { Text("••••••••").foregroundColor(.ghTextMuted) }
                    } else {
                        SecureField("", text: $text)
                            .placeholder(when: text.isEmpty) { Text("••••••••").foregroundColor(.ghTextMuted) }
                    }
                }
                .foregroundColor(.ghText)
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 14)).foregroundColor(.ghTextMuted)
                }
            }
            .padding()
            .background(Color.ghSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isFocused ? Color.ghGold.opacity(0.6) : Color.ghBorder,
                            lineWidth: isFocused ? 1 : 0.5)
            )
        }
    }
}

struct GHPrimaryButton: View {
    let label: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading { ProgressView().tint(.black) }
                else { Text(label).font(.ghHeadline).foregroundColor(.black) }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.ghGold)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isLoading)
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold)).kerning(0.8)
            .foregroundColor(.ghTextMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func placeholder<C: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> C) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}
