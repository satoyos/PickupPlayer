//
//  DocumentPickerView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct DocumentPickerView: UIViewControllerRepresentable {
  @ObservedObject var playlist: Playlist
  @Environment(\.dismiss) var dismiss

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [.audio, .mpeg4Audio, .mp3, .mpeg4Movie],
      asCopy: true
    )
    picker.delegate = context.coordinator
    picker.allowsMultipleSelection = true
    return picker
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    let parent: DocumentPickerView

    init(_ parent: DocumentPickerView) {
      self.parent = parent
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      print("📂 ファイルピッカーで\(urls.count)個のファイルが選択されました")
      for url in urls {
        print("📂 処理中: \(url.lastPathComponent)")

        // asCopy: true の場合、ファイルは既にアプリがアクセス可能な場所にコピーされているため
        // セキュリティスコープのアクセスは不要（失敗する場合がある）
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        if needsSecurityScope {
          print("🔓 セキュリティスコープアクセス取得")
        } else {
          print("ℹ️ セキュリティスコープアクセス不要（既にコピー済み）")
        }

        defer {
          if needsSecurityScope {
            url.stopAccessingSecurityScopedResource()
          }
        }

        // ファイルをアプリのドキュメントディレクトリにコピー
        if let copiedURL = copyFileToDocuments(url) {
          print("✅ コピー成功: \(copiedURL.path)")
          addAudioFile(from: copiedURL)
        } else {
          print("❌ コピー失敗: \(url.lastPathComponent)")
        }
      }
      parent.dismiss()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      parent.dismiss()
    }

    private func copyFileToDocuments(_ url: URL) -> URL? {
      print("💾 copyFileToDocuments開始: \(url.lastPathComponent)")
      let fileManager = FileManager.default
      guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("❌ Documentsディレクトリの取得に失敗")
        return nil
      }

      let fileName = url.lastPathComponent
      let destinationURL = documentsDirectory.appendingPathComponent(fileName)
      print("💾 コピー先: \(destinationURL.path)")

      // すでに同じ名前のファイルが存在する場合は削除
      if fileManager.fileExists(atPath: destinationURL.path) {
        print("🗑️ 既存ファイルを削除: \(fileName)")
        try? fileManager.removeItem(at: destinationURL)
      }

      do {
        print("💾 コピー実行中...")
        try fileManager.copyItem(at: url, to: destinationURL)
        print("✅ コピー成功")
        return destinationURL
      } catch {
        print("❌ ファイルのコピーに失敗しました: \(error)")
        print("❌ エラー詳細: \(error.localizedDescription)")
        return nil
      }
    }

    private func addAudioFile(from url: URL) {
      Task {
        print("📁 addAudioFile開始: \(url.path)")
        print("📁 ファイル存在確認: \(FileManager.default.fileExists(atPath: url.path))")

        let asset = AVURLAsset(url: url)
        let duration: TimeInterval
        do {
          duration = try await asset.load(.duration).seconds
          print("✅ デュレーション読み込み成功: \(duration)秒")
        } catch {
          print("❌ デュレーションの読み込みに失敗しました: \(error)")
          print("❌ エラー詳細: \(error.localizedDescription)")
          duration = 0
        }

        // アートワークを抽出
        print("🎨 アートワーク抽出開始")
        let artworkData = await ArtworkExtractor.extractArtwork(from: url)
        if let data = artworkData {
          print("✅ アートワーク抽出成功: \(data.count) bytes")
        } else {
          print("⚠️ アートワークなし")
        }

        await MainActor.run {
          let audioFile = AudioFile(
            url: url,
            title: url.deletingPathExtension().lastPathComponent,
            duration: duration,
            lastPlaybackPosition: 0,
            artworkData: artworkData
          )
          print("➕ プレイリストに追加: \(audioFile.title)")
          parent.playlist.addItem(audioFile)
          print("✅ プレイリスト追加完了。現在のアイテム数: \(parent.playlist.items.count)")
        }
      }
    }
  }
}
