//
//  MainScreenViewModel.swift
//  Testing-MSAL-SwiftUI
//
//  Created by Muhammad Khan on 8/24/21.
//

import SwiftUI
import MSAL

final class MainScreenViewModel: NSObject, ObservableObject, URLSessionDelegate {
    
    private let kTenantName = "fabrikamb2c.onmicrosoft.com" // Your tenant name
    private let kAuthorityHostName = "fabrikamb2c.b2clogin.com" // Your authority host name
    private let kClientID = "90c0fe63-bcf2-44d5-8fb7-b8bbc0b29dc6" // Your client ID from the portal when you created your application
    private let kSignupOrSigninPolicy = "b2c_1_susi" // Your signup and sign-in policy you created in the portal
    private let kEditProfilePolicy = "b2c_1_edit_profile" // Your edit policy you created in the portal
    private let kResetPasswordPolicy = "b2c_1_reset" // Your reset password policy you created in the portal
    private let kGraphURI = "https://fabrikamb2chello.azurewebsites.net/hello" // This is your backend API that you've configured to accept your app's tokens
    private let kScopes: [String] = ["https://fabrikamb2c.onmicrosoft.com/helloapi/demo.read"] // This is a scope that you've configured your backend API to look for.
    
    // DO NOT CHANGE - This is the format of OIDC Token and Authorization endpoints for Azure AD B2C.
    private let kEndpoint = "https://%@/tfp/%@/%@"
    private var application: MSALPublicClientApplication?
    private var accessToken: String?

    /// Drives the log panel in ContentView.
    ///
    /// Must be `@Published` on an `ObservableObject`: SwiftUI redraws in
    /// response to a publisher, not to a plain property being assigned. Without
    /// it the panel renders once and never changes, which makes the whole
    /// sample look broken.
    @Published var loggingText = ""

    /// Append a line to the log panel, on the main queue.
    ///
    /// MSAL's completion handlers are not guaranteed to run on the main thread,
    /// and publishing a change from a background thread is undefined behaviour
    /// in SwiftUI. Funnelling every write through here is the fix.
    private func log(_ message: String) {
        if Thread.isMainThread {
            loggingText = message
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.loggingText = message
            }
        }
    }

    /// The view controller MSAL presents its web view from.
    ///
    /// `UIApplication.shared.windows` is deprecated since iOS 15; the scene API
    /// replaces it. Returns nil rather than force-unwrapping, because a nil
    /// root view controller is a normal state during launch and backgrounding.
    func getRootView() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
    
    func initializeMSAL() {
        do {
            /**
             Initialize a MSALPublicClientApplication with a MSALPublicClientApplicationConfig.
             MSALPublicClientApplicationConfig can be initialized with client id, redirect uri and authority.
             Redirect uri will be constucted automatically in the form of "msal<your-client-id-here>://auth" if not provided.
             The scheme part, i.e. "msal<your-client-id-here>", needs to be registered in the info.plist of the project
             */
            
            let siginPolicyAuthority = try self.getAuthority(forPolicy: self.kSignupOrSigninPolicy)
            let editProfileAuthority = try self.getAuthority(forPolicy: self.kEditProfilePolicy)

            // Provide configuration for MSALPublicClientApplication
            // MSAL will use default redirect uri when you provide nil
            let pcaConfig = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: nil, authority: siginPolicyAuthority)
            pcaConfig.knownAuthorities = [siginPolicyAuthority, editProfileAuthority]
            self.application = try MSALPublicClientApplication(configuration: pcaConfig)
        } catch {
            self.log("Unable to create application \(error)")
        }
    }
    
    func startAuthorization() {
        do {
            /**
             authority is a URL indicating a directory that MSAL can use to obtain tokens. In Azure B2C
             it is of the form `https://<instance/tfp/<tenant>/<policy>`, where `<instance>` is the
             directory host (e.g. https://login.microsoftonline.com), `<tenant>` is a
             identifier within the directory itself (e.g. a domain associated to the
             tenant, such as contoso.onmicrosoft.com), and `<policy>` is the policy you wish to
             use for the current user flow.
             */
            let authority = try self.getAuthority(forPolicy: self.kSignupOrSigninPolicy)
            /**
             Acquire a token for a new account using interactive authentication

             - scopes: Permissions you want included in the access token received
             in the result in the completionBlock. Not all scopes are
             gauranteed to be included in the access token returned.
             - completionBlock: The completion block that will be called when the authentication
             flow completes, or encounters an error.
             */
            guard let application = application else {
                self.log("MSAL is not initialised yet.")
                return
            }
            guard let presenter = getRootView() else {
                self.log("No view controller available to present the sign-in web view.")
                return
            }
            let webViewParameters = MSALWebviewParameters(authPresentationViewController: presenter)
            let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
            parameters.promptType = .selectAccount
            parameters.authority = authority
            application.acquireToken(with: parameters) { (result, error) in
                guard let result = result else {
                    self.log("Could not acquire token: \(error?.localizedDescription ?? "no error information returned")")
                    return
                }
                self.accessToken = result.accessToken
                self.log("Access token is \(self.accessToken ?? "Empty")")
            }
        } catch {
            self.log("Unable to create authority \(error)")
        }
    }
    
    func editProfile() {
        do {
            /**
             authority is a URL indicating a directory that MSAL can use to obtain tokens. In Azure B2C
             it is of the form `https://<instance/tfp/<tenant>/<policy>`, where `<instance>` is the
             directory host (e.g. https://login.microsoftonline.com), `<tenant>` is a
             identifier within the directory itself (e.g. a domain associated to the
             tenant, such as contoso.onmicrosoft.com), and `<policy>` is the policy you wish to
             use for the current user flow.
             */
            let authority = try self.getAuthority(forPolicy: self.kEditProfilePolicy)
            /**
             Acquire a token for a new account using interactive authentication
             
             - scopes: Permissions you want included in the access token received
             in the result in the completionBlock. Not all scopes are
             gauranteed to be included in the access token returned.
             - completionBlock: The completion block that will be called when the authentication
             flow completes, or encounters an error.
             */
            guard let application = application else {
                self.log("MSAL is not initialised yet.")
                return
            }
            guard let presenter = getRootView() else {
                self.log("No view controller available to present the sign-in web view.")
                return
            }
            let thisAccount = try self.getAccountByPolicy(withAccounts: application.allAccounts(), policy: kEditProfilePolicy)
            let webViewParameters = MSALWebviewParameters(authPresentationViewController: presenter)
            let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
            parameters.authority = authority
            parameters.account = thisAccount

            application.acquireToken(with: parameters) { (result, error) in
                if let error = error {
                    self.log("Could not edit profile: \(error)")
                } else {
                    self.log("Successfully edited profile")
                }
            }
        } catch {
            self.log("Unable to construct parameters before calling acquire token \(error)")
        }
    }
    
    func refreshToken() {
        do {
            /**
             authority is a URL indicating a directory that MSAL can use to obtain tokens. In Azure B2C
             it is of the form `https://<instance/tfp/<tenant>/<policy>`, where `<instance>` is the
             directory host (e.g. https://login.microsoftonline.com), `<tenant>` is a
             identifier within the directory itself (e.g. a domain associated to the
             tenant, such as contoso.onmicrosoft.com), and `<policy>` is the policy you wish to
             use for the current user flow.
             */
            let authority = try self.getAuthority(forPolicy: self.kSignupOrSigninPolicy)
            /**
             Acquire a token for an existing account silently
             
             - scopes: Permissions you want included in the access token received
             in the result in the completionBlock. Not all scopes are
             gauranteed to be included in the access token returned.
             - account: An account object that we retrieved from the application object before that the
             authentication flow will be locked down to.
             - completionBlock: The completion block that will be called when the authentication
             flow completes, or encounters an error.
             */
            guard let application = application else {
                self.log("MSAL is not initialised yet.")
                return
            }
            guard let thisAccount = try self.getAccountByPolicy(withAccounts: application.allAccounts(), policy: kSignupOrSigninPolicy) else {
                self.log("There is no account available!")
                return
            }
            let parameters = MSALSilentTokenParameters(scopes: kScopes, account:thisAccount)
            parameters.authority = authority
            application.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    let nsError = error as NSError
                    // interactionRequired means we need to ask the user to sign-in. This usually happens
                    // when the user's Refresh Token is expired or if the user has changed their password
                    // among other possible reasons.
                    if (nsError.domain == MSALErrorDomain) {
                        if (nsError.code == MSALError.interactionRequired.rawValue) {
                            // Notice we supply the account here. This ensures we acquire token for the same account
                            // as we originally authenticated.
                            // This completion handler is not guaranteed to be
                            // on the main thread, and presenting UI, or even
                            // reading UIApplication.connectedScenes, has to be.
                            DispatchQueue.main.async {
                                guard let presenter = self.getRootView() else {
                                    self.log("No view controller available to present the sign-in web view.")
                                    return
                                }
                                let webviewParameters = MSALWebviewParameters(authPresentationViewController: presenter)
                                let parameters = MSALInteractiveTokenParameters(scopes: self.kScopes, webviewParameters: webviewParameters)
                                parameters.account = thisAccount
                                application.acquireToken(with: parameters) { (result, error) in
                                    guard let result = result else {
                                        self.log("Could not acquire new token: \(error?.localizedDescription ?? "no error information returned")")
                                        return
                                    }
                                    self.accessToken = result.accessToken
                                    self.log("Access token is \(self.accessToken ?? "empty")")
                                }
                            }
                            return
                        }
                    }
                    self.log("Could not acquire token: \(error)")
                    return
                }
                guard let result = result else {
                    self.log("Could not acquire token: No result returned")
                    return
                }
                self.accessToken = result.accessToken
                self.log("Refreshing token silently")
                self.log("Refreshed access token is \(self.accessToken ?? "empty")")
            }
        } catch {
            self.log("Unable to construct parameters before calling acquire token \(error)")
        }
    }
    
    func callApi() {
        guard let accessToken = self.accessToken else {
            self.log("Operation failed because could not find an access token!")
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        let url = URL(string: self.kGraphURI)
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let urlSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
        self.log("Calling the API....")
        urlSession.dataTask(with: request) { data, response, error in
            guard let validData = data else {
                self.log("Could not call API: \(error?.localizedDescription ?? "no error information returned")")
                return
            }
            let result = try? JSONSerialization.jsonObject(with: validData, options: [])
            guard let validResult = result as? [String: Any] else {
                self.log("Nothing returned from API")
                return
            }
            self.log("API response: \(validResult.debugDescription)")
        }.resume()
    }
    
    func performLogout() {
        do {
            /**
             Removes all tokens from the cache for this application for the provided account
             - account:    The account to remove from the cache
             */
            guard let application = application else {
                self.log("MSAL is not initialised yet.")
                return
            }
            let thisAccount = try self.getAccountByPolicy(withAccounts: application.allAccounts(), policy: kSignupOrSigninPolicy)
            guard let accountToRemove = thisAccount else {
                // Previously this logged "no account" and then immediately
                // logged "Signed out" anyway, which reads as success.
                self.log("There is no account to sign out.")
                return
            }
            try application.remove(accountToRemove)
            self.accessToken = nil
            self.log("Signed out")
        } catch  {
            self.log("Received error signing out: \(error)")
        }
    }
    
    func getAccountByPolicy (withAccounts accounts: [MSALAccount], policy: String) throws -> MSALAccount? {
        for account in accounts {
            // This is a single account sample, so we only check the suffic part of the object id,
            // where object id is in the form of <object id>-<policy>.
            // For multi-account apps, the whole object id needs to be checked.
            if let homeAccountId = account.homeAccountId, let objectId = homeAccountId.objectId {
                if objectId.hasSuffix(policy.lowercased()) {
                    return account
                }
            }
        }
        return nil
    }

    func getAuthority(forPolicy policy: String) throws -> MSALB2CAuthority {
        guard let authorityURL = URL(string: String(format: self.kEndpoint, self.kAuthorityHostName, self.kTenantName, policy)) else {
            throw NSError(domain: "SomeDomain", code: 1,
                          userInfo: ["errorDescription": "Unable to create authority URL!"])
        }
        return try MSALB2CAuthority(url: authorityURL)
    }
}
