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
    
    var addParticipantLogic = AddParticipantLogic()
    let spinner = JGProgressHUD(style: .dark)
    var selectedGroup: Groups? {
        didSet {
            let realmParticipantsArray = selectedGroup?.groupParticipants.sorted(byKeyPath: "isAdmin", ascending: false)
            for participant in realmParticipantsArray! {
                participantsArray.append(participant)
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var participantsArray = [GroupParticipants]()
    var searchResultsArray = [RealmUser]()
    var newSelectedParticipantsArray = [GroupParticipants]()
    
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
        //Update realm with the new participants on group
        addParticipantLogic.addNewParticipantsToRealm(for: selectedGroup!, with: newSelectedParticipantsArray)
        
        let oldParticipantsArray = participantsArray.filter { !newSelectedParticipantsArray.contains($0)}
        
        //Add new participants to old participant's all participants nodes in firebase
        FireDBManager.shared.addNewParticipantsToGroup(oldParticipants: oldParticipantsArray, newParticipants: newSelectedParticipantsArray)
        
        //Add complete group object to users that are being added to the group on firebase
        FireDBManager.shared.addGroupToNewParticipants(selectedGroup: selectedGroup!, newParticipantsArray: newSelectedParticipantsArray, oldParticipantsArray: oldParticipantsArray)
        
        dismiss(animated: true)
    }
    

}

//MARK: - TableView Delegate & DataSource

extension AddParticipantViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableCell", for: indexPath) as! UsersResultsTableViewCell
        
        let imageName = searchResultsArray[indexPath.row].profilePictureFileName
        let userName = searchResultsArray[indexPath.row].fullName
        
        FireStoreManager.shared.getImageURL(imageName: imageName!) { [weak self] resultUrl in
            if let url = resultUrl {
                cell.profilePicture.sd_setImage(with: url)
                cell.nameLabel.text = userName
                self?.spinner.dismiss(animated: true)
            } else {
                //Already have image saved in user device just grab it
                ImageManager.shared.loadPictureFromDisk(fileName: imageName) { profilePicture in
                    cell.profilePicture.image = profilePicture
                    cell.nameLabel.text = userName
                    self?.spinner.dismiss(animated: true)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        spinner.show(in: view)
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedUser = searchResultsArray[indexPath.row]
        let selectedUserEmail = selectedUser.email!
        
        //Check if the user that was selected is already a group participant
        if participantsArray.contains(where: {$0.email! == selectedUserEmail}) == false {
            
            let participantObject = addParticipantLogic.getGroupParticipant(using: selectedUser, and: selectedGroup!)
            
            newSelectedParticipantsArray.append(participantObject)
            participantsArray.append(participantObject)
            
            DispatchQueue.main.async {
                self.spinner.dismiss(animated: true)
                self.collectionView.reloadData()
            }
            
        } else {
            //Present alert action saying that the user already is part of the group
            let alert = addParticipantLogic.getAlert()
            
            DispatchQueue.main.async {
                self.spinner.dismiss(animated: true)
                self.present(alert, animated: true)
            }
        }
    }
    
}

//MARK: - CollectionView Delegate & Datasource

extension AddParticipantViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participantsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCollectionCell", for: indexPath) as! NewGroupCollectionViewCell
        
        let participant = participantsArray[indexPath.row]
        let imageName = participant.profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { [weak self] profileImage in
            
            cell.imageView.image = profileImage
            
            if self!.newSelectedParticipantsArray.contains(participant) {
                cell.xButton.isHidden = false
            } else {
                cell.xButton.isHidden = true
            }
            spinner.dismiss(animated: true)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let participantToRemove = participantsArray[indexPath.row]
        
        newSelectedParticipantsArray.removeAll(where: {$0 == participantToRemove})
        participantsArray.remove(at: indexPath.row)
        
        DispatchQueue.main.async {
            collectionView.reloadData()
        }
    }
    
}

//MARK: - SearchBar Delegate

extension AddParticipantViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        spinner.show(in: view)
        
        addParticipantLogic.getFilteredParticipantsArray(participantsArray: participantsArray) { [weak self] filteredParticipantsArray in
            
            self?.searchResultsArray = filteredParticipantsArray
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
                self?.spinner.dismiss(animated: true)
                self?.tableView.reloadData()
            }
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
