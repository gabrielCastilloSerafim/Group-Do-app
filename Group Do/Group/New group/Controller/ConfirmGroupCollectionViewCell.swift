//
//  ConfirmGroupCollectionViewCell.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 15/11/22.
//

import UIKit

class ConfirmGroupCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var purpleBackground: UIImageView!
    @IBOutlet weak var profilePicture: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        purpleBackground.layer.cornerRadius = purpleBackground.frame.height/2
        
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
    }

}
