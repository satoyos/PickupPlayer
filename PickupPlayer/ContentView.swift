//
//  ContentView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var playlist = Playlist()
  @StateObject private var audioPlayerManager = AudioPlayerManager()
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      PlaylistView(playlist: playlist, audioPlayerManager: audioPlayerManager, selectedTab: $selectedTab)
        .tabItem {
          Label("プレイリスト", systemImage: "music.note.list")
        }
        .tag(0)

      PlayerView(audioPlayerManager: audioPlayerManager)
        .tabItem {
          Label("プレーヤー", systemImage: "play.circle")
        }
        .tag(1)
    }
  }
}

#Preview {
  ContentView()
}
