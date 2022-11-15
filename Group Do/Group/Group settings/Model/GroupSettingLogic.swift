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
        let realmGroupAdminEmail = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup.groupID!).filter("isAdmin == true")[0].email
        
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
                let realmGroup = realm.objects(Groups.self).filter("groupID == %@", selectedGroup.groupID!).first
                guard let realmGroup = realmGroup else {return}
                let realmGroupParticipants = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup.groupID!)
                let realmGroupItems = realm.objects(GroupItems.self).filter("fromGroupID == %@", selectedGroup.groupID!)
                
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
        let selfParticipant = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup.groupID!).filter("email == %@", realmUserEmail)[0]
        
        GroupSettingsFireDBManager.shared.deleteExitUser(participantToRemove: selfParticipant, allParticipantsArray: allGroupParticipants)
    }
    
    ///Deletes complete group from fire base
    func deleteEntireGroupFromFirebase(selectedGroup: Groups, participantsArray: Results<GroupParticipants>) {
        
        var participantsArray = Array<GroupParticipants>()
        let realm = try! Realm()
        let participants = realm.objects(GroupParticipants.self).filter("partOfGroupID == %@", selectedGroup.groupID!)
        for participant in participants {
            participantsArray.append(participant)
        }
        
        GroupSettingsFireDBManager.shared.deleteGroupFromFirebase(group: selectedGroup, participantsArray: participantsArray)
    }
    
    ///Deletes group participants images from device memory  if it is not being used nowhere else
    func deleteProfilePictures(deletedGroupParticipants: Results<GroupParticipants>) {
        
        for participant in deletedGroupParticipants {
            
            let realm = try! Realm()
            let selfUserEmail = realm.objects(RealmUser.self)[0].email!
            
            if participant.email != selfUserEmail {
                
                if realm.objects(GroupParticipants.self).filter("email == %@", participant.email!).filter("partOfGroupID != %@", participant.partOfGroupID!).count == 0 {
                    ImageManager.shared.deleteImageFromLocalStorage(imageName: participant.profilePictureFileName!)
                }
            }
        }
    }
    
    ///Updates the modified profile picture in local device memory
    func updateProfilePictureInDeviceMemory(newImage: UIImage, selectedGroup: Groups) {
        
        let realm = try! Realm()
        let group = realm.objects(Groups.self).filter("groupID == %@", selectedGroup.groupID!).first
        guard let group = group else {return}
        let groupImageName = group.groupPictureName!
        
        //Delete old image from device memory
        ImageManager.shared.deleteImageFromLocalStorage(imageName: groupImageName)
        
        //Save new image to device memory
        ImageManager.shared.saveImageToDeviceMemory(imageName: groupImageName, image: newImage) {}
    }
    
    
}
