//
//  Location.swift
//  Breweries
//
//  Created by Edvin Lellhame on 3/23/19.
//  Copyright © 2019 Edvin Lellhame. All rights reserved.
//

import Foundation

class Location {
    let city: String?
    let state: String?
    let street: String?
    let zip: String?
    let name: String?
    let rating: String?
    let phone: String?
    let type: String?
    let url: String?
    let id: String?
    
    init(json: [String: AnyObject]) {
        self.city = json["city"] as? String
        self.state = json["state"] as? String
        self.street = json["street"] as? String
        self.zip = json["zip"] as? String
        self.name = json["name"] as? String
        self.rating = json["overall"] as? String
        self.phone = json["phone"] as? String
        self.type = json["status"] as? String
        self.url = json["url"] as? String
        self.id = json["id"] as? String
    }
    
    
}
