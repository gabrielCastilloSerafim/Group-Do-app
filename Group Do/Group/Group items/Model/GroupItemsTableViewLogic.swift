//
//  GroupItemsTableViewLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 3/11/22.
//

import Foundation
import RealmSwift

struct GroupItemsTableViewLogic {
    
    ///Updates realm with the correct information for a task completion
    func updateRealmForCompletedTask(selectedItem: GroupItems, selfUserEmail: String) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                selectedItem.completedByUserEmail = selfUserEmail
                selectedItem.isDone = !selectedItem.isDone
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Updates realm with the correct information for a task marked undone
    func updateRealmForUndoneCompletedTask(selectedItem: GroupItems) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                selectedItem.completedByUserEmail = ""
                selectedItem.isDone = !selectedItem.isDone
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    ///Sends push notifications to all participants of  the group containing the new completed item information
    func sendPushNotificationToParticipants(participantsArray: List<GroupParticipants>, itemTitle: String, selectedGroup: Groups) {
        
        let realm = try! Realm()
        let selfUser = realm.objects(RealmUser.self)[0]
        let userName = selfUser.fullName!
        let userEmail = selfUser.email!
        
        for participant in participantsArray {
            
            let token = participant.notificationToken!
            let participantEmail = participant.email!
            
            if participantEmail != userEmail {
                
                PushNotificationSender.shared.sendPushNotification(to: token, title: "Task completed", body: #"\#(userName) completed task: "\#(itemTitle)" from group: "\#(selectedGroup.groupName!)". "#)
            }
        }
    }

    
}
