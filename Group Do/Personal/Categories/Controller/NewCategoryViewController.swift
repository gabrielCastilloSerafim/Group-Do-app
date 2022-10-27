//
//  NewCategoryViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit
import RealmSwift

class NewCategoryViewController: UIViewController {

    @IBOutlet weak var newCategoryTextField: UITextField!
    
    private var newCategoryLogic = NewCategoryLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addCategoryPressed(_ sender: UIButton) {
        
        //Variable that contains the text entered in the UITextField
        let newCategoryName = newCategoryTextField.text!
        
        //Create new category object
        let newCategoryObj = newCategoryLogic.createNewCategoryObject(with: newCategoryName)
        
        //Save realm object
        newCategoryLogic.addCategoryToRealm(newCategoryObj)
        
        //Save new category to firebase database
        let realm = try! Realm()
        let email = realm.objects(RealmUser.self)[0].email!
        FireDBManager.shared.addPersonalCategory(email: email, categoryObject: newCategoryObj)
        
        //Dismiss view
        self.dismiss(animated: true)
    }
    
    
    
}
