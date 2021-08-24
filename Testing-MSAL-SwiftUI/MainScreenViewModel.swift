//
//  MainScreenViewModel.swift
//  Testing-MSAL-SwiftUI
//
//  Created by Muhammad Khan on 8/24/21.
//

import SwiftUI
import MSAL

class MainScreenViewModel: NSObject, URLSessionDelegate {
    
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
    private lazy var application: MSALPublicClientApplication! = nil
    private lazy var accessToken: String? = nil
    lazy var updateLoggingText = ""
    
    func getRootView() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
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
            self.updateLoggingText = "Unable to create application \(error)"
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
            let webViewParameters = MSALWebviewParameters(authPresentationViewController: getRootView())
            let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
            parameters.promptType = .selectAccount
            parameters.authority = authority
            application.acquireToken(with: parameters) { (result, error) in
                guard let result = result else {
                    self.updateLoggingText = "Could not acquire token: \(error ?? "No error informarion" as! Error)"
                    return
                }
                self.accessToken = result.accessToken
                self.updateLoggingText = "Access token is \(self.accessToken ?? "Empty")"
            }
        } catch {
            self.updateLoggingText = "Unable to create authority \(error)"
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
            let thisAccount = try self.getAccountByPolicy(withAccounts: application.allAccounts(), policy: kEditProfilePolicy)
            let webViewParameters = MSALWebviewParameters(authPresentationViewController: getRootView())
            let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
            parameters.authority = authority
            parameters.account = thisAccount
            
            application.acquireToken(with: parameters) { (result, error) in
                if let error = error {
                    self.updateLoggingText = "Could not edit profile: \(error)"
                } else {
                    self.updateLoggingText = "Successfully edited profile"
                }
            }
        } catch {
            self.updateLoggingText = "Unable to construct parameters before calling acquire token \(error)"
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
            guard let thisAccount = try self.getAccountByPolicy(withAccounts: application.allAccounts(), policy: kSignupOrSigninPolicy) else {
                self.updateLoggingText = "There is no account available!"
                return
            }
            let parameters = MSALSilentTokenParameters(scopes: kScopes, account:thisAccount)
            parameters.authority = authority
            self.application.acquireTokenSilent(with: parameters) { (result, error) in
                if let error = error {
                    let nsError = error as NSError
                    // interactionRequired means we need to ask the user to sign-in. This usually happens
                    // when the user's Refresh Token is expired or if the user has changed their password
                    // among other possible reasons.
                    if (nsError.domain == MSALErrorDomain) {
                        if (nsError.code == MSALError.interactionRequired.rawValue) {
                            // Notice we supply the account here. This ensures we acquire token for the same account
                            // as we originally authenticated.
                            let webviewParameters = MSALWebviewParameters(authPresentationViewController: self.getRootView())
                            let parameters = MSALInteractiveTokenParameters(scopes: self.kScopes, webviewParameters: webviewParameters)
                            parameters.account = thisAccount
                            self.application.acquireToken(with: parameters) { (result, error) in
                                guard let result = result else {
                                    self.updateLoggingText = "Could not acquire new token: \(error ?? "No error informarion" as! Error)"
                                    return
                                }
                                self.accessToken = result.accessToken
                                self.updateLoggingText = "Access token is \(self.accessToken ?? "empty")"
                            }
                            return
                        }
                    }
                    self.updateLoggingText = "Could not acquire token: \(error)"
                    return
                }
                guard let result = result else {
                    self.updateLoggingText = "Could not acquire token: No result returned"
                    return
                }
                self.accessToken = result.accessToken
                self.updateLoggingText = "Refreshing token silently"
                self.updateLoggingText = "Refreshed access token is \(self.accessToken ?? "empty")"
            }
        } catch {
            self.updateLoggingText = "Unable to construct parameters before calling acquire token \(error)"
        }
    }
    
    func callApi() {
        guard let accessToken = self.accessToken else {
            self.updateLoggingText = "Operation failed because could not find an access token!"
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        let url = URL(string: self.kGraphURI)
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let urlSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
        self.updateLoggingText = "Calling the API...."
        urlSession.dataTask(with: request) { data, response, error in
            guard let validData = data else {
                self.updateLoggingText = "Could not call API: \(error ?? "No error informarion" as! Error)"
                return
            }
            let result = try? JSONSerialization.jsonObject(with: validData, options: [])
            guard let validResult = result as? [String: Any] else {
                self.updateLoggingText = "Nothing returned from API"
                return
            }
            self.updateLoggingText = "API response: \(validResult.debugDescription)"
        }.resume()
    }
    
    func performLogout() {
        do {
            /**
             Removes all tokens from the cache for this application for the provided account
             - account:    The account to remove from the cache
             */
            let thisAccount = try self.getAccountByPolicy(withAccounts: application.allAccounts(), policy: kSignupOrSigninPolicy)
            if let accountToRemove = thisAccount {
                try application.remove(accountToRemove)
            } else {
                self.updateLoggingText = "There is no account to signing out!"
            }
            self.updateLoggingText = "Signed out"
        } catch  {
            self.updateLoggingText = "Received error signing out: \(error)"
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
