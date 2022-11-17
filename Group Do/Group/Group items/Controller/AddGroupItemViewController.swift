//
//  AddGroupItemViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit
import RealmSwift

final class AddGroupItemViewController: UIViewController {
    
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var itemTitleTextField: UITextField!
    
    var selectedGroup: Groups?{
        didSet {
            participantArray = selectedGroup?.groupParticipants
        }
    }
    var groupID: String?
    var participantArray: List<GroupParticipants>?
    var newGroupItemsLogic = NewGroupItemLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup segment control appearance
        prioritySelector.selectedSegmentTintColor = #colorLiteral(red: 0.7826580405, green: 0.9515060782, blue: 0.8565776944, alpha: 1)
        
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let firstItemTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.01189811528, green: 0.781259954, blue: 0.3344096541, alpha: 1), NSAttributedString.Key.font: font]
        let otherItemsTitleText = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1), NSAttributedString.Key.font: font]
        
        prioritySelector.setTitleTextAttributes(firstItemTitleText, for: .selected)
        prioritySelector.setTitleTextAttributes(otherItemsTitleText, for: .normal)
        
        //Dismiss keyboard when tapped around
        self.hideKeyboardWhenTappedAround()
        
        //Manage keyboard hiding textField
        self.setupKeyboardHiding()
        
        //Listen for delete notifications from parent VC
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissModalNewGroupItem"), object: nil)
    }
    //When observer gets notified it means that the group has been deleted and needs to dismiss current modal presentation
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
    
    @IBAction func addTaskButtonPressed(_ sender: Any) {
        
        let itemTitle = itemTitleTextField.text!
        let deadLine = newGroupItemsLogic.getDeadLineString(for: datePicker.date)
        let priorityString = newGroupItemsLogic.getPriorityString(for: prioritySelector.selectedSegmentIndex)
        
        //Check if user typed a item title
        if itemTitle == "" {
            let alert = UIAlertController(title: "Error", message: "Please give the item a title.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Create new group item object
        let newItemObject = newGroupItemsLogic.createGroupItemObject(itemTitle: itemTitle, selectedGroup: selectedGroup!, priorityString: priorityString, deadLine: deadLine)
        
        //Add new group item object to realm
        newGroupItemsLogic.addGroupItemToRealm(selectedGroup: selectedGroup!, newItemObject: newItemObject)
        
        //Add group item to Firebase
        newGroupItemsLogic.addGroupItemToFirebase(participantsArray: participantArray!, newItemObject: newItemObject)
        
        dismiss(animated: true)
    }
    

}
