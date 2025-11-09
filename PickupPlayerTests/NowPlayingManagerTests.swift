//
//  NowPlayingManagerTests.swift
//  PickupPlayerTests
//
//  Created by Yoshifumi Sato on 2025/11/09.
//

import XCTest
import MediaPlayer
@testable import PickupPlayer

final class NowPlayingManagerTests: XCTestCase {

  var nowPlayingManager: NowPlayingManager!

  override func setUp() {
    super.setUp()
    nowPlayingManager = NowPlayingManager.shared
  }

  override func tearDown() {
    // テスト後にNow Playing情報をクリア
    nowPlayingManager.clearNowPlayingInfo()
    nowPlayingManager = nil
    super.tearDown()
  }

  // MARK: - アートワークなしのテスト

  func testUpdateNowPlayingInfo_withoutArtwork() {
    // Arrange
    let title = "Test Track"
    let duration: TimeInterval = 120
    let currentTime: TimeInterval = 30
    let isPlaying = true

    // Act
    nowPlayingManager.updateNowPlayingInfo(
      title: title,
      duration: duration,
      currentTime: currentTime,
      isPlaying: isPlaying,
      artwork: nil
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNotNil(nowPlayingInfo, "Now Playing情報が設定されているべき")
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyTitle] as? String, title, "タイトルが正しく設定されているべき")
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] as? TimeInterval, duration, "再生時間が正しく設定されているべき")
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval, currentTime, "現在時刻が正しく設定されているべき")
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 1.0, "再生レートが1.0であるべき")
    XCTAssertNil(nowPlayingInfo?[MPMediaItemPropertyArtwork], "アートワークが設定されていないべき")
  }

  // MARK: - アートワーク付きのテスト

  func testUpdateNowPlayingInfo_withArtwork() {
    // Arrange
    let title = "Test Track with Artwork"
    let duration: TimeInterval = 180
    let currentTime: TimeInterval = 45
    let isPlaying = false
    let testImage = AudioFileTestFixture.makeTestImage(size: CGSize(width: 200, height: 200))

    // Act
    nowPlayingManager.updateNowPlayingInfo(
      title: title,
      duration: duration,
      currentTime: currentTime,
      isPlaying: isPlaying,
      artwork: testImage
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNotNil(nowPlayingInfo, "Now Playing情報が設定されているべき")
    XCTAssertNotNil(nowPlayingInfo?[MPMediaItemPropertyArtwork], "アートワークが設定されているべき")

    if let artwork = nowPlayingInfo?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
      let artworkImage = artwork.image(at: CGSize(width: 200, height: 200))
      XCTAssertNotNil(artworkImage, "アートワーク画像が取得できるべき")
    } else {
      XCTFail("MPMediaItemArtworkにキャストできませんでした")
    }
  }

  // MARK: - アートワークサイズのテスト

  func testUpdateNowPlayingInfo_artworkSizeMatches() {
    // Arrange
    let testSize = CGSize(width: 300, height: 300)
    let testImage = AudioFileTestFixture.makeTestImage(size: testSize)

    // Act
    nowPlayingManager.updateNowPlayingInfo(
      title: "Size Test",
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: testImage
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    if let artwork = nowPlayingInfo?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
      let retrievedImage = artwork.image(at: testSize)
      XCTAssertNotNil(retrievedImage, "指定サイズでアートワーク画像が取得できるべき")
      XCTAssertEqual(retrievedImage?.size, testSize, "画像サイズが一致するべき")
    } else {
      XCTFail("MPMediaItemArtworkが設定されていませんでした")
    }
  }

  // MARK: - Now Playing情報のクリア

  func testClearNowPlayingInfo_removesArtwork() {
    // Arrange: まずアートワーク付きで情報を設定
    let testImage = AudioFileTestFixture.makeTestImage()
    nowPlayingManager.updateNowPlayingInfo(
      title: "Clear Test",
      duration: 100,
      currentTime: 0,
      isPlaying: true,
      artwork: testImage
    )

    // アートワークが設定されていることを確認
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNotNil(nowPlayingInfo?[MPMediaItemPropertyArtwork], "アートワークが設定されているべき")

    // Act: Now Playing情報をクリア
    nowPlayingManager.clearNowPlayingInfo()

    // Assert
    nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNil(nowPlayingInfo, "Now Playing情報がクリアされているべき")
  }

  // MARK: - 再生レートのテスト

  func testUpdateNowPlayingInfo_playbackRateWhenPlaying() {
    // Arrange
    let isPlaying = true

    // Act
    nowPlayingManager.updateNowPlayingInfo(
      title: "Playing Test",
      duration: 100,
      currentTime: 50,
      isPlaying: isPlaying,
      artwork: nil
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 1.0, "再生中は再生レートが1.0であるべき")
  }

  func testUpdateNowPlayingInfo_playbackRateWhenPaused() {
    // Arrange
    let isPlaying = false

    // Act
    nowPlayingManager.updateNowPlayingInfo(
      title: "Paused Test",
      duration: 100,
      currentTime: 50,
      isPlaying: isPlaying,
      artwork: nil
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 0.0, "一時停止中は再生レートが0.0であるべき")
  }

  // MARK: - スリープタイマー情報のテスト

  func testUpdateNowPlayingInfo_withSleepTimerRemaining() {
    // Arrange
    let title = "Sleep Timer Test"
    let sleepTimerRemaining: TimeInterval = 300 // 5分

    // Act
    nowPlayingManager.updateNowPlayingInfo(
      title: title,
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: nil,
      sleepTimerRemaining: sleepTimerRemaining
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNotNil(nowPlayingInfo, "Now Playing情報が設定されているべき")
    let artist = nowPlayingInfo?[MPMediaItemPropertyArtist] as? String
    XCTAssertNotNil(artist, "アーティスト情報にタイマー情報が設定されているべき")
    XCTAssertTrue(artist?.contains("🌙") == true, "タイマー情報に月アイコンが含まれているべき")
    XCTAssertEqual(artist, "🌙 05:00", "タイマー情報が正しくフォーマットされているべき")
  }

  func testUpdateNowPlayingInfo_withSleepTimerRemaining_variousTimes() {
    // Test Case 1: 10分30秒
    nowPlayingManager.updateNowPlayingInfo(
      title: "Test",
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: nil,
      sleepTimerRemaining: 630
    )
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyArtist] as? String, "🌙 10:30", "10分30秒が正しくフォーマットされるべき")

    // Test Case 2: 1秒
    nowPlayingManager.updateNowPlayingInfo(
      title: "Test",
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: nil,
      sleepTimerRemaining: 1
    )
    nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyArtist] as? String, "🌙 00:01", "1秒が正しくフォーマットされるべき")

    // Test Case 3: 59秒
    nowPlayingManager.updateNowPlayingInfo(
      title: "Test",
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: nil,
      sleepTimerRemaining: 59
    )
    nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyArtist] as? String, "🌙 00:59", "59秒が正しくフォーマットされるべき")
  }

  func testUpdateNowPlayingInfo_withoutSleepTimerRemaining() {
    // Arrange
    let title = "No Timer Test"

    // Act: タイマー情報なし
    nowPlayingManager.updateNowPlayingInfo(
      title: title,
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: nil,
      sleepTimerRemaining: nil
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNil(nowPlayingInfo?[MPMediaItemPropertyArtist], "タイマー情報なしの場合、アーティスト情報は設定されないべき")
  }

  func testUpdateNowPlayingInfo_withZeroSleepTimerRemaining() {
    // Arrange
    let title = "Zero Timer Test"

    // Act: 残り時間が0
    nowPlayingManager.updateNowPlayingInfo(
      title: title,
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: nil,
      sleepTimerRemaining: 0
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNil(nowPlayingInfo?[MPMediaItemPropertyArtist], "残り時間が0の場合、アーティスト情報は設定されないべき")
  }

  func testUpdateNowPlayingInfo_sleepTimerWithArtwork() {
    // Arrange
    let testImage = AudioFileTestFixture.makeTestImage()
    let sleepTimerRemaining: TimeInterval = 180 // 3分

    // Act: タイマー情報とアートワークの両方を設定
    nowPlayingManager.updateNowPlayingInfo(
      title: "Timer with Artwork",
      duration: 100,
      currentTime: 50,
      isPlaying: true,
      artwork: testImage,
      sleepTimerRemaining: sleepTimerRemaining
    )

    // Assert
    let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertNotNil(nowPlayingInfo?[MPMediaItemPropertyArtwork], "アートワークが設定されているべき")
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyArtist] as? String, "🌙 03:00", "タイマー情報が正しく設定されているべき")
  }
}
