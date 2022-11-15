//
//  NewItemViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import RealmSwift

final class NewItemViewController: UIViewController {

    @IBOutlet weak var newItemTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    
    private var newItemLogic = NewItemLogic()
    var currentCategory: PersonalCategories?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround() 
        
        //Listen for delete notifications from parent VC
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissModalNewItem"), object: nil)
    }
    
//When observer gets notified it means that the parent category has been deleted and needs to dismiss current modal presentation
@objc func methodOfReceivedNotification(notification: Notification) {
    dismiss(animated: true)
}
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addTaskPressed(_ sender: UIButton) {
        
        //Variables necessary to create a newItem object
        guard let currentCategory = currentCategory else {return}
        guard let categoryID = currentCategory.categoryID else {return}
        
        let newItemTitle = newItemTextField.text!
        let newItemDeadline = newItemLogic.selectedDateToString(with: datePicker.date)
        let newItemPriority = newItemLogic.determinePriorityLevel(for: prioritySelector.selectedSegmentIndex)
        
        //Check if user typed a item title
        if newItemTitle == "" {
            let alert = UIAlertController(title: "Error", message: "Please give the item a title.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Create a new item object
        let newItemObject = newItemLogic.createPersonalItemObject(title: newItemTitle,
                                                                  priority: newItemPriority,
                                                                  deadline: newItemDeadline,
                                                                  parentCategoryID: categoryID)
        
        //Append created item object to its corresponding category in realm
        newItemLogic.appendItemObjectToRealm(newItemObject: newItemObject, selectedCategoryObject: currentCategory)
        
        //Save created object to firebase
        let realm = try! Realm()
        let email = realm.objects(RealmUser.self)[0].email!
        PersonalItemsFireDBManager.shared.addPersonalItem(email: email, itemObject: newItemObject)
        
        dismiss(animated: true)
    }
    

}
