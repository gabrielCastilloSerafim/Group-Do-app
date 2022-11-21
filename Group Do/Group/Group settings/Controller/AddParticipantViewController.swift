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

final class AddParticipantViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
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
        
        searchBar.becomeFirstResponder()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "AddParticipantTableViewCell", bundle: nil), forCellReuseIdentifier: "AddParticipantTableViewCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "AddParticipantCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AddParticipantCollectionViewCell")
        
        //Listen for delete notifications from parent VC
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("DismissModalAddParticipants"), object: nil)
    }
    
    //When observer gets notified it means that the group has been deleted and needs to dismiss current modal presentation
    @objc func methodOfReceivedNotification(notification: Notification) {
        dismiss(animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        
        //Check if user added someone and if not show alert
        if newSelectedParticipantsArray.isEmpty {
            let alert = UIAlertController(title: "Error", message: "Please select new participants.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        //Update realm with the new participants on group
        addParticipantLogic.addNewParticipantsToRealm(for: selectedGroup!, with: newSelectedParticipantsArray)
        
        let oldParticipantsArray = participantsArray.filter { !newSelectedParticipantsArray.contains($0)}
        
        //Add new participants to old participant's all participants nodes in firebase
        GroupSettingsFireDBManager.shared.addNewParticipantsToGroup(oldParticipants: oldParticipantsArray, newParticipants: newSelectedParticipantsArray)
        
        //Add complete group object to users that are being added to the group on firebase
        GroupSettingsFireDBManager.shared.addGroupToNewParticipants(selectedGroup: selectedGroup!, newParticipantsArray: newSelectedParticipantsArray, oldParticipantsArray: oldParticipantsArray)
        
        dismiss(animated: true)
    }
    

}

//MARK: - TableView Delegate & DataSource

extension AddParticipantViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddParticipantTableViewCell", for: indexPath) as! AddParticipantTableViewCell
        
        let imageName = searchResultsArray[indexPath.row].profilePictureFileName
        let userName = searchResultsArray[indexPath.row].fullName
        
        FireStoreManager.shared.getImageURL(imageName: imageName!) { [weak self] resultUrl in
            if let url = resultUrl {
                DispatchQueue.main.async {
                    cell.nameLabel.text = userName
                    cell.profilePictureImage.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "defaultUserPicture.pdf"))
                    self?.spinner.dismiss(animated: true)
                }
            } else {
                //Already have image saved in user device just grab it
                ImageManager.shared.loadPictureFromDisk(fileName: imageName) { profilePicture in
                    DispatchQueue.main.async {
                        cell.profilePictureImage.image = profilePicture
                        cell.nameLabel.text = userName
                        self?.spinner.dismiss(animated: true)
                    }
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
            let participantProfileImageName = participantObject.profilePictureFileName!
            
            newSelectedParticipantsArray.append(participantObject)
            participantsArray.append(participantObject)
            
            //Download and save user photo to device storage if it does not exist yet
            FireStoreManager.shared.getImageURL(imageName: participantProfileImageName) { url in
                if let url = url {
                    FireStoreManager.shared.downloadImageWithURL(imageURL: url) { image in
                        ImageManager.shared.saveImageToDeviceMemory(imageName: participantProfileImageName, image: image) {
                            DispatchQueue.main.async {
                                self.spinner.dismiss(animated: true)
                                self.collectionView.reloadData()
                            }
                        }
                    }
                }
                //Image already exists in device memory just update collection view
                else {
                    DispatchQueue.main.async {
                        self.spinner.dismiss(animated: true)
                        self.collectionView.reloadData()
                    }
                }
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
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddParticipantCollectionViewCell", for: indexPath) as! AddParticipantCollectionViewCell
        
        let participant = participantsArray[indexPath.row]
        let imageName = participant.profilePictureFileName
        
        ImageManager.shared.loadPictureFromDisk(fileName: imageName) { [weak self] profileImage in
            
            DispatchQueue.main.async {
                cell.profilePicture.image = profileImage
            }
            
            if self!.newSelectedParticipantsArray.contains(participant) {
                DispatchQueue.main.async {
                    cell.xButtonImage.isHidden = false
                    cell.xButtonImageBackground.isHidden = false
                    cell.isUserInteractionEnabled = true
                }
            } else {
                DispatchQueue.main.async {
                    cell.xButtonImage.isHidden = true
                    cell.xButtonImageBackground.isHidden = true
                    cell.isUserInteractionEnabled = false
                }
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
        
        let searchBarText = searchBar.text!
        
        addParticipantLogic.getFilteredParticipantsArray(participantsArray: participantsArray, searchBarText: searchBarText) { [weak self] filteredParticipantsArray in
            
            if filteredParticipantsArray.isEmpty {
                
                let alert = UIAlertController(title: "No users found", message: "Could not find user match.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self?.present(alert, animated: true)
            } else {
                
                self?.searchResultsArray = filteredParticipantsArray
            }
            
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
