//
//  EditProfileLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import UIKit
import RealmSwift

struct EditProfileLogic {
    
    ///Updates the modified profile picture in local device memory
    func updateProfilePictureInDeviceMemory(newImage: UIImage) {
        
        let realm = try! Realm()
        let profilePictureName = realm.objects(RealmUser.self)[0].profilePictureFileName!
        
        //Delete old image from device memory
        ImageManager.shared.deleteImageFromLocalStorage(imageName: profilePictureName)
        
        //Save new image to device memory
        ImageManager.shared.saveImageToDeviceMemory(imageName: profilePictureName, image: newImage) {}
    }
    
    ///Returns the user's profile picture
    func getProfilePicture(completion: (UIImage) -> Void) {
        
        let realm = try! Realm()
        let profilePictureName = realm.objects(RealmUser.self)[0].profilePictureFileName!
        
        ImageManager.shared.loadPictureFromDisk(fileName: profilePictureName) { image in
            guard let image = image else {return}
            
            completion(image)
        }
    }
    
}
