//
//  ItemsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit
import RealmSwift

final class ItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var taskCompletionCircle: UIImageView!
    @IBOutlet weak var taskCompletedButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private var itemsTableViewLogic = ItemsTableViewLogic()
    var parentCategoryID: String?
    
    @IBAction func taskCompletedPressed(_ sender: Any) {
        guard let parentCategoryID = parentCategoryID else {return}
        let realm = try! Realm()
        
        let selectedIndexPath = taskCompletedButton.tag
        
        let selectedItemObject = itemsTableViewLogic.getSelectedItemObject(for: parentCategoryID, in: selectedIndexPath)
        
        itemsTableViewLogic.updateObjectInRealm(for: selectedItemObject)
        
        //Perform isDone property update in firebase (Can call the addPersonal item because if it's child already exists it wont create another one it will only update the exiting child with it`s new value)
        let email = realm.objects(RealmUser.self)[0].email!
        PersonalItemsFireDBManager.shared.addPersonalItem(email: email, itemObject: selectedItemObject)
        
    }
}
