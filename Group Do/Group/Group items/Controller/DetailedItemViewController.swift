//
//  ViewController.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 28/11/22.
//

import UIKit

class DetailedItemViewController: UIViewController {

    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var itemPriority: UIImageView!
    @IBOutlet weak var itemDeadline: UILabel!
    @IBOutlet weak var itemStatus: UILabel!
    
    var itemObject: GroupItems?
    let priorityImagesArray = [#imageLiteral(resourceName: "Priority Low"), #imageLiteral(resourceName: "Priority Medium"), #imageLiteral(resourceName: "Priority High")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        populateView()
    }
    
    func populateView() {
        itemTitle.text = itemObject?.itemTitle
        itemDeadline.text = itemObject?.deadLine
        
        if itemObject?.isDone == true {
            itemStatus.text = "Completed"
        }
        
        switch itemObject?.priority {
        case "Low":
            itemPriority.image = priorityImagesArray[0]
        case "Medium":
            itemPriority.image = priorityImagesArray[1]
        default:
            itemPriority.image = priorityImagesArray[2]
        }
        
    }
    

}
