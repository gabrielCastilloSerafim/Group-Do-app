//
//  GroupsViewController.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 7/10/22.
//

import UIKit
import FirebaseAuth

class GroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var groupsArray = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        groupsArray.append("Hello")
        groupsArray.append("Bye")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkLoginStatus()
        
    }
    
    private func checkLoginStatus() {
        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "GroupsToLogin", sender: self)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        
        
        
        
    }
    
}

//MARK: - TableView Delegate & DataSource

extension GroupsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return groupsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath)
        
        cell.textLabel?.text = groupsArray[indexPath.row]
        
        return cell
        
    }
    
    
    
    
}
