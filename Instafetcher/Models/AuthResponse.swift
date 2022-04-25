//
//  AuthResponse.swift
//  Instafetcher
//
//  Created by Igor Penkin on 25.04.2022.
//

import Foundation


struct AuthResponse: Decodable {
    var user_id: Int
    var access_token: String
    var expires_in: Int?
    var refresh_token: String?
    var scope: String?
}
