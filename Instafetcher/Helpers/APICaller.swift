//
//  APICaller.swift
//  Instafetcher
//
//  Created by Igor Penkin on 25.04.2022.
//

import Foundation


final class APICaller {
    static let shared = APICaller()
    
    struct Constants {
        static let baseAPIURL = "https://graph.instagram.com"
    }
    
    enum HTTPMethod: String {
        case GET
        case POST
        case PUT
        case DELETE
    }
    
    enum APIError: String, Error {
        case failedToGetDate = "Data from Spotify API was not downloaded or reached. Pealse debug APICaller class."
    }
    
    private init() {}
}


extension APICaller {
    
    func getMe() {
        guard let token = AuthManager.shared.accessToken,
              let apiUrl = URL(string: Constants.baseAPIURL + "/me?" + "fields=id,username,account_type,media_count" + "&access_token=\(token)")
        else { fatalError() }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = HTTPMethod.GET.rawValue
        request.timeoutInterval = 20
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Logger.log(object: Self.self, method: #function, message: "Fail data")
                return
            }
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                //JSONDecoder().decode(UserProfile.self, from: data)
                Logger.log(object: Self.self, method: #function, message: "Got user profile model:", body: result)
            } catch {
                Logger.log(object: Self.self, method: #function, message: "Error:", body: error)
            }
        }
        task.resume()
    }
    
    func getMeMedia() {
        guard let token = AuthManager.shared.accessToken,
              let apiUrl = URL(string: Constants.baseAPIURL + "/me/media?" + "fields=id,username,caption,media_type,media_url,permalink,thumbnail_url,timestamp" + "&access_token=\(token)")
        else { fatalError() }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = HTTPMethod.GET.rawValue
        request.timeoutInterval = 20
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Logger.log(object: Self.self, method: #function, message: "Fail data")
                return
            }
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                //JSONDecoder().decode(UserProfile.self, from: data)
                Logger.log(object: Self.self, method: #function, message: "Got media object:", body: result)
            } catch {
                Logger.log(object: Self.self, method: #function, message: "Error:", body: error)
            }
        }
        task.resume()
    }
    
    func getMedia(id: String) {
        guard let token = AuthManager.shared.accessToken,
              let apiUrl = URL(string: Constants.baseAPIURL + "/\(id)?" + "fields=id,username,caption,media_type,media_url,permalink,thumbnail_url,timestamp" + "&access_token=\(token)")
        else { fatalError() }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = HTTPMethod.GET.rawValue
        request.timeoutInterval = 20
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                Logger.log(object: Self.self, method: #function, message: "Fail data")
                return
            }
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                //JSONDecoder().decode(UserProfile.self, from: data)
                Logger.log(object: Self.self, method: #function, message: "Got media object:", body: result)
            } catch {
                Logger.log(object: Self.self, method: #function, message: "Error:", body: error)
            }
        }
        task.resume()
    }
}
