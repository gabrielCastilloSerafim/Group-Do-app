//
//  FileManager.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 9/10/22.
//

import UIKit
import RealmSwift

final class ImageManager {
    
    static let shared = ImageManager()
    
    ///Saves an image to devices documents directory using the following convention to name the image --->  "\(formattedEmail)_profile_picture.png"
    public func saveImage(userEmail: String, image: UIImage) {
        
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
    
    ///Loads user's profile picture from local storage, Has completion with UIImage ready to use, the image naming convention used was --->  "\(formattedEmail)_profile_picture.png"
    public func loadUserProfilePictureFromDisk(completion:(UIImage?) -> Void) {
        
        let realm = try! Realm()
        let userObject = realm.objects(RealmUser.self)
        let fileName = userObject[0].profilePictureFileName
        
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
    

    
    
}
