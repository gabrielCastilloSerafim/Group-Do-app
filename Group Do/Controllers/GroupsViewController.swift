//
//  GroupsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth

class GroupsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkLoginStatus()
        
    }
    
    private func checkLoginStatus() {
        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "GroupsToLogin", sender: self)
        }
    }
    

}
