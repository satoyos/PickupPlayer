//
//  PlaybackStateManager.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation

class PlaybackStateManager {
  static let shared = PlaybackStateManager()

  private init() {}

  func savePlaybackPosition(for audioFileID: UUID, position: TimeInterval) {
    UserDefaults.standard.set(position, forKey: "playback_\(audioFileID.uuidString)")
  }

  func loadPlaybackPosition(for audioFileID: UUID) -> TimeInterval {
    return UserDefaults.standard.double(forKey: "playback_\(audioFileID.uuidString)")
  }

  func clearPlaybackPosition(for audioFileID: UUID) {
    UserDefaults.standard.removeObject(forKey: "playback_\(audioFileID.uuidString)")
  }
}
