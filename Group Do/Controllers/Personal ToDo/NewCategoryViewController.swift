//
//  NewCategoryViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit

class NewCategoryViewController: UIViewController {

    @IBOutlet weak var newCategoryTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static var completion: ((String?) -> Void)?
    
    @IBAction func addCategoryPressed(_ sender: UIButton) {
        
        Self.completion?(newCategoryTextField.text)
        
        self.dismiss(animated: true)
        
    }
    
    
    
}
