//
//  AddParticipantViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 17/10/22.
//

import UIKit

class AddParticipantViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    var usersArray = Array<RealmUser>()
    var selectedUsersArray = Array<GroupParticipants>()
    
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
        
    }
    

}

//MARK: - TableView Delegate & DataSource

extension AddParticipantViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableCell", for: indexPath) as! UsersResultsTableViewCell
        
        return cell
    }
    
    
}

//MARK: - CollectionView Delegate & Datasource

extension AddParticipantViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsersArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCollectionCell", for: indexPath) as! NewGroupCollectionViewCell
        
        return cell
    }
    
    
}

//MARK: - SearchBar Delegate

extension AddParticipantViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        FireDBManager.shared.getAllUsers { [weak self] realmUsersList in
            
            
            
            
            
            
        }
    }
}
