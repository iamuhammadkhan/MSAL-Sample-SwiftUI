//
//  AppDelegate.swift
//  Testing-MSAL-SwiftUI
//
//  Created by Muhammad Khan on 8/24/21.
//

import UIKit
import MSAL

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MSALGlobalConfig.loggerConfig.setLogCallback { (logLevel, message, containsPII) in
            if (!containsPII) { print("%@", message!) }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("Received callback!")
        guard let sourceApp = sourceApplication else { return false }
        MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: sourceApp)
        return true
    }
}
