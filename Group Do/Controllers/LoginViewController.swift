//
//  LoginViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Hides back button on view
        self.navigationItem.setHidesBackButton(true, animated: false)
        //Hides tab bar controller
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Unhides tab bar controller
        self.tabBarController?.tabBar.isHidden = false
    }
    

    @IBAction func loginButtonPressed(_ sender: Any) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                
                print("Success logging in")
                self?.navigationController?.popToRootViewController(animated: false)
            }
        }
        
    }
    
}
