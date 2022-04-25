//
//  AuthManager.swift
//  Instafetcher
//
//  Created by Igor Penkin on 25.04.2022.
//

import Foundation


final class AuthManager {
    
    static let shared = AuthManager()
    
    private var isTokenRefreshing = false
    
    private enum Constants {
        static let clientID = "1026541781288903"
        static let clientSecret = "dece058af8a646843aec9f1d4a38424a"
        static let tokenAPIURL = "https://api.instagram.com/oauth/access_token"
        static let redirectURI = "https://github.com/igorpenkin"
        static let scopes = "user_profile,user_media"
    }
    
    private init() {
    }
    
    public var signInURL: URL? {
        let baseURL = "https://api.instagram.com/oauth/authorize"
        let authURL = "\(baseURL)?client_id=\(Constants.clientID)&redirect_uri=\(Constants.redirectURI)&scope=\(Constants.scopes)&response_type=code"
        return URL(string: authURL)
    }
    
    var isSignedIn: Bool {
         return accessToken != nil
    }
    
    public var userId: String? {
        return UserDefaults.standard.string(forKey: "user_id")
    }
    
    public var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }
        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }
    
    public func exchangeCodeForToken(
        code: String,
        completionHandler: @escaping ((Bool) -> Void)
    ) {
        guard var url = URL(string: Constants.tokenAPIURL) else {
            Logger.log(object: Self.self, method: #function, message: "Was guarded.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var component = URLComponents()
        component.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.clientID),
            URLQueryItem(name: "client_secret", value: Constants.clientSecret),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
        ]
        request.httpBody = component.query?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                completionHandler(false)
                return
            }
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                Logger.log(object: Self.self, method: #function, message: " JSON with tokens data got.", body: result, clarification: nil)
                self?.cacheToken(result: result)
                completionHandler(true)
            } catch {
                Logger.log(object: Self.self, method: #function, message: "❌ An Error was thrown while getting tokens data.")
                completionHandler(false)
            }
        }
        Logger.log(object: Self.self, method: #function, message: "URL Session is started to get tokens.")
        task.resume()
    }
    
    private var onRefreshBloks = [((String) -> Void)]()
    
    /// Supplies valid token to be used with API Calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard !isTokenRefreshing else {
            // Append the completion
            onRefreshBloks.append(completion)
            return
        }
        
        if shouldRefreshToken {
            refreshIfNeeded { [weak self] success in
                if let token = self?.accessToken, success {
                     completion(token)
                }
            }
        } else if let token = accessToken {
             completion(token)
        }
    }
    
    public func refreshIfNeeded(completion: ((Bool) -> Void)? ) {
        Logger.log(object: Self.self, method: #function)
        guard !isTokenRefreshing else {
            Logger.log(object: Self.self, method: #function, message: "Token refreshing is guarded : is refreshing.")
            return
        }
        guard shouldRefreshToken else {
            Logger.log(object: Self.self, method: #function, message: "Token refreshing is guarded : no needs to refresh.")
            completion?(true)
            return
        }
        guard self.refreshToken != nil else {
            Logger.log(object: Self.self, method: #function, message: "Token refreshing is guarded : refresh token is Nil.")
            return
        }
        //Refresh the token
        guard let url = URL(string: Constants.tokenAPIURL) else {
            Logger.log(object: Self.self, method: #function, message: "Token refreshing is guarded : broken API url.")
            return
        }
            
        self.isTokenRefreshing = true
        
        var component = URLComponents()
        component.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: self.refreshToken)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("INFO: \(#function) Failure to get Base64 for basicToken")
            completion?(false)
            return
        }
        
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        request.httpBody = component.query?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.isTokenRefreshing = false
            guard let data = data, error == nil else {
                completion?(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.onRefreshBloks.forEach { $0(result.access_token) }
                self?.onRefreshBloks.removeAll()
                Logger.log(object: Self.self, method: #function, message: "Recieved access token:", body: result.access_token, clarification: nil)
                self?.cacheToken(result: result)
                completion?(true)
            } catch {
                completion?(false)
            }
        }
        task.resume()
        Logger.log(object: Self.self, method: #function, message: "URL Session is started to refresh tokens.")
    }
    
    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.user_id, forKey: "user_id")
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        if let refreshToken = result.refresh_token {
            UserDefaults.standard.setValue(refreshToken, forKey: "refresh_token")
        }
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(600)), forKey: "expirationDate")
        Logger.log(object: Self.self, method: #function, message: "Tokens are cashed.")
    }
    
    public func signOut(completion: (Bool) -> Void) {
        UserDefaults.standard.setValue(nil, forKey: "user_id")
        UserDefaults.standard.setValue(nil, forKey: "access_token")
        UserDefaults.standard.setValue(nil, forKey: "refresh_token")
        UserDefaults.standard.setValue(nil, forKey: "expirationDate")
        if (tokenExpirationDate != nil),
           (userId != nil),
           (accessToken != nil),
           (refreshToken != nil) {
            completion(false)
        }
        completion(true)
    }
}
