//
//  User.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    var firstName: String?
    var lastName: String?
    var phone: String?
    var avatarUrl: String?
    
    // Обчислювана властивість для відображення повного імені
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else if let lastName = lastName {
            return lastName
        } else {
            return email
        }
    }
}
