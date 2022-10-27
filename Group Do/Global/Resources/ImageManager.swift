//
//  FileManager.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 9/10/22.
//

import UIKit
import RealmSwift

final class ImageManager {
    
    //Create class singleton
    static let shared = ImageManager()
    private init() {}
    
    ///Saves an image to devices documents directory using the following convention to name the image --->  "\(formattedEmail)_profile_picture.png"
    public func saveProfileImage(userEmail: String, image: UIImage) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let formattedEmail = FireDBManager.shared.emailFormatter(email: userEmail)
        
        let fileName = "\(formattedEmail)_profile_picture.png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
            print("Success saving image locally")
        } catch let error {
            print("error saving file with error", error)
        }
        
    }
    
    ///Saves an image to devices documents directory using the following convention to name the image --->  "\(groupID)_group_picture.png"
    public func saveGroupImage(groupID: String, image: UIImage, completion: @escaping () -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = "\(groupID)_group_picture.png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                completion()
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
            completion()
            print("Success saving image locally")
        } catch let error {
            print("error saving file with error", error)
        }
        
    }
    
    ///Loads images from local storage, Has completion with UIImage ready to use, the image naming convention used was --->  "\(formattedEmail)_profile_picture.png"
    public func loadPictureFromDisk(fileName: String?, completion:(UIImage?) -> Void) {
        
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName!)
            let image = UIImage(contentsOfFile: imageUrl.path)
            print("Success retrieving image from local storage")
            completion(image)
        }
    }
    
    ///Deletes all images from documents directory
    public func deleAllImagesFromUsersDir() {
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs where fileURL.pathExtension == "png" {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  {
            print(error.localizedDescription)
        }
        
    }
    
    ///Delete group image from local device storage
    public func deleteLocalGroupPhoto(groupID: String) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = "\(groupID)_group_picture.png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed group photo from device memory")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        
    }
    
    ///Delete profile picture image from local device storage
    public func deleteLocalProfilePicture(userEmail: String) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let formattedEmail = FireDBManager.shared.emailFormatter(email: userEmail)
        
        let fileName = "\(formattedEmail)_profile_picture.png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed profile picture from device memory")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        
    }
    
    
    
    
    
}
