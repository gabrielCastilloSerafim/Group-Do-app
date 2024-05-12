//
//  AppDelegate.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging
import AdWizard

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customisation after application launch.
        
        let pushManager = PushNotificationManager()
        pushManager.registerForPushNotifications()
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        guard let adWizardApiKey = Bundle.main.object(forInfoDictionaryKey: "ADWIZARD_API_KEY") as? String else {
            fatalError("ADWIZARD_API_KEY not found")
        }
        AdWizard.shared.configure(apiKey: adWizardApiKey)
        
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
}
