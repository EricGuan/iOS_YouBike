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

    func initWithData(stopInfo: StopInfo) {
        stopNameLabel.text = stopInfo.stopName
        availableBikeLabel.text = String(stopInfo.availableBike!)
        availableBikeLabel.backgroundColor = stopInfo.availableBike == 0 ? UIColor.redColor() : UIColor(red: 0.004, green: 0.839, blue: 0.004, alpha: 1)
        availableSlotLabel.text = String(stopInfo.availableSlot!)
        availableSlotLabel.backgroundColor = stopInfo.availableSlot == 0 ? UIColor.redColor() : UIColor.orangeColor()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
