//
//  PlayerView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import SwiftUI

struct PlayerView: View {
  @StateObject private var viewModel: PlayerViewModel

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
  }
}
