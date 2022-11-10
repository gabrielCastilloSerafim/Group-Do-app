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
    
    ///Saves an image to devices documents directory using its imageName
    public func saveImageToDeviceMemory(imageName: String, image: UIImage, completion: @escaping () -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
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
    
    ///Loads images from local storage, Has completion with UIImage ready to use
    public func loadPictureFromDisk(fileName: String?, completion:(UIImage?) -> Void) {
        
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName!)
            let image = UIImage(contentsOfFile: imageUrl.path)
            
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
            return
        }
    }
    
    ///Deletes an image from local device storage using its image name
    public func deleteImageFromLocalStorage(imageName: String) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed group photo from device memory")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
    }
    
    
}
