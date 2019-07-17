//
//  Views.swift
//  StarWars
//
//  Created by Master on 17/07/2019.
//  Copyright © 2019 Kirirushi. All rights reserved.
//

import UIKit

extension UIAlertController {
  static func errorAlertController(title: String, message: String) -> UIAlertController {
    let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
    return errorAlert
  }
}
