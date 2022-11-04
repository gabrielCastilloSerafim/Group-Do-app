//
//  NewGroupItemLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 30/10/22.
//

import Foundation
import RealmSwift

struct NewGroupItemLogic {
    
    ///Returns the passed in date from the date picker as string in "dd/MM/YY" format.
    func getDeadLineString(for date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        return dateFormatter.string(from: date)
    }
    
    ///Returns the right priority level string based on the passed in number from the segmented control
    func getPriorityString(for selectedPriorityIndex: Int) -> String {
        
        switch selectedPriorityIndex {
        case 0:
            return "Low"
        case 1:
            return "Medium"
        default:
            return "High"
        }
    }
    
    ///Creates and returns a new GroupItem object
    func createGroupItemObject(itemTitle: String, selectedGroup: Groups, priorityString: String, deadLine: String) -> GroupItems {
        
        let date = Date()
        let timeSince1970 = date.timeIntervalSince1970
        let newItemID = "\(itemTitle)\(timeSince1970)"
        
        let realm = try! Realm()
        let userObject = realm.objects(RealmUser.self)[0]
        let userName = userObject.fullName
        let userEmail = userObject.email
        
        let newItem = GroupItems()
        newItem.itemTitle = itemTitle
        newItem.creationDate = currentDateString()
        newItem.creationTimeSince1970 = timeSince1970
        newItem.priority = priorityString
        newItem.isDone = false
        newItem.deadLine = deadLine
        newItem.itemID = newItemID
        newItem.creatorName = userName
        newItem.creatorEmail = userEmail
        newItem.fromGroupID = selectedGroup.groupID
        newItem.completedByUserEmail = ""
        
        return newItem
    }
    
    ///Adds new group item to realm
    func addGroupItemToRealm(selectedGroup: Groups, newItemObject: GroupItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                selectedGroup.groupItems.append(newItemObject)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Adds new group item object to firebase
    func addGroupItemToFirebase(participantsArray: List<GroupParticipants>, newItemObject: GroupItems) {
        
        var groupParticipantsArray = [GroupParticipants]()
        for participant in participantsArray {
            groupParticipantsArray.append(participant)
        }
        FireDBManager.shared.addGroupItemToFirebase(participantsArray: groupParticipantsArray, groupItemObject: newItemObject)
    }
    
    ///Returns the current data string in the format "dd/MM/YY"
    func currentDateString() -> String {
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
}
