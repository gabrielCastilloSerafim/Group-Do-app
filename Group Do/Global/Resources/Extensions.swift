//
//  ViewControllerExtensions.swift
//  Group Do
//
//  Created by Gabriel Castillo Serafim on 9/10/22.
//

import UIKit
import FirebaseAuth

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

//MARK: - Dismiss Keyboard When Tapped Around

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

//MARK: - Keyboard Obstructing TextFields Management

extension UIViewController {
    
    func setupKeyboardHiding() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(sender: NSNotification) {

        guard let userInfo = sender.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let currentTextField = UIResponder.currentFirst() as? UITextField
        else { return }

        // check if the top of the keyboard is above the bottom of the currently focused textBox ...
        let keyboardTopY = keyboardFrame.cgRectValue.origin.y
        let convertedTextFieldFrame = view.convert(currentTextField.frame, from: currentTextField.superview)
        let textFieldBottomY = convertedTextFieldFrame.origin.y + convertedTextFieldFrame.size.height

        // if textField bottom is below keyboard bottom - bump the frame up
        if textFieldBottomY > keyboardTopY {
            let textFieldHeight:Double = 70
            let textBoxY = convertedTextFieldFrame.origin.y
            let newFrameY = (textBoxY - keyboardTopY + textFieldHeight) * -1
            view.frame.origin.y = newFrameY
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
}

//MARK: - Checks Textfield Is Being Activated

extension UIResponder {
    
    private struct Static {
        static weak var responder: UIResponder?
    }
    
    /// Finds the current first responder
    /// - Returns: the current UIResponder if it exists
    static func currentFirst() -> UIResponder? {
        Static.responder = nil
        UIApplication.shared.sendAction(#selector(UIResponder._trap), to: nil, from: nil, for: nil)
        return Static.responder
    }
    
    @objc private func _trap() {
        Static.responder = self
    }
}

//MARK: - Show Firebase Auth Error As Alert

extension UIViewController {

    //Get the error code from error in login/register VC and calls the errorMessage computed property on it if the switch case matches one of the messages that we customised we show that on alert otherwise we show the localised description on alert.
    func handleFireAuthError(error: Error) {

        if let errorCode = AuthErrorCode.Code(rawValue: error._code) {
            
            if let errorMessage = errorCode.errorMessage {
                //Show custom alert "errorMessage did not return nil"
                let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default)
                alert.addAction(okAction)
                present(alert, animated: true)
                        
            } else {
                //Show localised description "errorMessage returned nil"
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default)
                    alert.addAction(okAction)
                    present(alert, animated: true)
            }
        }
    }
}

//MARK: - Assign Some Of Custom Error Messages To Firebase Auth Default Errors

extension AuthErrorCode.Code {
    //Computed property
    var errorMessage: String? {
        //We are switching on the original enum that contains all the errors from firebase and changing the return for the ones that we want.
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account."
        case .invalidEmail:
            return "Please enter a valid Email."
        case .networkError:
            return "Network error. Please try again."
        case .wrongPassword:
            return "Password is not correct, please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
            
        default:
            return nil
        }
    }
}
