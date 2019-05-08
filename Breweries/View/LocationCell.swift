//
//  LocationCell.swift
//  Breweries
//
//  Created by Edvin Lellhame on 3/23/19.
//  Copyright © 2019 Edvin Lellhame. All rights reserved.
//

import UIKit

class LocationCell: UICollectionViewCell {
    
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var locationTypeLabel: UILabel!
    
    func updateLabels(location: Location) {
        if let locationName = location.name, let locationType = location.type {
            locationNameLabel.text = locationName
            locationTypeLabel.text = locationType
        }
        
    }
    
    func updateLabelsWithNullBreweries() {
        locationNameLabel.text = "Breweries Not Found"
        locationTypeLabel.text = ""
    }
    
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}
