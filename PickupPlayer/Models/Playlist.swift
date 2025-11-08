//
//  Playlist.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import Combine
import SwiftUI

class Playlist: ObservableObject {
  @Published var items: [AudioFile] = []

  init() {
    loadPlaylist()
  }

  func addItem(_ audioFile: AudioFile) {
    items.append(audioFile)
    savePlaylist()
  }

  func removeItems(at offsets: IndexSet) {
    items.remove(atOffsets: offsets)
    savePlaylist()
  }

  func moveItems(from source: IndexSet, to destination: Int) {
    items.move(fromOffsets: source, toOffset: destination)
    savePlaylist()
  }

  func updatePlaybackPosition(for audioFile: AudioFile, position: TimeInterval) {
    if let index = items.firstIndex(where: { $0.id == audioFile.id }) {
      items[index].lastPlaybackPosition = position
      savePlaylist()
    }
  }

  private func savePlaylist() {
    if let encoded = try? JSONEncoder().encode(items) {
      UserDefaults.standard.set(encoded, forKey: "playlist")
    }
  }

  private func loadPlaylist() {
    if let data = UserDefaults.standard.data(forKey: "playlist"),
       let decoded = try? JSONDecoder().decode([AudioFile].self, from: data) {
      items = decoded
    }
  }
}
