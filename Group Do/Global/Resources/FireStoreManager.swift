//
//  FireStoreManager.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import Foundation
import FirebaseStorage

final class FireStoreManager {
    
    //Class singleton
    static let shared = FireStoreManager()
    private init() {}
    
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
    
    ///Upload group picture to firebase FireStore using the following name convention to name the image  --->  "\(formattedGroupID)_profile_picture.png"
    public func uploadGroupImage(image:UIImage, groupID:String, completion: @escaping (Bool) -> Void) {
        
        let formattedGroupID = FireDBManager.shared.iDFormatter(id: groupID)
        
        let imageData = image.pngData()
        //Standardises the picture file names to be easily accessed
        let filename = "\(formattedGroupID)_group_picture.png"
        
        guard imageData != nil else {
            print("Failed to transform image to png data")
            completion(false)
            return
        }
        storage.child("images/\(filename)").putData(imageData!) { metadata, error in
            guard error == nil else {
                print(error!.localizedDescription)
                completion(false)
                return
            }
            print("Success uploading image")
            completion(true)
        }
    }
    
    ///Gets download URL to a image in firebase storage using its unique name
    public func getImageURL(imageName: String, completion: @escaping (URL?) -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) == true {
            completion(nil)
            
        } else {
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
    
    ///Gets download URL to profile picture image in firebase storage using its unique profile picture image name
    public func getProfilePictureImageURL(userEmail: String, completion: @escaping (URL?) -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let formattedEmail = FireDBManager.shared.emailFormatter(email: userEmail)
        let fileName = "\(formattedEmail)_profile_picture.png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) == true {
            completion(nil)
            
        } else {
            let reference = storage.child("images/\(fileName)")
            
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
    
    ///Gets download URL to group image in firebase storage using its unique group image name
    public func getGroupImageURL(groupID: String, completion: @escaping (URL?) -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        //File name with groupID not formatted because we are looking in the local memory and in local memory the image names are not formatted like in firebase
        let fileName = "\(groupID)_group_picture.png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) == true {
            completion(nil)
            
        } else {
            //File name with formatted groupID because we are looking for it in firebase
            let formattedGroupID = FireDBManager.shared.iDFormatter(id: groupID)
            let formattedFileName = "\(formattedGroupID)_group_picture.png"
            
            let reference = storage.child("images/\(formattedFileName)")
            
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
    
    ///Download group image from firebase using a download URL and givesBack the image as a UIImage in the completion block
    public func downloadGroupImageWithURL(imageURL: URL, completion: @escaping (UIImage) -> Void) {
        
        URLSession.shared.dataTask(with: imageURL) { imageData, _, error in
            guard imageData != nil, error == nil else {return}
            completion(UIImage(data: imageData!)!)
        }.resume()
        
    }
    
    ///Download profile image from firebase using a download URL and givesBack the image as a UIImage in the completion block
    public func downloadProfileImageWithURL(imageURL: URL, completion: @escaping (UIImage) -> Void) {
        
        URLSession.shared.dataTask(with: imageURL) { imageData, _, error in
            guard imageData != nil, error == nil else {return}
            completion(UIImage(data: imageData!)!)
        }.resume()
        
    }
    
    ///Deletes a group picture file from fireStore
    public func deleteGroupImage(group: Groups) {
        
        let groupId = FireDBManager.shared.iDFormatter(id: group.groupID!)
        let imagePath = storage.child("images/\(groupId)_group_picture.png")
        
        imagePath.delete { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    
    
    
}
