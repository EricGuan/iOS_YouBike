//
//  bikeStop_TableViewCell.swift
//  YouBike
//
//  Created by Ka Ho on 8/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import UIKit

class bikeStop_TableViewCell: UITableViewCell {

    @IBOutlet weak var stopNameLabel, availableBikeLabel, availableSlotLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        stopNameLabel.adjustsFontSizeToFitWidth = true
        availableBikeLabel.layer.cornerRadius = 5
        availableBikeLabel.layer.masksToBounds = true
        availableSlotLabel.layer.cornerRadius = 5
        availableSlotLabel.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
