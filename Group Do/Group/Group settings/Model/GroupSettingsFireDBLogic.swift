//
//  GroupSettingsFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension GroupSettingsFireDBManager {
    
    //MARK: - User Exited Group
    
    ///Returns an array containing all the participants IDs for the participants that have to be deleted
    func getArrayOfParticipantsIDsToDelete(for snapshot: DataSnapshot, using groupID: String) -> [String] {
        
        var arrayOfParticipantsIDsToDelete = [String]()
        
        for child in snapshot.children {
            
            let snap = child as! DataSnapshot
            let dict = snap.value as! [String:Any]
            
            if dict["partOfGroupID"] as? String == groupID {
                let participantEmail = dict["email"] as! String
                let formattedEmail = participantEmail.formattedEmail
                let groupID = dict["partOfGroupID"] as! String
                let formattedGroupID = groupID.formattedID
                let participantID = "\(formattedEmail)\(formattedGroupID)"
                
                arrayOfParticipantsIDsToDelete.append(participantID)
            }
        }
        return arrayOfParticipantsIDsToDelete
    }
    
    ///Returns the correct index on the participants node of the participant that we have to delete in the firebase database
    func getIndexOfParticipantToRemove(with snapshot: DataSnapshot, and participantToRemoveEmail: String) -> String {
        
        var counter = 0
        
        for child in snapshot.children {
            
            let snap = child as! DataSnapshot
            let dict = snap.value as! [String:Any]
            
            if dict["email"] as? String == participantToRemoveEmail {
                break
            } else {
                counter += 1
            }
        }
        return String(counter)
    }
    
    //MARK: - Admin Deleted The Group
    
    ///Gets a groupItems snapshot delete the unwanted items and returns its updated version
    func getArrayOfItemIDsToDelete(for snapshot: DataSnapshot, using groupID: String) -> [String] {
        
        var arrayOfItemIDToDelete = [String]()
        
        for child in snapshot.children {
            
            let snap = child as! DataSnapshot
            let dict = snap.value as! [String:Any]
            
            if dict["fromGroupID"] as? String == groupID {
                arrayOfItemIDToDelete.append(dict["itemID"] as! String)
            }
        }
        return arrayOfItemIDToDelete
    }
    
    //MARK: - Participant Has Been Added To Group
    
    ///Takes an array of groupParticipants objects and transforms it in a groupParticipants dictionary array
    func getGroupParticipantsDictionaryArray(for groupParticipantsArray: [GroupParticipants]) -> [[String: Any]] {
        
        var participantsDictionaryArray = [[String: Any]]()
        
        for participant in groupParticipantsArray {
            
            let participantDict: [String: Any] = [ "fullName": participant.fullName!,
                                                   "firstName": participant.firstName!,
                                                   "lastName": participant.lastName!,
                                                   "email": participant.email!,
                                                   "profilePictureFileName": participant.profilePictureFileName!,
                                                   "partOfGroupID": participant.partOfGroupID!,
                                                   "isAdmin": participant.isAdmin
                                                ]
            participantsDictionaryArray.append(participantDict)
        }
        return participantsDictionaryArray
    }
    
    //MARK: - User Has Been Added To Group
    
    ///Creates and returns a dictionary array containing all the group items for the given group object
    func getAllGroupItemsDictionaryArray(selectedGroup: Groups) -> [[String: Any]] {
        
        let realm = try! Realm()
        let groupItemsArray = realm.objects(GroupItems.self).filter("fromGroupID == %@", selectedGroup.groupID!)
        var groupItemsDictionaryArray = [[String: Any]]()
        
        for item in groupItemsArray {
            
            let itemDict: [String: Any] = ["itemTitle": item.itemTitle!,
                                           "creationDate": item.creationDate!,
                                           "creationTimeSince1970": item.creationTimeSince1970,
                                           "priority": item.priority!,
                                           "isDone": item.isDone,
                                           "deadLine": item.deadLine!,
                                           "itemID": item.itemID!,
                                           "creatorName": item.creatorName!,
                                           "creatorEmail": item.creatorEmail!,
                                           "fromGroupID": item.fromGroupID!,
                                           "completedByUserEmail": item.completedByUserEmail!
                                            ]
            
            groupItemsDictionaryArray.append(itemDict)
        }
        return groupItemsDictionaryArray
    }
    
    ///Creates a complete new group dictionary to add to new users that have been added to the group
    func getCompleteGroupDictionary(groupObject: Groups, allParticipantsDictionaryArray: [[String:Any]], allItemsDictionaryArray: [[String: Any]]) -> [String: Any] {
        
        let groupDictionary: [String: Any] = ["groupName": groupObject.groupName!,
                                              "creationTimeSince1970": groupObject.creationTimeSince1970,
                                              "groupID": groupObject.groupID!,
                                              "groupPictureName": groupObject.groupPictureName!,
                                              "participants": allParticipantsDictionaryArray,
                                              "items": allItemsDictionaryArray
                                                ]
      return groupDictionary
    }
    
    
    
    
    
    
    
    
    
}
