//
//  PlayerView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import SwiftUI

struct PlayerView: View {
  @StateObject private var viewModel: PlayerViewModel
  @State private var showSleepTimerSheet = false

  init(audioPlayerManager: AudioPlayerManager) {
    _viewModel = StateObject(wrappedValue: PlayerViewModel(audioPlayerManager: audioPlayerManager))
  }

  var body: some View {
    VStack(spacing: 20) {
      // アートワーク画像
      Group {
        if let artworkImage = viewModel.artworkImage {
          Image(uiImage: artworkImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(40)
        } else {
          Image(systemName: "music.note")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(.gray.opacity(0.3))
            .padding(40)
        }
      }

      // ファイル名
      if let audioFile = viewModel.currentAudioFile {
        Text(audioFile.title)
          .font(.headline)
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }

      // スリープタイマー表示 / 設定ボタン（入れ替え表示）
      if viewModel.isSleepTimerActive {
        // タイマー有効時：残り時間を表示
        HStack {
          Image(systemName: "moon.fill")
            .foregroundColor(.orange)
          Text(viewModel.sleepTimerRemainingFormatted)
            .font(.subheadline)
            .foregroundColor(.orange)
          Spacer()
          Button("キャンセル") {
            viewModel.cancelSleepTimer()
          }
          .font(.caption)
          .foregroundColor(.orange)
        }
        .padding(.horizontal)
      } else {
        // タイマー無効時：設定ボタンを表示
        Button(action: {
          showSleepTimerSheet = true
        }) {
          HStack {
            Image(systemName: "moon")
            Text("スリープタイマー")
          }
        }
      }

      // 再生時間表示
      HStack {
        Text(viewModel.currentTimeFormatted)
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
        Text(viewModel.durationFormatted)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal)

      // 再生位置スライダー
      Slider(
        value: $viewModel.sliderValue,
        in: 0...max(viewModel.duration, 1),
        onEditingChanged: viewModel.sliderEditingChanged
      )
      .padding(.horizontal)

      // コントロールボタン
      HStack(spacing: 40) {
        // 30秒巻き戻しボタン
        Button(action: viewModel.skipBackward) {
          Image(systemName: "gobackward.30")
            .font(.system(size: 40))
        }

        // Play/Pauseボタン
        Button(action: viewModel.togglePlayPause) {
          Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 60))
        }

        // 30秒早送りボタン
        Button(action: viewModel.skipForward) {
          Image(systemName: "goforward.30")
            .font(.system(size: 40))
        }
      }
      .padding(.bottom, 20)
    }
    .padding()
    .confirmationDialog("スリープタイマー", isPresented: $showSleepTimerSheet) {
      Button("5分") {
        viewModel.setSleepTimer(minutes: 5)
      }
      Button("10分") {
        viewModel.setSleepTimer(minutes: 10)
      }
      Button("15分") {
        viewModel.setSleepTimer(minutes: 15)
      }
      Button("20分") {
        viewModel.setSleepTimer(minutes: 20)
      }
      Button("30分") {
        viewModel.setSleepTimer(minutes: 30)
      }
      if viewModel.isSleepTimerActive {
        Button("キャンセル", role: .destructive) {
          viewModel.cancelSleepTimer()
        }
      }
      Button("閉じる", role: .cancel) {}
    }
  }
}
