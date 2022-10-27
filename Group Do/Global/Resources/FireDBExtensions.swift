//
//  FirebaseDBExtensions.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 23/10/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension FireDBManager {
    
    //MARK: - Email/ID Formatters
    
    ///Returns a formatted email String replacing "@" and "." with "_"
    public func emailFormatter(email: String) -> String {
        
        var formattedEmail = email.replacingOccurrences(of: "@", with: "_")
        formattedEmail = formattedEmail.replacingOccurrences(of: ".", with: "_")
        
        return formattedEmail
    }
    
    ///Returns a formatted categoryID String replacing "." with "_"
    public func iDFormatter(id: String) -> String {
        
        let formattedId = id.replacingOccurrences(of: ".", with: "_")
        
        return formattedId
    }
    
    //MARK: - Personal Categories
    
    ///Returns a [String:Any] dictionary containing all the properties of a PersonalCategories object
    func personalCategoryObjectToDict(with categoryObject: PersonalCategories) -> [String: Any] {
        
        let categoryObjectDictionary: [String: Any] = ["categoryName":categoryObject.categoryName!,
                                                       "creationDate":categoryObject.creationDate!,
                                                       "creationTimeSince1970":categoryObject.creationTimeSince1970,
                                                       "categoryID":categoryObject.categoryID!]
        return categoryObjectDictionary
    }
    
    ///Takes a firebase Personal Categories snapshot and returns an PersonalCategories object
    func snapshotToPersonalCategoriesObject(with snapshot: DataSnapshot) -> PersonalCategories? {
        
        let realmPersonalCategoriesObj = PersonalCategories()
        
        guard let snapDict = snapshot.value as? [String:Any] else {return nil}
        
        guard let categoryName = snapDict ["categoryName"] as? String,
              let creationDate = snapDict ["creationDate"] as? String,
              let creationTimeSince1970 = snapDict ["creationTimeSince1970"] as? Double,
              let categoryID = snapDict ["categoryID"] as? String
        else {return nil}
        
        realmPersonalCategoriesObj.categoryName = categoryName
        realmPersonalCategoriesObj.creationDate = creationDate
        realmPersonalCategoriesObj.creationTimeSince1970 = creationTimeSince1970
        realmPersonalCategoriesObj.categoryID = categoryID
        
        return realmPersonalCategoriesObj
    }
    
    //MARK: - Personal Items
    
    ///Returns a [String:Any] dictionary containing all the properties of a PersonalItems object
    func personalItemsObjectToDict(with itemObject: PersonalItems) -> [String: Any] {
        
        let itemsDictionary: [String: Any] = ["itemTitle":itemObject.itemTitle!,
                                              "creationDate":itemObject.creationDate!,
                                              "creationTimeSince1970":itemObject.creationTimeSince1970,
                                              "priority":itemObject.priority!,
                                              "isDone":itemObject.isDone,
                                              "deadLine":itemObject.deadLine!,
                                              "itemID":itemObject.itemID!,
                                              "parentCategoryID":itemObject.parentCategoryID!]
        return itemsDictionary
    }
    
    ///Takes a firebase PersonalItems child snapshot and returns a PersonalItems object
    func snapshotToPersonalItemsObject(with snapshot: DataSnapshot) -> PersonalItems? {
        
        let realmItemObject = PersonalItems()
        
        guard let snapDict = snapshot.value as? [String:Any] else {return nil}
            
            guard let itemTitle = snapDict ["itemTitle"] as? String,
                    let creationDate = snapDict ["creationDate"] as? String,
                    let creationTimeSince1970 = snapDict ["creationTimeSince1970"] as? Double,
                    let priority = snapDict ["priority"] as? String,
                    let isDone = snapDict ["isDone"] as? Bool,
                    let deadLine = snapDict ["deadLine"] as? String,
                    let itemID = snapDict ["itemID"] as? String,
                    let parentCategoryID = snapDict ["parentCategoryID"] as? String
            else {return nil}
            
            realmItemObject.itemTitle = itemTitle
            realmItemObject.creationDate = creationDate
            realmItemObject.creationTimeSince1970 = creationTimeSince1970
            realmItemObject.priority = priority
            realmItemObject.isDone = isDone
            realmItemObject.deadLine = deadLine
            realmItemObject.itemID = itemID
            realmItemObject.parentCategoryID = parentCategoryID
        
        return realmItemObject
    }
    
    //MARK: - Create New Group
    
    ///Returns a [String:Any] dictionary containing all the properties of a Groups object
    func groupObjectToDict(with groupObject: Groups) -> [String:Any] {
        
        let group: [String : Any] = ["groupName":groupObject.groupName!,
                                     "creationTimeSince1970":groupObject.creationTimeSince1970,
                                     "groupID":groupObject.groupID!,
                                     "groupPictureName":groupObject.groupPictureName!
        ]
        return group
    }
    
    ///Returns an array of [String:Any] dictionaries containing all the properties of a GroupParticipant object
    func participantsArrayToDict(with participantsObjectArray: Array<GroupParticipants>) -> [[String:Any]] {
        
        var arrayOfParticipantsDict = Array<[String:Any]>()
        
        for participant in participantsObjectArray {
            
            let participantDictionary: [String:Any] = ["fullName":participant.fullName!,
                                                       "firstName":participant.firstName!,
                                                       "lastName":participant.lastName!,
                                                       "email":participant.email!,
                                                       "profilePictureFileName":participant.profilePictureFileName!,
                                                       "partOfGroupID":participant.partOfGroupID!,
                                                       "isAdmin":participant.isAdmin
            ]
            arrayOfParticipantsDict.append(participantDictionary)
        }
        return arrayOfParticipantsDict
    }
    
    //MARK: - All Groups
    
    ///Takes a snapshot containing a dictionary with the information  of the new added group and returns a group object
    func groupSnapshotToObject(with snapshot:DataSnapshot) -> Groups? {
        
        let groupObject = Groups()
        guard let snapshotDict = snapshot.value as? [String:Any] else {return nil}
        
        guard let groupName = snapshotDict["groupName"] as? String,
              let creationTimeSince1970 = snapshotDict["creationTimeSince1970"] as? Double,
              let groupID = snapshotDict["groupID"] as? String,
              let groupPictureName = snapshotDict["groupPictureName"] as? String
        else {return nil}
        
        groupObject.groupName = groupName
        groupObject.creationTimeSince1970 = creationTimeSince1970
        groupObject.groupID = groupID
        groupObject.groupPictureName = groupPictureName
        
        return groupObject
    }
    
    ///Filters all participants snapshot to contain only participants of the passed in group and use it to create an array of participant objects
    func getGroupParticipantObjectsArray(addedGroup: Groups, snapshot: DataSnapshot) -> Array<GroupParticipants>? {
        
        let addedGroupID = addedGroup.groupID!
        var groupParticipantsArray = Array<GroupParticipants>()
        
        guard let arrayOfParticipantsDict = snapshot.value as? [String:[String:Any]] else {return nil}
        
        for dictionary in  arrayOfParticipantsDict {
            
            if dictionary.value ["partOfGroupID"] as! String == addedGroupID {
                
                let participantObject = GroupParticipants()
                
                guard let fullName = dictionary.value ["fullName"] as? String,
                      let firstName = dictionary.value ["firstName"] as? String,
                      let lastName = dictionary.value ["lastName"] as? String,
                      let email = dictionary.value ["email"] as? String,
                      let profilePictureFileName = dictionary.value ["profilePictureFileName"] as? String,
                      let partOfGroupID = dictionary.value ["partOfGroupID"] as? String,
                      let isAdmin = dictionary.value ["isAdmin"] as? Bool
                else {return nil}
                
                participantObject.fullName = fullName
                participantObject.firstName = firstName
                participantObject.lastName = lastName
                participantObject.email = email
                participantObject.profilePictureFileName = profilePictureFileName
                participantObject.partOfGroupID = partOfGroupID
                participantObject.isAdmin = isAdmin
                
                groupParticipantsArray.append(participantObject)
            }
        }
        return groupParticipantsArray
    }
    
    ///Checks if a group object already exists in realm using the groupID and returns a Boolean true if it does or false if it does not.
    func groupExistsInRealm(with groupID: String) {
        
        let realm = try! Realm()
        
        
        
    }
    
}
