//
//  GroupSettingsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 17/10/22.
//

import UIKit
import RealmSwift

final class GroupSettingsTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var adminOrDeleteImage: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
    }
    
    private var groupSettingsCellLogic = GroupSettingsCellLogic()
    var selectedGroup: Groups?
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        
        let realm = try! Realm()
        let participantsArray = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup!.groupID!).sorted(byKeyPath: "isAdmin", ascending: false)
        
        let indexPath = deleteButton.tag
        
        let participantToDelete = participantsArray[indexPath]
        
        //Delete group participant from other participants accounts on firebase
        GroupSettingsFireDBManager.shared.deleteUserRemovedByAdmin(participantToRemove: participantToDelete, selectedGroup: selectedGroup!)
        
        //Delete entire group from person who was deleted from group on firebase
        GroupSettingsFireDBManager.shared.deleteGroupFromRemovedPersonAccount(participantToRemove: participantToDelete, selectedGroup: selectedGroup!)
        
        //Delete removed person's profile picture from local device storage if it is not being used in any other group
        groupSettingsCellLogic.deleteRemovedUserProfilePicture(participantToDelete: participantToDelete)

        //Delete participant from realm
        groupSettingsCellLogic.deleteParticipantFromRealm(participantToDelete: participantToDelete)
    }

    
}
