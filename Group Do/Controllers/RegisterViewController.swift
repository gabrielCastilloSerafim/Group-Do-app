//
//  RegisterViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Hides tab bar controller
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Unhides tab bar controller
        self.tabBarController?.tabBar.isHidden = false
    }

    @IBAction func registerButtonPressed(_ sender: UIButton) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                
                print("Success creating user")
                
                self?.navigationController?.popToRootViewController(animated: false)
                
            }
            
            
        }
        
        
    }
    

}
