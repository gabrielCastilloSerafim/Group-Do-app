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
        
        newItemTextField.delegate = self
        
        //Setup segment control appearance
        prioritySelector.selectedSegmentTintColor = #colorLiteral(red: 0.7826580405, green: 0.9515060782, blue: 0.8565776944, alpha: 1)
        
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let firstItemTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.01189811528, green: 0.781259954, blue: 0.3344096541, alpha: 1), NSAttributedString.Key.font: font]
        let otherItemsTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1), NSAttributedString.Key.font: font]
        
        prioritySelector.setTitleTextAttributes(firstItemTitleText, for: .selected)
        prioritySelector.setTitleTextAttributes(otherItemsTitleText, for: .normal)
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround() 
        
        //Listen for delete notifications from parent VC
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissModalNewItem"), object: nil)
    }
    
//When observer gets notified it means that the parent category has been deleted and needs to dismiss current modal presentation
@objc func methodOfReceivedNotification(notification: Notification) {
    dismiss(animated: true)
}
    
    @IBAction func segmentControlChanged(_ sender: UISegmentedControl) {
        //Dynamically change color of selected segment
        switch sender.selectedSegmentIndex {
        case 0:
            DispatchQueue.main.async {
                sender.selectedSegmentTintColor = #colorLiteral(red: 0.7826580405, green: 0.9515060782, blue: 0.8565776944, alpha: 1)
                let customTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.01189811528, green: 0.781259954, blue: 0.3344096541, alpha: 1)]
                sender.setTitleTextAttributes(customTitleText, for: .selected)
            }
        case 1:
            DispatchQueue.main.async {
                sender.selectedSegmentTintColor = #colorLiteral(red: 0.9974918962, green: 0.9372679591, blue: 0.8053532243, alpha: 1)
                let customTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.9954606891, green: 0.7196272016, blue: 0.1046531126, alpha: 1)]
                sender.setTitleTextAttributes(customTitleText, for: .selected)
            }
        default:
            DispatchQueue.main.async {
                sender.selectedSegmentTintColor = #colorLiteral(red: 0.9987171292, green: 0.8295300603, blue: 0.8019035459, alpha: 1)
                let customTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 1, green: 0.2364974022, blue: 0.1153539345, alpha: 1)]
                sender.setTitleTextAttributes(customTitleText, for: .selected)
            }
        }
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

//MARK: - UITextField Delegate

extension NewItemViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}
