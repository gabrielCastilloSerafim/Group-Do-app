//
//  MainNavigationController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 19/10/22.
//

import UIKit
import RealmSwift

class MainNavigationController: UIViewController {
    
    static var isLoggedIn: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLogIn()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Self.isLoggedIn! {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "tabController") as! UITabBarController
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: false)
            
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! UINavigationController
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
        }
        
    }
    
    private func checkLogIn() {
        let realm = try! Realm()
        if realm.objects(RealmUser.self).count > 0 {
            Self.isLoggedIn = true
        } else {
            Self.isLoggedIn = false
        }
        
    }
    
    
}
