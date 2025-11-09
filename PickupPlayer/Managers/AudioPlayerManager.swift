//
//  AudioPlayerManager.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import AVFoundation
import Combine
import UIKit

class AudioPlayerManager: NSObject, ObservableObject {
  @Published var isPlaying = false
  @Published var currentTime: TimeInterval = 0
  @Published var duration: TimeInterval = 0
  @Published var currentAudioFile: AudioFile?

  private var audioPlayer: AVAudioPlayer?
  private var timer: Timer?
  private let playbackStateManager = PlaybackStateManager.shared
  private let nowPlayingManager = NowPlayingManager.shared
  private var cachedArtworkImage: UIImage?

  override init() {
    super.init()
    setupAudioSession()
    setupRemoteCommandObservers()
  }

  private func setupAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default)
      try audioSession.setActive(true)
    } catch {
      print("オーディオセッションの設定に失敗しました: \(error)")
    }
  }

  func loadAudio(_ audioFile: AudioFile) {
    print("🎵 オーディオファイル読み込み開始: \(audioFile.title)")
    print("🎵 ファイルパス: \(audioFile.url.path)")
    print("🎵 ファイル存在確認: \(FileManager.default.fileExists(atPath: audioFile.url.path))")

    // ファイルの存在を確認
    guard FileManager.default.fileExists(atPath: audioFile.url.path) else {
      print("❌ ファイルが存在しません: \(audioFile.url.path)")
      print("❌ このファイルは削除または移動された可能性があります")
      // エラー状態をクリア
      audioPlayer = nil
      currentAudioFile = nil
      cachedArtworkImage = nil
      duration = 0
      currentTime = 0
      isPlaying = false
      nowPlayingManager.clearNowPlayingInfo()
      return
    }

    do {
      audioPlayer = try AVAudioPlayer(contentsOf: audioFile.url)
      audioPlayer?.delegate = self
      audioPlayer?.prepareToPlay()

      currentAudioFile = audioFile
      duration = audioPlayer?.duration ?? 0
      print("✅ オーディオファイル読み込み成功: \(duration)秒")

      // アートワーク画像をキャッシュ
      if let artworkData = audioFile.artworkData {
        cachedArtworkImage = UIImage(data: artworkData)
      } else {
        cachedArtworkImage = nil
      }

      // 保存された再生位置を読み込む
      let savedPosition = playbackStateManager.loadPlaybackPosition(for: audioFile.id)
      if savedPosition > 0 && savedPosition < duration {
        audioPlayer?.currentTime = savedPosition
        currentTime = savedPosition
        print("📍 再生位置を復元: \(savedPosition)秒")
      } else {
        currentTime = 0
      }
    } catch {
      print("❌ オーディオファイルの読み込みに失敗しました: \(error)")
      print("❌ エラー詳細: \(error.localizedDescription)")
      // エラー状態をクリア
      audioPlayer = nil
      currentAudioFile = nil
      cachedArtworkImage = nil
      duration = 0
      currentTime = 0
      isPlaying = false
      nowPlayingManager.clearNowPlayingInfo()
    }
  }

  func play() {
    guard let player = audioPlayer else {
      print("⚠️ 再生失敗: オーディオプレーヤーが初期化されていません")
      isPlaying = false
      // Now Playing情報をクリア
      nowPlayingManager.clearNowPlayingInfo()
      return
    }

    player.play()
    isPlaying = true
    startTimer()
    updateNowPlaying()
  }

  func pause() {
    audioPlayer?.pause()
    isPlaying = false
    stopTimer()
    saveCurrentPosition()
    updateNowPlaying()
  }

  func togglePlayPause() {
    if isPlaying {
      pause()
    } else {
      play()
    }
  }

  func seek(to time: TimeInterval) {
    audioPlayer?.currentTime = time
    currentTime = time
    saveCurrentPosition()
  }

  func skipForward(seconds: TimeInterval = 30) {
    let newTime = min(currentTime + seconds, duration)
    seek(to: newTime)
  }

  func skipBackward(seconds: TimeInterval = 30) {
    let newTime = max(currentTime - seconds, 0)
    seek(to: newTime)
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self, let player = self.audioPlayer else { return }
      self.currentTime = player.currentTime
      self.saveCurrentPosition()
      self.updateNowPlaying()
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func saveCurrentPosition() {
    guard let audioFile = currentAudioFile else { return }
    playbackStateManager.savePlaybackPosition(for: audioFile.id, position: currentTime)
  }

  private func updateNowPlaying() {
    guard let audioFile = currentAudioFile else { return }
    nowPlayingManager.updateNowPlayingInfo(
      title: audioFile.title,
      duration: duration,
      currentTime: currentTime,
      isPlaying: isPlaying,
      artwork: cachedArtworkImage
    )
  }

  private func setupRemoteCommandObservers() {
    NotificationCenter.default.addObserver(
      forName: .remotePlay,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.play()
    }

    NotificationCenter.default.addObserver(
      forName: .remotePause,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.pause()
    }

    NotificationCenter.default.addObserver(
      forName: .remoteTogglePlayPause,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.togglePlayPause()
    }

    NotificationCenter.default.addObserver(
      forName: .remoteSkipForward,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.skipForward(seconds: 30)
    }

    NotificationCenter.default.addObserver(
      forName: .remoteSkipBackward,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.skipBackward(seconds: 30)
    }
  }

  deinit {
    stopTimer()
    NotificationCenter.default.removeObserver(self)
  }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    isPlaying = false
    stopTimer()
    currentTime = 0
    saveCurrentPosition()
    updateNowPlaying()
  }
}
