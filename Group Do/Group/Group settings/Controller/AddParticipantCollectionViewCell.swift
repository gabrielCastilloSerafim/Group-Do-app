//
//  AddParticipantCollectionViewCell.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 14/11/22.
//

import UIKit

class AddParticipantCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var whiteBackGround: UIImageView!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var xButtonImage: UIImageView!
    @IBOutlet weak var xButtonImageBackground: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        
        whiteBackGround.layer.cornerRadius = whiteBackGround.frame.height/2
    }

}
