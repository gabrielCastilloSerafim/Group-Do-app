//
//  NewCategoryViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 6/10/22.
//

import UIKit
import RealmSwift

final class NewCategoryViewController: UIViewController {

    @IBOutlet weak var newCategoryTextField: UITextField!
    
    private var newCategoryLogic = NewCategoryLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround()
        
        //Manage keyboard hiding textField
        self.setupKeyboardHiding()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addCategoryPressed(_ sender: UIButton) {
        
        let newCategoryName = newCategoryTextField.text!
        
        //Check if user typed a category title
        if newCategoryName == "" {
            let alert = UIAlertController(title: "Error", message: "Please give the category a name.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Create new category object
        let newCategoryObj = newCategoryLogic.createNewCategoryObject(with: newCategoryName)
        
        //Save realm object
        newCategoryLogic.addCategoryToRealm(newCategoryObj)
        
        //Save new category to firebase database
        let realm = try! Realm()
        let email = realm.objects(RealmUser.self)[0].email!
        CategoriesFireDBManager.shared.addPersonalCategory(email: email, categoryObject: newCategoryObj)
        
        //Dismiss view
        self.dismiss(animated: true)
    }
    
    
    
}
