//
//  AddGroupItemViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit
import RealmSwift

class AddGroupItemViewController: UIViewController {
    
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
        //Listen for delete notifications from parent VC
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissModalNewGroupItem"), object: nil)
    }
    //When observer gets notified it means that the group has been deleted and needs to dismiss current modal presentation
    @objc func methodOfReceivedNotification(notification: Notification) {
        dismiss(animated: true)
    }
    
    @IBAction func addTaskButtonPressed(_ sender: Any) {
        
        let itemTitle = itemTitleTextField.text!
        let deadLine = newGroupItemsLogic.getDeadLineString(for: datePicker.date)
        let priorityString = newGroupItemsLogic.getPriorityString(for: prioritySelector.selectedSegmentIndex)
        
        //Create new group item object
        let newItemObject = newGroupItemsLogic.createGroupItemObject(itemTitle: itemTitle, selectedGroup: selectedGroup!, priorityString: priorityString, deadLine: deadLine)
        
        //Add new group item object to realm
        newGroupItemsLogic.addGroupItemToRealm(selectedGroup: selectedGroup!, newItemObject: newItemObject)
        
        //Add group item to Firebase
        newGroupItemsLogic.addGroupItemToFirebase(participantsArray: participantArray!, newItemObject: newItemObject)
        
        dismiss(animated: true)
    }
    

}
