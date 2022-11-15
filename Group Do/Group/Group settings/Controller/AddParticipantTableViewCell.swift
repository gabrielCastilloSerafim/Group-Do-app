//
//  AddParticipantTableViewCell.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import UIKit

class AddParticipantTableViewCell: UITableViewCell {

    @IBOutlet weak var profilePictureImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profilePictureImage.layer.cornerRadius = profilePictureImage.frame.height/2
    }

    
    
}
