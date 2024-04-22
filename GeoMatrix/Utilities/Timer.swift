//
//  Timer.swift
//  GeoMatrix
//
//  Created by Emrecan Karaçayır on 22/4/24.
//

import Foundation
import SwiftUI

extension Timer {
  static func animateNumber(number: Binding<Double>, busy: Binding<Bool>, start: Double, end: Double, duration: Double = 1.0) {
    busy.wrappedValue = true
    let startTime = Date()
    Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true) { timer in
      let now = Date()
      let interval = now.timeIntervalSince(startTime)
      if !busy.wrappedValue {
        timer.invalidate()
      }
      if interval >= duration {
        number.wrappedValue = end
        timer.invalidate()
        busy.wrappedValue = false
      } else {
        number.wrappedValue = start + (end - start) * (interval / duration)
      }
    }
  }
}
