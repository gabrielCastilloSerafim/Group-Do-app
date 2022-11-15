//
//  NewGroupCollectionViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import UIKit

final class NewGroupCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var whiteBackground: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var xButtonImage: UIImageView!
    @IBOutlet weak var xButtonBackground: UIImageView!
    @IBOutlet weak var personImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        whiteBackground.layer.cornerRadius = whiteBackground.frame.height/2
        
        imageView.layer.cornerRadius = imageView.frame.height/2
        
    }
    
    
}
