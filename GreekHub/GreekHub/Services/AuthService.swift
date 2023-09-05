import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case noChapterFound
    case notApproved
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:       return "Please enter a valid email address."
        case .wrongPassword:      return "Incorrect password. Please try again."
        case .userNotFound:       return "No account found with that email."
        case .emailAlreadyInUse:  return "An account with this email already exists."
        case .weakPassword:       return "Password must be at least 6 characters."
        case .noChapterFound:     return "No chapter found. Contact your administrator."
        case .notApproved:        return "Your account is pending officer approval."
        case .unknown(let msg):   return msg
        }
    }

    static func from(_ error: Error) -> AuthError {
        let code = AuthErrorCode(_nsError: error as NSError)
        switch code.code {
        case .invalidEmail:         return .invalidEmail
        case .wrongPassword:        return .wrongPassword
        case .userNotFound:         return .userNotFound
        case .emailAlreadyInUse:    return .emailAlreadyInUse
        case .weakPassword:         return .weakPassword
        default:                    return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Auth Service

final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isLoading = false

    private let auth = Auth.auth()
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
        }
    }

    deinit {
        if let handle = authHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    var isLoggedIn: Bool { firebaseUser != nil }
    var currentUID: String? { firebaseUser?.uid }

    // MARK: Sign In

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    // MARK: Sign Up

    func signUp(email: String, password: String) async throws -> String {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user.uid
    }

    // MARK: Sign Out

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: Reset Password

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}
