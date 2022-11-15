//
//  AllGroupsLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 25/10/22.
//

import Foundation
import RealmSwift

struct AllGroupsLogic {
    
    ///Returns a Results Groups objects array containing all the groups stored in realm
    func getAllGroupsFromRealm(completion: (Results<Groups>) -> Void) {
        
        let realm = try! Realm()
        completion(realm.objects(Groups.self).sorted(byKeyPath: "creationTimeSince1970", ascending: false))
    }
    
    ///Gets a properly sorted Results list of all groups stored in a realm that contains the text string passed to it
    func getGroupsSearchResult(with text:String , completion: (Results<Groups>) -> Void) {
        let realm = try! Realm()
        
        completion(realm.objects(Groups.self).filter("groupName CONTAINS[cd] %@", text).sorted(byKeyPath: "creationTimeSince1970",ascending: true))
    }
    
    ///Activates all listeners for firebase real time database
    func activateAllFirebaseDatabaseListeners() {
        
        let realm = try! Realm()
        let userEmail = realm.objects(RealmUser.self)[0].email!
        //Start listening for group additions in firebase
        AllGroupsFireDBManager.shared.listenForGroupAdditions(userEmail: userEmail)
        //Start listening to group deletions on firebase
        AllGroupsFireDBManager.shared.listenForGroupDeletions(userEmail: userEmail)
        //Start listening for groupItems addition
        AllGroupsFireDBManager.shared.listenForGroupItemAddition(userEmail: userEmail)
        //Start listening for groupItems deletion
        AllGroupsFireDBManager.shared.listenForGroupItemsDeletions(userEmail: userEmail)
        //Start listening for groupItems Update
        AllGroupsFireDBManager.shared.listenForGroupItemsUpdates(userEmail: userEmail)
        //Start listening for groupParticipants addition
        AllGroupsFireDBManager.shared.listenForParticipantAdditions(userEmail: userEmail)
        //Start listening for groupParticipants deletion
        AllGroupsFireDBManager.shared.listenForParticipantDeletions(userEmail: userEmail)
        //Start listening for group updated to be able to reorganise tableview cells with most recently updated ones at the top
        AllGroupsFireDBManager.shared.listenForGroupUpdates(userEmail: userEmail)
        //Start listening for profile pictures and group images updates
        AllGroupsFireDBManager.shared.listenForNeedToUpdateImages(userEmail: userEmail)
    }
    
}
