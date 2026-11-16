//
//  User.swift
//  wishywash
//
//  Created by Shofia Ghazali on 3/11/26.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var email: String
    var phoneNumber: String?
}
