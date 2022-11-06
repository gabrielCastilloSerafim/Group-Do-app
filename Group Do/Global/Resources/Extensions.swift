//
//  ViewControllerExtensions.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 9/10/22.
//

import UIKit

//MARK: - Current date string formatter
extension UIViewController {
    
    ///Returns the current date formatted in --> "dd/MM/YY" as a String.
    public func currentDateString() -> String {
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
}

//MARK: - Email & ID Formatters

extension String {
    
    var formattedID: String {
        
        let formattedId = self.replacingOccurrences(of: ".", with: "_")
        return formattedId
    }
    
    var formattedEmail: String {
        
        var formattedEmail = self.replacingOccurrences(of: "@", with: "_")
        formattedEmail = formattedEmail.replacingOccurrences(of: ".", with: "_")
        return formattedEmail
    }
}
