//
//  ArtworkExtractor.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import Foundation
import AVFoundation
import UIKit

struct ArtworkExtractor {
  /// オーディオファイルからアートワーク画像データを抽出
  /// - Parameter url: オーディオファイルのURL
  /// - Returns: アートワーク画像データ（PNG形式）、存在しない場合はnil
  static func extractArtwork(from url: URL) async -> Data? {
    let asset = AVURLAsset(url: url)

    do {
      // メタデータを読み込む
      let metadata = try await asset.load(.commonMetadata)

      // アートワークを検索
      for item in metadata {
        // キーがartworkの項目を探す
        guard let key = item.commonKey,
              key == .commonKeyArtwork else {
          continue
        }

        // データを取得
        if let data = try? await item.load(.value) as? Data {
          return data
        }

        // UIImageとして取得できる場合
        if let image = try? await item.load(.value) as? UIImage,
           let pngData = image.pngData() {
          return pngData
        }
      }

      // AVMetadataKeySpace.iTunesのアートワークも確認
      let iTunesMetadata = try await asset.load(.metadata)
      for item in iTunesMetadata {
        guard let keySpace = item.keySpace,
              keySpace == .iTunes,
              let key = item.key as? String,
              key == "covr" else {
          continue
        }

        if let data = try? await item.load(.value) as? Data {
          return data
        }
      }

      return nil
    } catch {
      print("アートワークの抽出に失敗しました: \(error)")
      return nil
    }
  }

  /// Data から UIImage を生成
  /// - Parameter data: 画像データ
  /// - Returns: UIImage、生成できない場合はnil
  static func imageFromData(_ data: Data) -> UIImage? {
    return UIImage(data: data)
  }
}
