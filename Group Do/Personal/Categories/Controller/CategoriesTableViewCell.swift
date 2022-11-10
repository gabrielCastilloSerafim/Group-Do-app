//
//  CategoriesTableViewCell.swift
//  Group Task
//
//  Created by Gabriel Castillo Serafim on 8/11/22.
//

import UIKit

class CategoriesTableViewCell: UITableViewCell {

    @IBOutlet weak var greenBackground: UIView!
    @IBOutlet weak var uncompletedTasksNumber: UILabel!
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        greenBackground.layer.cornerRadius = greenBackground.frame.height/5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
