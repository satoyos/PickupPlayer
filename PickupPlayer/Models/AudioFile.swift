//
//  AudioFile.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import UIKit

struct AudioFile: Identifiable, Codable, Equatable {
  let id: UUID
  let fileName: String // 相対パス（ファイル名のみ）
  let title: String
  let duration: TimeInterval
  var lastPlaybackPosition: TimeInterval
  var artworkPath: String? // アートワークファイルのパス（相対パス）

  // URLを動的に生成する計算プロパティ
  var url: URL {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      fatalError("Documentsディレクトリが見つかりません")
    }
    return documentsDirectory.appendingPathComponent(fileName)
  }

  // アートワークデータを取得する計算プロパティ
  var artworkData: Data? {
    get {
      guard let path = artworkPath else { return nil }
      return ArtworkManager.shared.loadArtwork(from: path)
    }
  }

  init(id: UUID = UUID(), url: URL, title: String, duration: TimeInterval, lastPlaybackPosition: TimeInterval = 0, artworkData: Data? = nil) {
    self.id = id
    self.fileName = url.lastPathComponent // ファイル名のみを保存
    self.title = title
    self.duration = duration
    self.lastPlaybackPosition = lastPlaybackPosition

    // アートワークを保存してパスを設定
    if let data = artworkData {
      self.artworkPath = ArtworkManager.shared.saveArtwork(data, for: id)
    } else {
      self.artworkPath = nil
    }
  }

  // Codable対応のためのカスタムエンコード/デコード
  enum CodingKeys: String, CodingKey {
    case id
    case fileName // urlの代わりにfileNameを使用
    case title
    case duration
    case lastPlaybackPosition
    case artworkPath
    // 旧バージョンとの互換性のため
    case url
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)

    // 新形式: fileNameを読み込む
    if let fileName = try? container.decode(String.self, forKey: .fileName) {
      self.fileName = fileName
      print("📁 新形式でファイル名読み込み: \(fileName)")
    }
    // 旧形式: 絶対パスのURLから移行
    else if let oldURL = try? container.decode(URL.self, forKey: .url) {
      self.fileName = oldURL.lastPathComponent
      print("🔄 旧形式から移行: \(oldURL.path) → \(self.fileName)")
    }
    // どちらもない場合はエラー
    else {
      throw DecodingError.dataCorruptedError(
        forKey: .fileName,
        in: container,
        debugDescription: "fileNameまたはurlが必要です"
      )
    }

    title = try container.decode(String.self, forKey: .title)
    duration = try container.decode(TimeInterval.self, forKey: .duration)
    lastPlaybackPosition = try container.decode(TimeInterval.self, forKey: .lastPlaybackPosition)
    artworkPath = try container.decodeIfPresent(String.self, forKey: .artworkPath)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(fileName, forKey: .fileName) // ファイル名のみを保存
    try container.encode(title, forKey: .title)
    try container.encode(duration, forKey: .duration)
    try container.encode(lastPlaybackPosition, forKey: .lastPlaybackPosition)
    try container.encodeIfPresent(artworkPath, forKey: .artworkPath)
  }
}
