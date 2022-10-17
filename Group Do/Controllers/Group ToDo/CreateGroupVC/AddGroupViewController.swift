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

class AddGroupViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    var usersArray = Array<RealmUser>()
    var selectedUserArray = Array<RealmUser>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UsersResultsTableViewCell", bundle: nil), forCellReuseIdentifier: "UsersTableCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "NewGroupCollectionViewCell" , bundle: nil), forCellWithReuseIdentifier: "customCollectionCell")

    }

    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        
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
        
        let imageName = usersArray[indexPath.row].profilePictureFileName!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableCell", for: indexPath) as! UsersResultsTableViewCell
        
        FireStoreManager.shared.getImageURL(imageName: imageName) { [weak self] url in
            cell.nameLabel.text = self?.usersArray[indexPath.row].fullName
            cell.profilePicture.sd_setImage(with: url)
            self?.spinner.dismiss(animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        spinner.show(in: view)
        
        let participant = usersArray[indexPath.row]
        
        if selectedUserArray.contains(participant) {
            print("Already has participant")
            
            let alert = UIAlertController(title: "User already in group", message: "Please add a different user", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default)
            alert.addAction(action)
            present(alert, animated: true)
            
        } else {
            selectedUserArray.append(usersArray[indexPath.row])
        }
        
        collectionView.reloadData()
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
            let email = user.email
            
            FireStoreManager.shared.getImageURL(imageName: imageName) { [weak self] url in
                //Set profile picture image on cell
                DispatchQueue.main.async {
                    cell.imageView.sd_setImage(with: url) { _, _, _, _ in
                        cell.xButton.isHidden = false
                    }
                    self?.spinner.dismiss(animated: true)
                }
                //Download profile picture image
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let image = UIImage(data: data!) else {
                        return
                    }
                    //Save profile picture image to users phone
                    ImageManager.shared.saveImage(userEmail: email!, image: image)
                }.resume()
            }
        } else {
            DispatchQueue.main.async {
                cell.imageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
                cell.xButton.isHidden = true
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if usersArray.count == 0 {
            searchBar.becomeFirstResponder()
        }
        if selectedUserArray.count != 0 {
            
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
        //Perform users search using search bar text
        FireDBManager.shared.getAllUsers { [weak self] firebaseUsersArray in
            
            let realm = try! Realm()
            let selfUser = realm.objects(RealmUser.self)
            let selfUserEmail = selfUser[0].email
            
            var filteredUsersArray = Array<RealmUser>()
            
            for user in firebaseUsersArray {
                
                if user.email != selfUserEmail {
                    
                    if user.fullName?.lowercased().hasPrefix(searchBar.text!.lowercased()) == true {
                        filteredUsersArray.append(user)
                    }
                }
            }
            if filteredUsersArray.isEmpty == false {
                self?.usersArray = filteredUsersArray
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else {
                let alert = UIAlertController(title: "No users found", message: "Could not find user match", preferredStyle: .alert)
                let action = UIAlertAction(title: "Dismiss", style: .default)
                alert.addAction(action)
                DispatchQueue.main.async {
                    self?.spinner.dismiss(animated: true)
                    self?.present(alert, animated: true)
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
