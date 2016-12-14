//
//  LoginViewController.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 12/17/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet var loginButton: UIButton?
    @IBOutlet var emailAddress: UITextField?
    @IBOutlet var password: UITextField?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var successLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel?.hidden = true
        successLabel?.hidden = true
        password?.secureTextEntry = true;
        
        loginButton!.addTarget(self, action: #selector(LoginViewController.loginButtonPressed(_:)), forControlEvents: .TouchUpInside)
    }
    
    func loginButtonPressed(sender: UIButton!) {
        errorLabel!.hidden = true
        SparkCloud.sharedInstance().loginWithUser(emailAddress?.text, password: password?.text) { (error:NSError!) -> Void in
            if let _ = error {
                NSLog("Wrong credentials or no internet connectivity, please try again")
                NSLog("Error: " + error.debugDescription)
                self.errorLabel?.hidden = false
            }
            else {
                NSLog("Logged in")
                self.successLabel?.hidden = false
                self.loginButton?.enabled = false
            }
        }
    }
}
