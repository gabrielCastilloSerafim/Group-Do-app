//
//  NewGroupCollectionViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 11/10/22.
//

import UIKit

final class NewGroupCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var xButtonImage: UIImageView!
    @IBOutlet weak var xButtonBackground: UIImageView!
    @IBOutlet weak var personImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        
    }
    
    
}
