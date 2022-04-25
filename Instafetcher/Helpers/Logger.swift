//
//  Logger.swift
//  Instafetcher
//
//  Created by Igor Penkin on 25.04.2022.
//

import Foundation


final class Logger {
    
    static public func log(object: AnyClass, method: String) {
        print("\(Date()) INFO: [\(object) : \(method)] {\nNo description\n}")
    }
    
    static public func log(object: AnyClass, method: String, message: String) {
        print("\(Date()) INFO: [\(object) : \(method)] {\n\(message)\n}")
    }
    
    static public func log<T>(object: AnyClass, method: String, message: String, body: T, clarification: String? = nil) {
        print("\(Date()) INFO: [\(object) : \(method)] {\n\(message)\n\(body)\n// \(clarification ?? "")\n}")
    }
    
}
