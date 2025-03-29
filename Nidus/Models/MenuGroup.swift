//
//  MenuGroup.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct MenuGroup: Identifiable, Codable {
    let id: String
    let name: String
    var description: String?
    var displayOrder: Int
    let coffeeShopId: String
    var menuItems: [MenuItem]?
    var createdAt: Date
    var updatedAt: Date
}
