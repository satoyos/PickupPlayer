//
//  PlaylistView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import SwiftUI

struct PlaylistView: View {
  @ObservedObject var playlist: Playlist
  @StateObject private var viewModel: PlaylistViewModel
  @StateObject private var musicPickerViewModel: MusicPickerViewModel
  @Binding var selectedTab: Int

  init(playlist: Playlist, audioPlayerManager: AudioPlayerManager, selectedTab: Binding<Int>) {
    self.playlist = playlist
    _viewModel = StateObject(wrappedValue: PlaylistViewModel(playlist: playlist, audioPlayerManager: audioPlayerManager))
    _musicPickerViewModel = StateObject(wrappedValue: MusicPickerViewModel(playlist: playlist))
    self._selectedTab = selectedTab
  }

  var body: some View {
    NavigationView {
      VStack {
        if viewModel.isEmpty {
          // プレイリストが空の場合
          VStack(spacing: 20) {
            Image(systemName: "music.note.list")
              .font(.system(size: 60))
              .foregroundColor(.gray)
            Text("プレイリストが空です")
              .font(.headline)
              .foregroundColor(.gray)
            Text("ファイルを追加して再生を開始しましょう")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          // プレイリストの表示
          List {
            ForEach(viewModel.items) { audioFile in
              Button(action: {
                viewModel.playAudioFile(audioFile)
                selectedTab = 1 // プレーヤータブに遷移
              }) {
                HStack(spacing: 12) {
                  // アートワーク表示
                  if let artworkData = audioFile.artworkData,
                     let uiImage = UIImage(data: artworkData) {
                    Image(uiImage: uiImage)
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                      .frame(width: 50, height: 50)
                      .cornerRadius(4)
                      .clipped()
                  } else {
                    // デフォルトアイコン
                    ZStack {
                      RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                      Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    }
                  }

                  VStack(alignment: .leading, spacing: 4) {
                    Text(audioFile.title)
                      .font(.headline)
                      .foregroundColor(.primary)
                    Text(viewModel.formatTime(audioFile.duration))
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                  if audioFile.lastPlaybackPosition > 0 {
                    Text(viewModel.formatTime(audioFile.lastPlaybackPosition))
                      .font(.caption)
                      .foregroundColor(.blue)
                  }
                }
              }
            }
            .onDelete(perform: viewModel.deleteItems)
            .onMove(perform: viewModel.moveItems)
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("プレイリスト")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button(action: viewModel.showDocumentPicker) {
              Label("ファイルから選択", systemImage: "folder")
            }
            Button(action: viewModel.showMusicPicker) {
              Label("ミュージックライブラリから選択", systemImage: "music.note")
            }
          } label: {
            Image(systemName: "plus")
          }
        }
        ToolbarItem(placement: .navigationBarLeading) {
          EditButton()
        }
      }
      .sheet(isPresented: $viewModel.showingDocumentPicker) {
        DocumentPickerView(playlist: playlist)
      }
      .sheet(isPresented: $viewModel.showingMusicPicker) {
        MusicPickerView(viewModel: musicPickerViewModel)
      }
      .overlay(alignment: .bottom) {
        if musicPickerViewModel.isExporting {
          ExportProgressView(exportTasks: musicPickerViewModel.exportTasks)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut, value: musicPickerViewModel.exportTasks.count)
        }
      }
    }
  }
}
