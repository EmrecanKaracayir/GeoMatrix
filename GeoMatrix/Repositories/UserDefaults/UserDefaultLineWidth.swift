//
//  UserDefaultLineWidth.swift
//  GeoMatrix
//
//  Created by Emrecan Karaçayır on 21/4/24.
//

import Foundation
import SwiftUI
import Combine

class UserDefaultLineWidth: ObservableObject {
  @Published var lineWidth: Double = 4
  
  var subscriptions = Set<AnyCancellable>()
  
  init() {
    //loading from the UserDefaults
    if let value = UserDefaults.standard.value(forKey: key) as? Double {
       lineWidth = value
    }
    
    $lineWidth
      .sink { [unowned self] newValue in
        UserDefaults.standard.set(newValue, forKey: self.key)
      }
      .store(in: &subscriptions)
  }
  
  let key = "selectedLineWidth"
}
