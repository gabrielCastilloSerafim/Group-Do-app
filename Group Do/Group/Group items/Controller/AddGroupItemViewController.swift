//
//  AddGroupItemViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit

class AddGroupItemViewController: UIViewController {
    
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var itemTitleTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static var completion: ((_ itemTitle: String?, _ dueToDate: String?, _ priority: String?) -> Void)?

    @IBAction func addTaskButtonPressed(_ sender: Any) {
        
        let itemTitle = itemTitleTextField.text!
        
        let date = datePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        let dateString = dateFormatter.string(from: date)
        
        var priorityString = ""
        
        let selectedPriorityIndex = prioritySelector.selectedSegmentIndex
        switch selectedPriorityIndex {
        case 0:
            priorityString = "Low"
        case 1:
            priorityString = "Medium"
        default:
            priorityString = "High"
        }
        
        Self.completion!(itemTitle, dateString, priorityString)
        
        dismiss(animated: true)
    }
    

}
