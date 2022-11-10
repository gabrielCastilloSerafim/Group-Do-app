//
//  CreatedByMeTableViewCell.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 10/11/22.
//

import UIKit

class CreatedByMeTableViewCell: UITableViewCell {

    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var priorityImage: UIImageView!
    @IBOutlet weak var deadLine: UILabel!
    @IBOutlet weak var typeOfItem: UILabel!
    @IBOutlet weak var greenBackground: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        greenBackground.layer.cornerRadius = greenBackground.frame.height/5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
