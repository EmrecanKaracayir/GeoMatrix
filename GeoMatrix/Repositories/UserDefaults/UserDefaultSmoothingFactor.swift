//
//  UserDefaultLineWidth.swift
//  GeoMatrix
//
//  Created by Emrecan Karaçayır on 21/4/24.
//

import Foundation
import SwiftUI
import Combine

class UserDefaultSmoothingFactor: ObservableObject {
  @Published var smoothingFactor: Double = 0
  
  var subscriptions = Set<AnyCancellable>()
  
  init() {
    //loading from the UserDefaults
    if let value = UserDefaults.standard.value(forKey: key) as? Double {
      smoothingFactor = value
    }
    
    $smoothingFactor
      .sink { [unowned self] newValue in
        UserDefaults.standard.set(newValue, forKey: self.key)
      }
      .store(in: &subscriptions)
  }
  
  let key = "selectedSmoothingFactor"
}
