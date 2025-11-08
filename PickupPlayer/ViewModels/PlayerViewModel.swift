//
//  PlayerViewModel.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import Combine
import UIKit

class PlayerViewModel: ObservableObject {
  @Published var isDraggingSlider = false
  @Published var sliderValue: Double = 0
  @Published var artworkImage: UIImage?

  private let audioPlayerManager: AudioPlayerManager
  private var cancellables = Set<AnyCancellable>()

  init(audioPlayerManager: AudioPlayerManager) {
    self.audioPlayerManager = audioPlayerManager

    // AudioPlayerManagerのcurrentTimeの変化を監視
    audioPlayerManager.$currentTime
      .sink { [weak self] newTime in
        guard let self = self else { return }
        if !self.isDraggingSlider {
          self.sliderValue = newTime
        }
      }
      .store(in: &cancellables)

    // AudioPlayerManagerのcurrentAudioFileの変化を監視してアートワークを更新
    audioPlayerManager.$currentAudioFile
      .sink { [weak self] audioFile in
        guard let self = self else { return }
        if let artworkData = audioFile?.artworkData {
          self.artworkImage = UIImage(data: artworkData)
        } else {
          self.artworkImage = nil
        }
      }
      .store(in: &cancellables)
  }

  // MARK: - Computed Properties

  var currentAudioFile: AudioFile? {
    audioPlayerManager.currentAudioFile
  }

  var isPlaying: Bool {
    audioPlayerManager.isPlaying
  }

  var currentTime: TimeInterval {
    audioPlayerManager.currentTime
  }

  var duration: TimeInterval {
    audioPlayerManager.duration
  }

  var currentTimeFormatted: String {
    // スライダードラッグ中はsliderValueを、通常時はcurrentTimeを表示
    TimeFormatter.formatTime(isDraggingSlider ? sliderValue : currentTime)
  }

  var durationFormatted: String {
    TimeFormatter.formatTime(duration)
  }

  // MARK: - Actions

  func togglePlayPause() {
    audioPlayerManager.togglePlayPause()
  }

  func skipForward() {
    audioPlayerManager.skipForward(seconds: 30)
  }

  func skipBackward() {
    audioPlayerManager.skipBackward(seconds: 30)
  }

  func seek(to time: TimeInterval) {
    audioPlayerManager.seek(to: time)
  }

  func sliderEditingChanged(_ editing: Bool) {
    isDraggingSlider = editing
    if !editing {
      audioPlayerManager.seek(to: sliderValue)
    }
  }
}
