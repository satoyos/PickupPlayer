//
//  NowPlayingManager.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import MediaPlayer
import UIKit

class NowPlayingManager {
  static let shared = NowPlayingManager()

  private init() {
    setupRemoteCommands()
  }

  func updateNowPlayingInfo(
    title: String,
    duration: TimeInterval,
    currentTime: TimeInterval,
    isPlaying: Bool,
    artwork: UIImage? = nil,
    sleepTimerRemaining: TimeInterval? = nil
  ) {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

    // スリープタイマー情報をアーティスト欄に表示
    if let remaining = sleepTimerRemaining, remaining > 0 {
      let minutes = Int(remaining) / 60
      let seconds = Int(remaining) % 60
      nowPlayingInfo[MPMediaItemPropertyArtist] = String(format: "🌙 %02d:%02d", minutes, seconds)
    }

    // アートワーク画像を設定
    if let artwork = artwork {
      nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
        artwork
      }
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  func clearNowPlayingInfo() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }

  private func setupRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()

    // Play/Pauseコマンド
    commandCenter.playCommand.addTarget { _ in
      NotificationCenter.default.post(name: .remotePlay, object: nil)
      return .success
    }

    commandCenter.pauseCommand.addTarget { _ in
      NotificationCenter.default.post(name: .remotePause, object: nil)
      return .success
    }

    commandCenter.togglePlayPauseCommand.addTarget { _ in
      NotificationCenter.default.post(name: .remoteTogglePlayPause, object: nil)
      return .success
    }

    // スキップコマンド
    commandCenter.skipForwardCommand.preferredIntervals = [30]
    commandCenter.skipForwardCommand.addTarget { _ in
      NotificationCenter.default.post(name: .remoteSkipForward, object: nil)
      return .success
    }

    commandCenter.skipBackwardCommand.preferredIntervals = [30]
    commandCenter.skipBackwardCommand.addTarget { _ in
      NotificationCenter.default.post(name: .remoteSkipBackward, object: nil)
      return .success
    }
  }
}

// リモートコントロール用のNotification名
extension Notification.Name {
  static let remotePlay = Notification.Name("remotePlay")
  static let remotePause = Notification.Name("remotePause")
  static let remoteTogglePlayPause = Notification.Name("remoteTogglePlayPause")
  static let remoteSkipForward = Notification.Name("remoteSkipForward")
  static let remoteSkipBackward = Notification.Name("remoteSkipBackward")
}
