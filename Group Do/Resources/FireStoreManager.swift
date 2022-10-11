//
//  FireStoreManager.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import Foundation
import FirebaseStorage

final class FireStoreManager {
    
    static let shared = FireStoreManager()
    
    //Create a reference to our storage
    private let storage = Storage.storage().reference()
    
    ///Upload profile picture to firebase FireStore using the following name convention to name the image  --->  "\(formattedEmail)_profile_picture.png"
    public func uploadImage(image:UIImage, email:String) {
        
        let formattedEmail = FireDBManager.shared.emailFormatter(email: email)
        
        let imageData = image.pngData()
        //Standardises the picture file names to be easily accessed
        let filename = "\(formattedEmail)_profile_picture.png"
        
        guard imageData != nil else {
            print("Failed to transform image to png data")
            return
        }
        storage.child("images/\(filename)").putData(imageData!) { metadata, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            print("Success uploading image")
        }
    }
    
    ///Gets download URL to a image in firebase storage using its unique name
    public func getImageURL(imageName: String, completion: @escaping (URL) -> Void) {
        
        let reference = storage.child("images/\(imageName)")
        
        reference.downloadURL { result in
            switch result {
            case .success(let url):
                completion(url)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
    }
    
    
}
