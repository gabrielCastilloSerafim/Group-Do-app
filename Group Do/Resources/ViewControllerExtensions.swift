//
//  ViewControllerExtensions.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 9/10/22.
//

import UIKit


extension UIViewController {
    
    //MARK: - Current date string formatter
    
    ///Returns the current date formatted in --> "YY/MM/dd" as a String.
    public func currentDateString() -> String {
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY/MM/dd"
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
    
    
}


