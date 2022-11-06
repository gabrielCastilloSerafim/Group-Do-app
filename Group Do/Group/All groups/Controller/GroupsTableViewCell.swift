//
//  GroupsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 13/10/22.
//

import UIKit

final class GroupsTableViewCell: UITableViewCell {

    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
