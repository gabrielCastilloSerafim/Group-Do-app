//
//  NewItemViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit

class NewItemViewController: UIViewController {

    @IBOutlet weak var newItemTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var prioritySelector: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static var completion: ((String?, String?, String?) -> Void)?
    
    @IBAction func addTaskPressed(_ sender: UIButton) {
        
        let date = datePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY/MM/dd"
        // Convert Date to String
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
        
        Self.completion?(newItemTextField.text, priorityString, dateString)
        
        self.dismiss(animated: true)
    }
    

}
