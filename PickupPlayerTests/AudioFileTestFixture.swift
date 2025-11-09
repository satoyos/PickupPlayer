//
//  AudioFileTestFixture.swift
//  PickupPlayerTests
//
//  Created by Yoshifumi Sato on 2025/11/09.
//

import Foundation
import UIKit
@testable import PickupPlayer

/// テスト用のAudioFileオブジェクトを簡単に作成するためのヘルパー
struct AudioFileTestFixture {

  /// テスト用のAudioFileを作成
  /// - Parameters:
  ///   - title: ファイルのタイトル
  ///   - duration: 再生時間（秒）
  ///   - withArtwork: アートワーク画像を含めるかどうか
  /// - Returns: テスト用のAudioFileオブジェクト
  static func makeAudioFile(
    title: String = "Test Audio",
    duration: TimeInterval = 120,
    withArtwork: Bool = false
  ) -> AudioFile {
    let artworkData: Data? = withArtwork ? makeTestImageData() : nil

    // テスト用のダミーURLを作成（実際のファイルは存在しない）
    let testURL = URL(fileURLWithPath: "/tmp/\(title).mp3")

    return AudioFile(
      id: UUID(),
      url: testURL,
      title: title,
      duration: duration,
      lastPlaybackPosition: 0,
      artworkData: artworkData
    )
  }

  /// テスト用の画像データを作成
  /// - Returns: JPEGフォーマットの画像データ
  static func makeTestImageData(size: CGSize = CGSize(width: 100, height: 100)) -> Data {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
      UIColor.blue.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
    return image.jpegData(compressionQuality: 0.8)!
  }

  /// テスト用のUIImageを作成
  /// - Parameter size: 画像のサイズ
  /// - Returns: テスト用のUIImage
  static func makeTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      UIColor.blue.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }
}
