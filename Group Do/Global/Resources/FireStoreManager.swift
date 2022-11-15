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
    private init() {}
    private let storage = Storage.storage().reference()
    
    ///Upload group picture to firebase FireStore using its image name
    public func uploadImageToFireStore(image:UIImage, imageName:String, completion: @escaping (Bool) -> Void) {
        
        let imageData = image.pngData()
        let filename = imageName
        
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
                    return
                }
            }
        }
    }
    
    ///Gets download URL to a image in firebase storage using its unique name and does not check if image already exists because we are making an update
    public func getUpdateImageURL(imageName: String, completion: @escaping (URL) -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        let reference = storage.child("images/\(imageName)")
        
        reference.downloadURL { result in
            switch result {
            case .success(let url):
                completion(url)
            case .failure(let error):
                print(error.localizedDescription)
                return
            }
        }
    }
    
    ///Deletes a picture file from fireStore
    public func deleteImageFromFireStore(imageName: String) {
        
        let imagePath = storage.child("images/\(imageName)")
        
        imagePath.delete { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    ///Downloads an image from firebase using a download URL and givesBack the image as a UIImage in the completion block
    public func downloadImageWithURL(imageURL: URL, completion: @escaping (UIImage) -> Void) {
        
        URLSession.shared.dataTask(with: imageURL) { imageData, _, error in
            guard imageData != nil, error == nil else {return}
            completion(UIImage(data: imageData!)!)
        }.resume()
    }
    
    
    
    
}
