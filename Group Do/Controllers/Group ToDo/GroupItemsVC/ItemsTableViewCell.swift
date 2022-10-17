//
//  ItemsTableViewCell.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 14/10/22.
//

import UIKit

class ItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var itemTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
