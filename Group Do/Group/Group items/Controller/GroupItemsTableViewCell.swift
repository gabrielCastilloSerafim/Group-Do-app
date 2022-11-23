//
//  GroupItemsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 3/11/22.
//

import UIKit
import RealmSwift

final class GroupItemsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var checkCircle: UIImageView!
    @IBOutlet weak var dueToLabel: UILabel!
    @IBOutlet weak var createdBy: UILabel!
    @IBOutlet weak var priorityImage: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        checkImage.layer.cornerRadius = checkImage.frame.height/2
    }
    
    private var groupItemsTableViewLogic = GroupItemsTableViewLogic()
    var groupObject: Groups?
    
    @IBAction func checkItemPressed(_ sender: UIButton) {
        
        let realm = try! Realm()
        let selfUserEmail = realm.objects(RealmUser.self)[0].email!
        let realmGroup = realm.objects(GroupItems.self).filter("fromGroupID == %@", groupObject!.groupID!).sorted(byKeyPath: "creationTimeSince1970", ascending: false)
        let selectedItem = realmGroup[checkButton.tag]
        
        if selectedItem.completedByUserEmail == "" {
            
            //Set realm completedByUserEmail property as self user's email and change the isDone property to true
            groupItemsTableViewLogic.updateRealmForCompletedTask(selectedItem: selectedItem, selfUserEmail: selfUserEmail)
            
            //Update completed task in firebase
            GroupItemsFireDBManager.shared.updateCompletedGroupItemInFirebase(completedItem: selectedItem, selectedGroup: groupObject!, selfUserEmail: selfUserEmail)
            
            //Send push notification with completed item to group participants
            groupItemsTableViewLogic.sendPushNotificationToParticipants(participantsArray: groupObject!.groupParticipants, itemTitle: selectedItem.itemTitle!, selectedGroup: groupObject!)
            
        } else {
            
            if selectedItem.completedByUserEmail == selfUserEmail {
                //Set realm completedByUserEmail property back to "" and change the isDone property to false
                groupItemsTableViewLogic.updateRealmForUndoneCompletedTask(selectedItem: selectedItem)
                
                //Update firebase for done item unchecked
                GroupItemsFireDBManager.shared.updateUncheckedDoneGroupItemInFirebase(completedItem: selectedItem, selectedGroup: groupObject!)
            }
        }
    }
    
    
    
}
