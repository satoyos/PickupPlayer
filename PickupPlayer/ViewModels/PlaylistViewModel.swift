//
//  PlaylistViewModel.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import Combine

class PlaylistViewModel: ObservableObject {
  @Published var showingDocumentPicker = false
  @Published var showingMusicPicker = false

  private let playlist: Playlist
  private let audioPlayerManager: AudioPlayerManager

  init(playlist: Playlist, audioPlayerManager: AudioPlayerManager) {
    self.playlist = playlist
    self.audioPlayerManager = audioPlayerManager
  }

  // MARK: - Computed Properties

  var items: [AudioFile] {
    playlist.items
  }

  var isEmpty: Bool {
    playlist.items.isEmpty
  }

  // MARK: - Actions

  func showDocumentPicker() {
    showingDocumentPicker = true
  }

  func showMusicPicker() {
    showingMusicPicker = true
  }

  func deleteItems(at offsets: IndexSet) {
    playlist.removeItems(at: offsets)
  }

  func moveItems(from source: IndexSet, to destination: Int) {
    playlist.moveItems(from: source, to: destination)
  }

  func playAudioFile(_ audioFile: AudioFile) {
    audioPlayerManager.loadAudio(audioFile)
    audioPlayerManager.play()
  }

  func formatTime(_ time: TimeInterval) -> String {
    TimeFormatter.formatTime(time)
  }
}
