//
//  ArtworkManager.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/08.
//

import Foundation
import UIKit

class ArtworkManager {
  static let shared = ArtworkManager()

  private let artworksDirectory: URL
  private var cache: [String: Data] = [:]  // キャッシュ

  private init() {
    // Artworksディレクトリを作成
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    artworksDirectory = documentsDirectory.appendingPathComponent("Artworks")

    // ディレクトリが存在しない場合は作成
    if !FileManager.default.fileExists(atPath: artworksDirectory.path) {
      try? FileManager.default.createDirectory(at: artworksDirectory, withIntermediateDirectories: true)
    }
  }

  // MARK: - Public Methods

  /// アートワークを保存
  /// - Parameters:
  ///   - data: アートワーク画像データ
  ///   - id: AudioFileのID
  /// - Returns: 保存されたファイルのパス（相対パス）
  func saveArtwork(_ data: Data, for id: UUID) -> String? {
    let fileName = "\(id.uuidString).jpg"
    let fileURL = artworksDirectory.appendingPathComponent(fileName)

    do {
      try data.write(to: fileURL)
      print("💾 アートワーク保存成功: \(fileName)")
      return fileName
    } catch {
      print("❌ アートワーク保存失敗: \(error)")
      return nil
    }
  }

  /// アートワークを読み込み
  /// - Parameter path: ファイルパス（相対パス）
  /// - Returns: アートワーク画像データ
  func loadArtwork(from path: String) -> Data? {
    // キャッシュをチェック
    if let cachedData = cache[path] {
      // print("💨 アートワークキャッシュヒット: \(path)")
      return cachedData
    }

    let fileURL = artworksDirectory.appendingPathComponent(path)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("⚠️ アートワークファイルが存在しません: \(path)")
      return nil
    }

    do {
      let data = try Data(contentsOf: fileURL)
      print("📂 アートワーク読み込み成功: \(path) (\(data.count) bytes)")
      // キャッシュに保存
      cache[path] = data
      return data
    } catch {
      print("❌ アートワーク読み込み失敗: \(error)")
      return nil
    }
  }

  /// アートワークを削除
  /// - Parameter path: ファイルパス（相対パス）
  func deleteArtwork(at path: String) {
    // キャッシュから削除
    cache.removeValue(forKey: path)

    let fileURL = artworksDirectory.appendingPathComponent(path)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }

    do {
      try FileManager.default.removeItem(at: fileURL)
      print("🗑️ アートワーク削除成功: \(path)")
    } catch {
      print("❌ アートワーク削除失敗: \(error)")
    }
  }

  /// すべてのアートワークを削除（デバッグ用）
  func deleteAllArtworks() {
    // キャッシュをクリア
    cache.removeAll()

    do {
      let files = try FileManager.default.contentsOfDirectory(at: artworksDirectory, includingPropertiesForKeys: nil)
      for file in files {
        try FileManager.default.removeItem(at: file)
      }
      print("🗑️ すべてのアートワークを削除しました")
    } catch {
      print("❌ アートワーク削除失敗: \(error)")
    }
  }
}
