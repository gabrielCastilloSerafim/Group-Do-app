//
//  GroupsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 13/10/22.
//

import UIKit

final class GroupsTableViewCell: UITableViewCell {

    @IBOutlet weak var greenBackgroundView: UIView!
    @IBOutlet weak var notificationCircle: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var numberOfUncompletedTasks: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        groupImage.layer.cornerRadius = groupImage.frame.height/2
        greenBackgroundView.layer.cornerRadius = greenBackgroundView.frame.height/5
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
