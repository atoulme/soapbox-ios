import Foundation
import KeychainAccess
import UIWindowTransitions

protocol AuthenticationInteractorOutput {
    func present(error: AuthenticationInteractor.AuthenticationError)
    func present(state: AuthenticationInteractor.AuthenticationState)
    func presentLoggedInView()
}

class AuthenticationInteractor: AuthenticationViewControllerOutput {
    private let output: AuthenticationInteractorOutput
    private let api: APIClient

    private var token: String?

    private var image: UIImage?

    enum AuthenticationState: Int {
        case getStarted, login, pin, registration, requestNotifications, follow, success
    }

    enum AuthenticationError {
        case invalidEmail, invalidPin, invalidUsername, usernameTaken, missingProfileImage, general
    }

    init(output: AuthenticationInteractorOutput, api: APIClient) {
        self.output = output
        self.api = api
    }

    func login(email: String?) {
        guard var input = email else {
            return output.present(error: .invalidEmail)
        }

        input = input.trimmingCharacters(in: .whitespaces)
        guard isValidEmail(input) else {
            return output.present(error: .invalidEmail)
        }

        api.login(email: input) { result in
            switch result {
            case .failure:
                self.output.present(error: .general)
            case let .success(token):
                self.token = token
                self.output.present(state: .pin)
            }
        }
    }

    func submitPin(pin: String?) {
        guard let input = pin else {
            return output.present(error: .invalidPin)
        }

        api.submitPin(token: token!, pin: input) { result in
            switch result {
            case let .failure(error):
                switch error {
                case let .endpoint(response):
                    if response.code == .incorrectPin {
                        return self.output.present(error: .invalidPin)
                    }
                default:
                    break
                }

                return self.output.present(error: .general)
            case let .success(response):
                switch response.0 {
                case .success:
                    guard let user = response.1, let expires = response.2 else {
                        return self.output.present(error: .general)
                    }

                    self.store(token: self.token!, expires: expires, user: user)

                    NotificationManager.shared.requestAuthorization()

                    DispatchQueue.main.async {
                        self.output.presentLoggedInView()
                    }
                case .register:
                    self.output.present(state: .registration)
                }
            }
        }
    }

    func register(username: String?, displayName: String?, image: UIImage?) {
        guard let usernameInput = username, isValidUsername(usernameInput) else {
            return output.present(error: .invalidUsername)
        }

        guard let profileImage = image else {
            return output.present(error: .missingProfileImage)
        }

        api.register(token: token!, username: usernameInput, displayName: displayName ?? usernameInput, image: profileImage) { result in
            switch result {
            case let .failure(error):
                switch error {
                case let .endpoint(response):
                    if response.code == .usernameAlreadyExists {
                        return self.output.present(error: .usernameTaken)
                    }
                default:
                    break
                }

                return self.output.present(error: .general)
            case let .success((user, expires)):
                self.store(token: self.token!, expires: expires, user: user)
                DispatchQueue.main.async {
                    self.output.present(state: .requestNotifications)

                    NotificationManager.shared.delegate = self
                    NotificationManager.shared.requestAuthorization()
                }
            }
        }
    }

    func follow(users: [Int]) {
        if users.count == 0 {
            return output.present(state: .success)
        }

        api.multifollow(users: users, callback: { result in
            switch result {
            case .failure:
                self.output.present(error: .general)
                self.output.present(state: .success)
            case .success:
                self.output.present(state: .success)
            }
        })
    }

    private func isValidUsername(_ username: String) -> Bool {
        if username.count >= 100 || username.count < 3 {
            return false
        }

        let usernameRegexEx = "^([A-Za-z0-9_]+)*$"

        let usernamePred = NSPredicate(format: "SELF MATCHES %@", usernameRegexEx)
        return usernamePred.evaluate(with: username)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func store(token: String, expires: Int, user: APIClient.User) {
        guard let identifier = Bundle.main.bundleIdentifier else {
            fatalError("no identifier")
        }

        let keychain = Keychain(service: identifier)

        try? keychain.set(token, key: "token")
        try? keychain.set(String(Int(Date().timeIntervalSince1970) + expires), key: "expiry")

        UserStore.store(user: user)
    }
}

extension AuthenticationInteractor: NotificationManagerDelegate {
    func deviceTokenFailedToSet() {
        output.present(state: .follow)
    }

    func deviceTokenWasSet() {
        output.present(state: .follow)
    }
}
