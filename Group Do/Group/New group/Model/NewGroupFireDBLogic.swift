//
//  NewGroupFireDBLogic.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase
import RealmSwift

extension NewGroupFireDBManager {
    
    //MARK: - Create New Group
    
    ///Returns an array of [String:Any] dictionaries containing all the properties of a GroupParticipant object
    func participantsArrayToDict(with participantsObjectArray: Array<GroupParticipants>) -> [[String:Any]] {
        
        var arrayOfParticipantsDict = [[String:Any]]()
        
        for participant in participantsObjectArray {
            
            let participantDictionary: [String:Any] = ["fullName":participant.fullName!,
                                                       "firstName":participant.firstName!,
                                                       "lastName":participant.lastName!,
                                                       "email":participant.email!,
                                                       "profilePictureFileName":participant.profilePictureFileName!,
                                                       "partOfGroupID":participant.partOfGroupID!,
                                                       "isAdmin":participant.isAdmin,
                                                       "notificationToken":participant.notificationToken!
            ]
            arrayOfParticipantsDict.append(participantDictionary)
        }
        return arrayOfParticipantsDict
    }
    
    ///Returns a [String:Any] dictionary containing all the properties of a Groups object including the participants array
    func groupObjectToDict(with groupObject: Groups, and participantsArray: [[String:Any]]) -> [String : Any] {
        
        let group: [String : Any] = [
            "groupName":groupObject.groupName!,
            "creationTimeSince1970":groupObject.creationTimeSince1970,
            "groupID":groupObject.groupID!,
            "groupPictureName":groupObject.groupPictureName!,
            "participants":participantsArray
        ]
        return group
    }
    
    
    
    
    
}
