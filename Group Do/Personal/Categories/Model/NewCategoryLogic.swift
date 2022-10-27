//
//  NewCategoryLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 25/10/22.
//

import Foundation
import RealmSwift

struct NewCategoryLogic {
    
    ///Creates and returns a new category realm object taking a category name parameter
    func createNewCategoryObject(with categoryName: String) -> PersonalCategories {
        
        //Create date string
        let dateString = currentDateString()
        //Create timeInterval since 1970
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        //Create categoryID
        let categoryId = "\(categoryName)\(timeIntervalSince1970)"
        
        //Create Realm object
        let newCategory = PersonalCategories()
        newCategory.categoryName = categoryName
        newCategory.creationDate = dateString
        newCategory.creationTimeSince1970 = timeIntervalSince1970
        newCategory.categoryID = categoryId
        
        return newCategory
    }
    
    ///Add a new Category object to realm
    func addCategoryToRealm(_ newCategory: PersonalCategories) {
        
        let realm = try! Realm()
        do{
            try realm.write {
                realm.add(newCategory)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    ///Returns the current date formatted in --> "dd/MM/YY" as a String.
    func currentDateString() -> String {
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
    
}
