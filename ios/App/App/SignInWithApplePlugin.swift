import Foundation
import Capacitor
import AuthenticationServices
import UIKit

@objc(SignInWithApplePlugin)
public class SignInWithApplePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SignInWithApplePlugin"
    public let jsName = "SignInWithApple"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "signIn",           returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCredentialState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deleteAccount",    returnType: CAPPluginReturnPromise)
    ]

    private let userIDKey = "wspuffer.siwa.userid"
    private var pendingCall: CAPPluginCall?
    private weak var presentationDelegate: SiwAPresenter?

    // MARK: - Sign in

    @objc func signIn(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let provider = ASAuthorizationAppleIDProvider()
            let request  = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let bridge = SiwAPresenter(window: self.bridge?.viewController?.view?.window)
            self.presentationDelegate = bridge
            controller.delegate = bridge
            controller.presentationContextProvider = bridge
            bridge.onComplete = { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let payload):
                    if let uid = payload["userID"] as? String {
                        UserDefaults.standard.set(uid, forKey: self.userIDKey)
                    }
                    call.resolve(payload)
                case .failure(let error):
                    call.reject(error.localizedDescription)
                }
            }
            controller.performRequests()
        }
    }

    // MARK: - Credential state

    @objc func getCredentialState(_ call: CAPPluginCall) {
        guard let userID = call.getString("userID")
                ?? UserDefaults.standard.string(forKey: userIDKey) else {
            call.resolve(["state": "notFound", "authenticated": false])
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { state, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            let mapped: String
            switch state {
            case .authorized:      mapped = "authorized"
            case .revoked:         mapped = "revoked"
            case .notFound:        mapped = "notFound"
            case .transferred:     mapped = "transferred"
            @unknown default:      mapped = "unknown"
            }
            call.resolve([
                "state": mapped,
                "authenticated": state == .authorized,
                "userID": userID
            ])
        }
    }

    // MARK: - Delete account (local + forget credential)

    @objc func deleteAccount(_ call: CAPPluginCall) {
        // We have no server, so "deletion" means forgetting the Apple ID
        // credential reference and clearing the local user-defaults entry.
        // The user can also revoke us in Settings → Apple ID → Sign in with Apple.
        UserDefaults.standard.removeObject(forKey: userIDKey)
        call.resolve([
            "deleted": true,
            "note": "Local credential cleared. To fully revoke access, go to Settings → Apple ID → Sign in with Apple → WSPuffer → Stop using Apple ID."
        ])
    }
}

// MARK: - Apple sign-in callback bridge

private final class SiwAPresenter: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private let window: UIWindow?
    var onComplete: ((Result<[String: Any], Error>) -> Void)?

    init(window: UIWindow?) {
        self.window = window
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onComplete?(.failure(NSError(domain: "SiwA", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unsupported credential type"])))
            return
        }
        var payload: [String: Any] = [
            "userID": cred.user,
            "email":  cred.email ?? "",
            "givenName": cred.fullName?.givenName ?? "",
            "familyName": cred.fullName?.familyName ?? ""
        ]
        if let token = cred.identityToken,
           let tokenStr = String(data: token, encoding: .utf8) {
            payload["identityToken"] = tokenStr
        }
        if let authCode = cred.authorizationCode,
           let codeStr = String(data: authCode, encoding: .utf8) {
            payload["authorizationCode"] = codeStr
        }
        onComplete?(.success(payload))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        onComplete?(.failure(error))
    }
}
