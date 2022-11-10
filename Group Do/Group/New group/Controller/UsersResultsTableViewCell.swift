//
//  UsersResultsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import UIKit

final class UsersResultsTableViewCell: UITableViewCell {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
