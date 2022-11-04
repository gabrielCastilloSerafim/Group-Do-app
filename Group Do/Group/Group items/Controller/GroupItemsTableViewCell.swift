//
//  GroupItemsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 3/11/22.
//

import UIKit
import RealmSwift

class GroupItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private var groupItemsTableViewLogic = GroupItemsTableViewLogic()
    var groupObject: Groups?
    
    @IBAction func checkItemPressed(_ sender: UIButton) {
        
        let realm = try! Realm()
        let selfUserEmail = realm.objects(RealmUser.self)[0].email!
        let realmGroup = realm.objects(GroupItems.self).filter("fromGroupID CONTAINS %@", groupObject!.groupID!).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        let selectedItem = realmGroup[checkButton.tag]
        
        if selectedItem.completedByUserEmail == "" {
            
            //Set realm completedByUserEmail property as self user's email and change the isDone property to true
            groupItemsTableViewLogic.updateRealmForCompletedTask(selectedItem: selectedItem, selfUserEmail: selfUserEmail)
            
            //Update completed task in firebase
            FireDBManager.shared.updateCompletedGroupItemInFirebase(completedItem: selectedItem, selectedGroup: groupObject!, selfUserEmail: selfUserEmail)
            
        } else {
            
            if selectedItem.completedByUserEmail == selfUserEmail {
                //Set realm completedByUserEmail property back to "" and change the isDone property to false
                groupItemsTableViewLogic.updateRealmForUndoneCompletedTask(selectedItem: selectedItem)
                
                //Update firebase for done item unchecked
                FireDBManager.shared.updateUncheckedDoneGroupItemInFirebase(completedItem: selectedItem, selectedGroup: groupObject!)
            }
        }
    }
    
    
    
}
