//
//  GroupSettingsCellLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import UIKit
import RealmSwift

struct GroupSettingsCellLogic {
    
    ///Deletes removed person's profile picture from local device storage if it is not being used in any other group/
    func deleteRemovedUserProfilePicture(participantToDelete: GroupParticipants) {
        
        let realm = try! Realm()
        if realm.objects(GroupParticipants.self).filter("email == %@", participantToDelete.email!).count == 0 {
            ImageManager.shared.deleteImageFromLocalStorage(imageName: participantToDelete.profilePictureFileName!)
        }
    }
    
    ///Deletes participant from realm
    func deleteParticipantFromRealm(participantToDelete: GroupParticipants) {
        
        let realm = try! Realm()
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
