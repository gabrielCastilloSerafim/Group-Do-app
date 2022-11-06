//
//  LoginLogic.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import RealmSwift

struct LoginLogic {
    
    ///Saves user object to realm
    func saveUserToRealm(_ realmUser: RealmUser) {
        
        let realm = try! Realm()
        do {
            try realm.write({
                realm.add(realmUser)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    
    
}
