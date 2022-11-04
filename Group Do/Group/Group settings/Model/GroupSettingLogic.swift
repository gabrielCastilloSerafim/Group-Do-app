//
//  GroupSettingLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 30/10/22.
//

import UIKit
import RealmSwift

struct GroupSettingLogic {
    
    ///Check if user is the group admin if it is returns true if it is not returns false
    func checkIfUserIsGroupAdmin(selectedGroup: Groups) -> Bool {
        
        let realm = try! Realm()
        
        let realmUserEmail = realm.objects(RealmUser.self)[0].email
        let realmGroupAdminEmail = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup.groupID!).filter("isAdmin == true")[0].email
        
        if realmUserEmail == realmGroupAdminEmail {
            return true
        } else {
            return false
        }
    }
    
    ///Deletes a group and its related participants and items from user's realm
    func deleteGroupFromRealm(selectedGroup: Groups) {
        let realm = try! Realm()
        do {
            try realm.write({
                let realmGroup = realm.objects(Groups.self).filter("groupID CONTAINS %@", selectedGroup.groupID!).first
                guard let realmGroup = realmGroup else {return}
                let realmGroupParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup.groupID!)
                let realmGroupItems = realm.objects(GroupItems.self).filter("fromGroupID CONTAINS %@", selectedGroup.groupID!)
                
                realm.delete(realmGroup)
                realm.delete(realmGroupParticipants)
                realm.delete(realmGroupItems)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Deletes the user that is exiting the group from fire base
    func deleteExitUserFromFirebase(selectedGroup: Groups, allGroupParticipants: Results<GroupParticipants>) {
        
        let realm = try! Realm()
        
        let realmUserEmail = realm.objects(RealmUser.self)[0].email!
        let selfParticipant = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup.groupID!).filter("email CONTAINS %@", realmUserEmail)[0]
        
        FireDBManager.shared.deleteExitUser(participantToRemove: selfParticipant, allParticipantsArray: allGroupParticipants)
    }
    
    ///Deletes complete group from fire base
    func deleteEntireGroupFromFirebase(selectedGroup: Groups, participantsArray: Results<GroupParticipants>) {
        
        var participantsArray = Array<GroupParticipants>()
        let realm = try! Realm()
        let participants = realm.objects(GroupParticipants.self).filter("partOfGroupID CONTAINS %@", selectedGroup.groupID!)
        for participant in participants {
            participantsArray.append(participant)
        }
        
        FireDBManager.shared.deleteGroupFromFirebase(group: selectedGroup, participantsArray: participantsArray)
    }
    
    ///Creates and returns a alert action for a participant deletion
    func createAlertAction() -> UIAlertController {
        return UIAlertController(title: "Delete participant", message: "By clicking Confirm the selected participant will be excluded from group", preferredStyle: .alert)
    }
    
    ///Creates and returns a completion block to the delete participant  alert action
    func createAlertCompletion(participantToDelete: GroupParticipants, selectedGroup: Groups) -> UIAlertAction {
        
        return UIAlertAction(title: "Confirm", style: .destructive) { _ in

            //Delete group participant other participants accounts on firebase
            FireDBManager.shared.deleteUserRemovedByAdmin(participantToRemove: participantToDelete, selectedGroup: selectedGroup)
            
            //Delete entire group from person who was deleted from group on firebase
            FireDBManager.shared.deleteGroupFromRemovedPersonAccount(participantToRemove: participantToDelete, selectedGroup: selectedGroup)
            
            //Delete removed person's profile picture from local device storage if it is not being used in any other group
            let realm = try! Realm()
            if realm.objects(GroupParticipants.self).filter("email CONTAINS %@", participantToDelete.email!).count == 0 {
                ImageManager.shared.deleteLocalProfilePicture(userEmail: participantToDelete.email!)
            }

            //Delete participant from realm
            do {
                try realm.write({
                    realm.delete(participantToDelete)
                })
            } catch {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    
    
    
}
