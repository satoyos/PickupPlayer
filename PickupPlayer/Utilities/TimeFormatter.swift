//
//  TimeFormatter.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation

struct TimeFormatter {
  static func formatTime(_ time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    let seconds = Int(time) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }
}
