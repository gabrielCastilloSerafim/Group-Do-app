//
//  GroupItemsCollectionViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit

final class GroupItemsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var whiteBackground: UIImageView!
    @IBOutlet weak var profilePicture: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        
        whiteBackground.layer.cornerRadius = whiteBackground.frame.height/2
    }

}
