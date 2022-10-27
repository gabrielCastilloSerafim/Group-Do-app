//
//  AddParticipantViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 17/10/22.
//

import UIKit
import RealmSwift
import SDWebImage
import JGProgressHUD

class AddParticipantViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    static var completion: (() -> Void)?
    
    let spinner = JGProgressHUD(style: .dark)
    
    var usersArray = Array<RealmUser>()
    var selectedUsersArray = Array<GroupParticipants>()
    var participantsArray: Results<GroupParticipants>? {
        didSet {
            selectedUsersArray.append(contentsOf: participantsArray!)
            previousParticipantsCount = participantsArray!.count
        }
    }
    var participantsToAddToDatabase = Array<GroupParticipants>()
    var group = Groups()
    var previousParticipantsCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UsersResultsTableViewCell", bundle: nil), forCellReuseIdentifier: "UsersTableCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "NewGroupCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "customCollectionCell")
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        //Update Realm
        let realm = try! Realm()
        let groupObject = realm.objects(Groups.self).filter("groupID CONTAINS %@", group.groupID!)[0]
        do {
            try realm.write({
                groupObject.groupParticipants.append(objectsIn: participantsToAddToDatabase)
                realm.add(groupObject)
            })
        } catch {
            print(error.localizedDescription)
        }
        
        //Add new group participant to firebase
        //FireDBManager.shared.addNewParticipant(participantsArray: participantsToAddToDatabase, group: group)
        
        Self.completion!()
        dismiss(animated: true)
    }
    

}

//MARK: - TableView Delegate & DataSource

extension AddParticipantViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableCell", for: indexPath) as! UsersResultsTableViewCell
        
        let imageName = usersArray[indexPath.row].profilePictureFileName
        
        FireStoreManager.shared.getImageURL(imageName: imageName!) { [weak self] resultUrl in
            if let url = resultUrl {
                cell.profilePicture.sd_setImage(with: url)
                cell.nameLabel.text = self?.usersArray[indexPath.row].fullName
                self?.spinner.dismiss(animated: true)
            } else {
                //Already have image saved in user device just grab it
                ImageManager.shared.loadPictureFromDisk(fileName: imageName) { profilePicture in
                    cell.profilePicture.image = profilePicture
                    cell.nameLabel.text = self?.usersArray[indexPath.row].fullName
                    self?.spinner.dismiss(animated: true)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        spinner.show(in: view)
        tableView.deselectRow(at: indexPath, animated: true)
        
        var contains = false
        let selectedUser = usersArray[indexPath.row]
        
        let participantObject = GroupParticipants()
        participantObject.fullName = selectedUser.fullName
        participantObject.firstName = selectedUser.firstName
        participantObject.lastName = selectedUser.lastName
        participantObject.email = selectedUser.email
        participantObject.profilePictureFileName = selectedUser.profilePictureFileName
        participantObject.partOfGroupID = group.groupID
        participantObject.isAdmin = false
        
        for participant in selectedUsersArray {
            if participantObject.email == participant.email {
                contains = true
            }
        }
        
        if contains == false {
            selectedUsersArray.append(participantObject)
            participantsToAddToDatabase.append(participantObject)
            //Download and save profile picture
            let imageName = selectedUser.profilePictureFileName!
            let userEmail = selectedUser.email!
            FireStoreManager.shared.getImageURL(imageName: imageName) { resultUrl in
                if let url = resultUrl {
                    FireStoreManager.shared.downloadProfileImageWithURL(imageURL: url) { [weak self] profileImage in
                        ImageManager.shared.saveProfileImage(userEmail: userEmail, image: profileImage)
                        DispatchQueue.main.async {
                            self?.collectionView.reloadData()
                        }
                    }
                } else {
                   //Already have image saved in device memory
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
                
            }
        } else {
            spinner.dismiss(animated: true)
            let alert = UIAlertController(title: "User is already a participant", message: "You can only add a participant once.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true)
            contains = false
        }
        
    }
    
}

//MARK: - CollectionView Delegate & Datasource

extension AddParticipantViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsersArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCollectionCell", for: indexPath) as! NewGroupCollectionViewCell
        
        let imageName = selectedUsersArray[indexPath.row].profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { profileImage in
            cell.imageView.image = profileImage
            spinner.dismiss(animated: true)
        }
        
        if indexPath.row < previousParticipantsCount {
            cell.xButton.isHidden = true
            cell.isUserInteractionEnabled = false
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedUsersArray.remove(at: indexPath.row)
        participantsToAddToDatabase.remove(at: indexPath.row - previousParticipantsCount)
        collectionView.reloadData()
    }
    
}

//MARK: - SearchBar Delegate

extension AddParticipantViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        spinner.show(in: view)
        
        FireDBManager.shared.getAllUsers { [weak self] realmUsersList in
            
            var filteredUserList = Array<RealmUser>()
            let realm = try! Realm()
            let selfUserEmail = realm.objects(RealmUser.self)[0].email
            
            for user in realmUsersList {
                
                if user.fullName?.hasPrefix(searchBar.text!) == true && user.email != selfUserEmail {
                    filteredUserList.append(user)
                }
            }
            
            if filteredUserList.isEmpty {
                self?.spinner.dismiss(animated: true)
                let alert = UIAlertController(title: "No users found", message: "There are no matches for the introduced text.", preferredStyle: .alert)
                let action = UIAlertAction(title: "Dismiss", style: .default)
                alert.addAction(action)
                self?.present(alert, animated: true)
            }
            
            self?.usersArray = filteredUserList
            
            searchBar.resignFirstResponder()
            self?.tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
