//
//  MusicPickerViewModel.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/07.
//

import Foundation
import MediaPlayer
import AVFoundation
import Combine
import UIKit

class MusicPickerViewModel: ObservableObject {
  @Published var exportTasks: [ExportTask] = []
  @Published var errorMessage: String?

  private let playlist: Playlist
  private var exportSessions: [UUID: AVAssetExportSession] = [:]
  private var progressTimers: [UUID: Timer] = [:]

  var isExporting: Bool {
    exportTasks.contains { $0.status == .exporting }
  }

  init(playlist: Playlist) {
    self.playlist = playlist
  }

  deinit {
    // タイマーをすべて停止
    progressTimers.values.forEach { $0.invalidate() }
  }

  // MARK: - Public Methods

  func handleSelectedMediaItems(_ mediaItemCollection: MPMediaItemCollection) {
    for item in mediaItemCollection.items {
      if let url = item.assetURL {
        let title = item.title ?? "不明な曲"
        let duration = item.playbackDuration

        // MPMediaItemから直接アートワークを取得
        let artworkData = extractArtworkFromMediaItem(item)

        // タスクを作成
        let task = ExportTask(fileName: title, status: .waiting)
        Task { @MainActor in
          exportTasks.append(task)
        }

        // ミュージックファイルをアプリ内にエクスポート
        Task {
          await exportAndAddToPlaylist(url: url, title: title, duration: duration, artworkData: artworkData, taskId: task.id)
        }
      }
    }
  }

  // MARK: - Private Methods

  private func extractArtworkFromMediaItem(_ item: MPMediaItem) -> Data? {
    guard let artwork = item.artwork else {
      return nil
    }

    // アートワーク画像を取得（適切なサイズで）
    let image = artwork.image(at: CGSize(width: 600, height: 600))
    return image?.jpegData(compressionQuality: 0.8)
  }

  private func exportAndAddToPlaylist(url: URL, title: String, duration: TimeInterval, artworkData: Data?, taskId: UUID) async {
    guard let exportedURL = await exportMusicFile(from: url, title: title, taskId: taskId) else {
      await MainActor.run {
        errorMessage = "ファイルのエクスポートに失敗しました: \(title)"
        updateTaskStatus(taskId: taskId, status: .failed("エクスポートに失敗しました"))
      }
      print("ファイルのエクスポートに失敗しました: \(title)")
      return
    }

    await MainActor.run {
      let audioFile = AudioFile(
        url: exportedURL,
        title: title,
        duration: duration,
        lastPlaybackPosition: 0,
        artworkData: artworkData
      )
      playlist.addItem(audioFile)
      updateTaskStatus(taskId: taskId, status: .completed)

      // 完了後、少し待ってからタスクをリストから削除
      Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        await MainActor.run {
          exportTasks.removeAll { $0.id == taskId }
        }
      }
    }
  }

  private func exportMusicFile(from url: URL, title: String, taskId: UUID) async -> URL? {
    let asset = AVURLAsset(url: url)

    // エクスポート可能なプリセットを取得
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      print("エクスポートセッションの作成に失敗しました")
      return nil
    }

    // ファイル名を安全な形式に変換（特殊文字を除去）
    let safeFileName = title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    let fileName = safeFileName.isEmpty ? "audio_file" : safeFileName

    // エクスポート先のURLを作成
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      print("ドキュメントディレクトリの取得に失敗しました")
      return nil
    }

    let outputURL = documentsDirectory.appendingPathComponent("\(fileName).m4a")

    // 既存ファイルがあれば削除
    if FileManager.default.fileExists(atPath: outputURL.path) {
      try? FileManager.default.removeItem(at: outputURL)
    }

    // エクスポートセッションを保存
    await MainActor.run {
      exportSessions[taskId] = exportSession
      updateTaskStatus(taskId: taskId, status: .exporting)
    }

    // 進捗監視タイマーを開始
    startProgressMonitoring(for: taskId, exportSession: exportSession)

    // エクスポートを実行（iOS 18の新しいAPI使用）
    do {
      try await exportSession.export(to: outputURL, as: .m4a)

      // タイマーを停止
      await MainActor.run {
        stopProgressMonitoring(for: taskId)
        exportSessions.removeValue(forKey: taskId)
      }

      print("エクスポート成功: \(outputURL.path)")
      return outputURL
    } catch {
      // タイマーを停止
      await MainActor.run {
        stopProgressMonitoring(for: taskId)
        exportSessions.removeValue(forKey: taskId)
      }

      print("エクスポート失敗: \(error.localizedDescription)")
      return nil
    }
  }

  // MARK: - Progress Monitoring

  private func startProgressMonitoring(for taskId: UUID, exportSession: AVAssetExportSession) {
    Task { @MainActor in
      let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        // エクスポートセッションを辞書から取得
        guard let session = self.exportSessions[taskId] else { return }
        let progress = Double(session.progress)
        self.updateTaskProgress(taskId: taskId, progress: progress)
      }
      RunLoop.main.add(timer, forMode: .common)
      progressTimers[taskId] = timer
    }
  }

  private func stopProgressMonitoring(for taskId: UUID) {
    progressTimers[taskId]?.invalidate()
    progressTimers.removeValue(forKey: taskId)
  }

  private func updateTaskProgress(taskId: UUID, progress: Double) {
    if let index = exportTasks.firstIndex(where: { $0.id == taskId }) {
      exportTasks[index].progress = progress
    }
  }

  private func updateTaskStatus(taskId: UUID, status: ExportTask.Status) {
    if let index = exportTasks.firstIndex(where: { $0.id == taskId }) {
      exportTasks[index].status = status
    }
  }
}
