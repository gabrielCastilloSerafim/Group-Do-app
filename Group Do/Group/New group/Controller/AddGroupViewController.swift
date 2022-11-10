//
//  AddGroupViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import UIKit
import RealmSwift
import SDWebImage
import JGProgressHUD

final class AddGroupViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let spinner = JGProgressHUD(style: .dark)
    private var usersArray = Array<RealmUser>()
    private var selectedUserArray = Array<RealmUser>()
    private var addGroupLogic = AddGroupLogic()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UsersResultsTableViewCell", bundle: nil), forCellReuseIdentifier: "UsersTableCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "NewGroupCollectionViewCell" , bundle: nil), forCellWithReuseIdentifier: "customCollectionCell")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    @IBAction func nextButtonPressed(_ sender: UIBarButtonItem) {
        
        if selectedUserArray.count != 0 {
            performSegue(withIdentifier: "NewGroupToCreateGroup", sender: self)
        } else {
            let alert = UIAlertController(title: "No participants added", message: "Please add group participants in order to proceed.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default)
            alert.addAction(action)
            present(alert, animated: true)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ConfirmGroupViewController
        destinationVC.groupParticipants = selectedUserArray
    }
}

//MARK: - TableView Delegate & Datasource

extension AddGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableCell", for: indexPath) as! UsersResultsTableViewCell
        
        let imageName = usersArray[indexPath.row].profilePictureFileName!
        
        FireStoreManager.shared.getImageURL(imageName: imageName) { [weak self] resultUrl in
            if let url = resultUrl {
                cell.nameLabel.text = self?.usersArray[indexPath.row].fullName
                cell.profilePicture.sd_setImage(with: url)
                self?.spinner.dismiss(animated: true)
            } else {
                //Already have image stored in device memory just grab it
                ImageManager.shared.loadPictureFromDisk(fileName: imageName) { profileImage in
                    cell.nameLabel.text = self?.usersArray[indexPath.row].fullName
                    cell.profilePicture.image = profileImage
                    self?.spinner.dismiss(animated: true)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        spinner.show(in: view)
        tableView.deselectRow(at: indexPath, animated: true)
        
        let participant = usersArray[indexPath.row]
        
        if selectedUserArray.contains(participant) {
            
            spinner.dismiss(animated: true)
            present(addGroupLogic.userAlreadyInGroupAlert(), animated: true)
            
        } else {
            selectedUserArray.append(participant)
            //Download and save selected user profile picture
            let imageName = participant.profilePictureFileName!
            
            FireStoreManager.shared.getImageURL(imageName: imageName) { urlResult in
                if let url = urlResult {
                    FireStoreManager.shared.downloadImageWithURL(imageURL: url) { [weak self] profileImage in
                        ImageManager.shared.saveImageToDeviceMemory(imageName: imageName, image: profileImage) {
                            DispatchQueue.main.async {
                                self?.collectionView.reloadData()
                            }
                        }
                    }
                } else {
                    //Already have image in device memory just need to reload collectionView
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
}

//MARK: - CollectionView Delegate & Datasource

extension AddGroupViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if selectedUserArray.count == 0 {
            return 1
        } else {
            return selectedUserArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCollectionCell", for: indexPath) as! NewGroupCollectionViewCell
        
        if selectedUserArray.count != 0 {
            let user = selectedUserArray[indexPath.row]
            let imageName = user.profilePictureFileName!
            
            //Set image to collection cell
            ImageManager.shared.loadPictureFromDisk(fileName: imageName) { profileImage in
                cell.imageView.image = profileImage
                cell.xButtonImage.isHidden = false
                spinner.dismiss(animated: true)
            }
        } else {
            DispatchQueue.main.async {
                cell.imageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
                cell.xButtonImage.isHidden = true
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if usersArray.count == 0 {
            searchBar.becomeFirstResponder()
        }
        if selectedUserArray.count != 0 {
            
            //Check if added profile picture is being used in device else remove it from device memory
            addGroupLogic.deletePhotoFromDeviceMemory(selectedUser: selectedUserArray[indexPath.row])
            
            selectedUserArray.remove(at: indexPath.row)
            
            collectionView.reloadData()
        }
    }
    
}

//MARK: - SearchBar Delegate

extension AddGroupViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        usersArray = []
        spinner.show(in: view)
        
        let searchBarText = searchBar.text!
        
        addGroupLogic.performUserSearch(with: searchBarText) { [weak self] filteredUsersArray in
            
            if filteredUsersArray.isEmpty == false {
                self?.usersArray = filteredUsersArray
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self?.spinner.dismiss(animated: true)
                    self?.present((self?.addGroupLogic.noUsersFoundAlert())!, animated: true)
                }
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

