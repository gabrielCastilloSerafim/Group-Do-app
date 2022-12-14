//
//  AllGroupsFireDBMannager.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 4/11/22.
//

import Foundation
import FirebaseDatabase

final class AllGroupsFireDBManager {
    
    static let shared = AllGroupsFireDBManager()
    private init() {}
    private let database = Database.database().reference()
    
    //MARK: - Listen For Group Additions
    
    ///Listens for new added groups in user's "groups" node and saves it to device
    public func listenForGroupAdditions(userEmail: String) {
        
        let formattedEmail = userEmail.formattedEmail
        
        database.child("\(formattedEmail)/groups").observe(.childAdded) { [weak self] snapshot in
            
            //Transform child snapshotData to a groupObject
            let groupObject = self?.groupSnapshotToObject(with: snapshot)
            
            guard let groupObject = groupObject else {return}
            let groupID = groupObject.groupID!
            let groupPictureName = groupObject.groupPictureName!
            
            //Only proceed to group addition if group is not saved in realm yet
            if self?.groupExistsInRealm(with: groupID) == false {
                
                //Get the downloadURL for group image
                FireStoreManager.shared.getImageURL(imageName: groupPictureName) { url in
                    guard let url = url else {return}
                    //Download the group image
                    FireStoreManager.shared.downloadImageWithURL(imageURL: url) { image in
                        //Save the group Image to device memory
                        ImageManager.shared.saveImageToDeviceMemory(imageName: groupPictureName, image: image) {
                            
                            //Get all participants for the added group
                            let formattedGroupID = groupObject.groupID!.formattedID
                            self?.database.child("\(formattedEmail)/groups/\(formattedGroupID)/participants").observeSingleEvent(of: .value) { snapshot in
                                
                                //Create array of participant objects
                                let groupParticipantObjectsArray = self?.getGroupParticipantObjectsArray(snapshot: snapshot)
                                guard let groupParticipantObjectsArray = groupParticipantObjectsArray else {return}
                                
                                //Use a group participant email in order to get all the items for the added group
                                let withoutSelfParticipant = groupParticipantObjectsArray.filter { $0.email != userEmail }
                                let someParticipantEmail = withoutSelfParticipant.first?.email?.formattedEmail
                                guard let someParticipantEmail = someParticipantEmail else {return}
                                
                                //Get all the group items for the added group from a group participant account
                                self?.database.child("\(someParticipantEmail)/groupItems").observeSingleEvent(of: .value, with: { snapshot in
                                    
                                    //Create array of groupItem objects
                                    let groupID = groupObject.groupID!
                                    let groupItemsObjectsArray = self?.getGroupItemsObjectsArray(snapshot: snapshot, groupID: groupID)
                                    
                                    //Download and save every participants profile picture to device's local storage
                                    self?.downloadAndSaveParticipantsPictures(with: groupParticipantObjectsArray, completion: {
                                        
                                        //Properly add group to realm
                                        self?.saveNewGroupToRealm(with: groupObject, groupParticipantObjectsArray, and: groupItemsObjectsArray ?? [])
                                    })
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Listen For Group Deletions
    
    ///Listens for  group deletions in user's "groups" node and erases the deleted group and all it's related data from device
    public func listenForGroupDeletions(userEmail: String) {
        
        let formattedEmail = userEmail.formattedEmail
        
        database.child("\(formattedEmail)/groups").observe(.childRemoved) { [weak self] snapshot in
            
            //Transform child snapshotData to a groupObject
            let groupObject = self?.groupSnapshotToObject(with: snapshot)
            
            guard let groupObject = groupObject else {return}
            let groupID = groupObject.groupID!
            let groupImageName = groupObject.groupPictureName!
            
            
            //Only proceed to deletion if group still exists in realm
            if self?.checkIfGroupStillExists(for: groupID) == true {
                
                //Delete group from realm
                self?.deleteGroupFromRealm(groupObject)
                //Delete group participants from realm
                self?.deleteGroupParticipantsFromRealm(for: groupObject)
                //Delete group items from realm
                self?.deleteGroupItemsFromRealm(for: groupObject)
                //Check if participants profile picture is being used somewhere else if its not delete it from device memory
                self?.deleteProfilePictures(groupObject: groupObject)
                //Delete group image from device
                ImageManager.shared.deleteImageFromLocalStorage(imageName: groupImageName)
            }
        }
    }
    
    //MARK: - Listen For Group Item Addition
    
    ///Listen for items addition in user's  groupItems node
    public func listenForGroupItemAddition(userEmail: String) {
        
        let formattedEmail = userEmail.formattedEmail
        
        database.child("\(formattedEmail)/groupItems").observe(.childAdded) { [weak self] snapshot in
            
            //Create array of item objects
            let groupItemObject = self?.getGroupItemObject(snapshot: snapshot)
            guard let groupItemObject = groupItemObject else {return}
            
            //Only proceed to item addition if item does not exist in realm yet
            if self?.checkIfGroupItemExistsInRealm(for: groupItemObject) == false {
                
                //Add group item to its corresponding group in realm and change group isSeen property to false
                self?.addGroupItemToRealm(with: groupItemObject)
            }
        }
    }
    
    //MARK: - Listen For Group Items Deletion
    
    ///Listen for group item deletions in firebase
    public func listenForGroupItemsDeletions(userEmail: String) {
        
        let participantEmail = userEmail.formattedEmail
        
        database.child("\(participantEmail)/groupItems").observe(.childRemoved) { [weak self] snapshot in
            
            //Transform item snapshot in item object
            let deletedItemObject = self?.getGroupItemObject(snapshot: snapshot)
            
            //Only proceed if deleted item still exists in realm
            if self?.checkIfGroupItemExistsInRealm(for: deletedItemObject!) == true {
                //Delete item from realm
                self?.deleteGroupItemFromRealm(itemGroupObject: deletedItemObject!)
            }
        }
    }
    
    //MARK: - Listen For Group Items Updates
    
    ///Listens for updates in group items
    public func listenForGroupItemsUpdates(userEmail: String) {
        
        let formattedUserEmail = userEmail.formattedEmail
        
        database.child("\(formattedUserEmail)/groupItems").observe(.childChanged) { [weak self] snapshot in
            
            //Transform snapshot in a groupItemObject
            let updatedGroupItemObject = self?.getGroupItemObject(snapshot: snapshot)
            guard let updatedGroupItemObject = updatedGroupItemObject else {return}
            
            //Update groupItem in realm with the values from the snapshot's updatedGroupItemObject and change group's isSeen property to false
            self?.updateGroupItemInRealm(updatedGroupItem: updatedGroupItemObject)
        }
    }
    
    //MARK: - Listen For Participant Additions
    
    ///Listen for group participant additions
    public func listenForParticipantAdditions(userEmail: String) {
        
        let formattedUserEmail = userEmail.formattedEmail
        
        database.child("\(formattedUserEmail)/groupParticipants").observe(.childAdded) { [weak self] snapshot in
         
            //Transform added user dictionary in a groupParticipant object
            let addedParticipantObject = self?.getGroupParticipantObject(using: snapshot)
            guard let addedParticipantObject = addedParticipantObject else {return}
            let participantProfileImageName = addedParticipantObject.profilePictureFileName!
            
            //Before proceeding with addition check if the user object that we are trying to add already exists in realm
            if self?.checkIfParticipantExistsInRealm(participant: addedParticipantObject) == false {
                
                //Download added user's profile picture and save it to device's memory if it is not saved already
                FireStoreManager.shared.getImageURL(imageName: participantProfileImageName) { url in
                    if let url = url {
                        FireStoreManager.shared.downloadImageWithURL(imageURL: url) { image in
                            ImageManager.shared.saveImageToDeviceMemory(imageName: participantProfileImageName, image: image) {
                                //Add participant to realm
                                self?.addNewGroupParticipantToRealm(participant: addedParticipantObject)
                            }
                        }
                    }
                    //User's profile picture already exists in device memory so just need to update the realm
                    else {
                        //Add participant to realm
                        self?.addNewGroupParticipantToRealm(participant: addedParticipantObject)
                    }
                }
            }
        }
    }
    
    //MARK: - Listen For Participants Deletion
    
    ///Listen for group participants deletions
    public func listenForParticipantDeletions(userEmail: String) {
        
        let formattedUserEmail = userEmail.formattedEmail
        
        database.child("\(formattedUserEmail)/groupParticipants").observe(.childRemoved) { [weak self] snapshot in
            
            //Transform deleted user dictionary in a groupParticipant object
            let deletedParticipantObject = self?.getGroupParticipantObject(using: snapshot)
            guard let deletedParticipantObject = deletedParticipantObject else {return}
            
            //Before proceeding with deletion check if the object that we are trying to delete still exists in realm
            if self?.checkIfParticipantExistsInRealm(participant: deletedParticipantObject) == true {
                
                //Delete participant from realm
                self?.removeDeletedParticipantFromRealm(participant: deletedParticipantObject)
                //Check if participants profile picture is being used somewhere else if its not delete it from device memory
                self?.deleteProfilePictureFromDevice(selectedUser: deletedParticipantObject)
            }
        }
    }
    
    //MARK: - Listen for self user deletion
    
    ///Listens for a deletion of self user's account an exits to the log in area
    public func listenForSelfAccountDeletion(userEmail: String) {
        
        let formattedUserEmail = userEmail.formattedEmail
        
        database.child("\(formattedUserEmail)/isActiveAccount").observe(.childRemoved) { [weak self] _ in
            
            //Clear realm
            self?.deleteAllRealmData()
            //Delete images from system files
            ImageManager.shared.deleAllImagesFromUsersDir()
            //Go to login area
            MainNavigationController.isLoggedIn = false
            NotificationCenter.default.post(name: Notification.Name("DismissGroupsVC"), object: nil)
        }
    }
    
    //MARK: - Listen Group Updates
    
    ///Listen for group updates to be able to reorganise the order of most recently updated groups in the allGroups VC tableView
    public func listenForGroupUpdates(userEmail: String) {
        
        let formattedUserEmail = userEmail.formattedEmail
        
        database.child("\(formattedUserEmail)/groups").observe(.childChanged) { [weak self] snapshot in
            
            //Get and groups object that only contains the creationTimeSince1970 and groupID variables
            let groupObject = self?.getGroupPartialObject(snapshot: snapshot)
            guard let groupObject = groupObject else {return}
            
            //Update group object in realm with the new creationTimeSince1970 value
            self?.updateGroupInRealm(groupID: groupObject.groupID!, creationTimeSince1970: groupObject.creationTimeSince1970)
        }
    }
    
    //MARK: - Listen For Need To Update Images
    
    ///Listens for the creation of a need to update images node in selfUser's node, perform images updates and then deletes the created need to update images node
    public func listenForNeedToUpdateImages(userEmail: String) {
        
        let formattedUserEmail = userEmail.formattedEmail
        
        database.child("\(formattedUserEmail)/picturesToUpdate").observe(.childAdded) { [weak self] snapshot in
            
            //Get the image name to update in a string format
            let imageToUpdateName = snapshot.value as! String
            
            //Get update image URL
            FireStoreManager.shared.getUpdateImageURL(imageName: imageToUpdateName) { url in
                //Download new image from fireStore
                FireStoreManager.shared.downloadImageWithURL(imageURL: url) { image in
                    //Delete old image
                    ImageManager.shared.deleteImageFromLocalStorage(imageName: imageToUpdateName)
                    //Save downloaded image
                    ImageManager.shared.saveImageToDeviceMemory(imageName: imageToUpdateName, image: image) {}
                }
            }
            
            //Get the snapshot node name
            let snapshotNodeName = snapshot.key
            
            //Remove updated image node from firebase picturesToUpdate node
            self?.database.child("\(formattedUserEmail)/picturesToUpdate/\(snapshotNodeName)").removeValue()
        }
    }
    

    
}
