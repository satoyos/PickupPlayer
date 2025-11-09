//
//  PlayerViewModelTests.swift
//  AudioFilePlayerTests
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import XCTest
import Combine
@testable import PickupPlayer

final class PlayerViewModelTests: XCTestCase {

  var viewModel: PlayerViewModel!
  var mockAudioPlayerManager: AudioPlayerManager!
  var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()
    mockAudioPlayerManager = AudioPlayerManager()
    viewModel = PlayerViewModel(audioPlayerManager: mockAudioPlayerManager)
    cancellables = []
  }

  override func tearDown() {
    viewModel = nil
    mockAudioPlayerManager = nil
    cancellables = nil
    super.tearDown()
  }

  func testViewModel_initialState() {
    // Assert
    XCTAssertFalse(viewModel.isDraggingSlider, "初期状態ではスライダーをドラッグしていないべき")
    XCTAssertEqual(viewModel.sliderValue, 0, "初期状態でのスライダー値は0であるべき")
    XCTAssertNil(viewModel.currentAudioFile, "初期状態ではオーディオファイルは設定されていないべき")
  }

  func testViewModel_currentTimeFormatted() {
    // Arrange
    mockAudioPlayerManager.currentTime = 125

    // Act
    let formatted = viewModel.currentTimeFormatted

    // Assert
    XCTAssertEqual(formatted, "2:05", "現在時刻が正しくフォーマットされるべき")
  }

  func testViewModel_durationFormatted() {
    // Arrange
    mockAudioPlayerManager.duration = 3665

    // Act
    let formatted = viewModel.durationFormatted

    // Assert
    XCTAssertEqual(formatted, "1:01:05", "デュレーションが正しくフォーマットされるべき")
  }

  func testViewModel_sliderEditingChanged_startDragging() {
    // Act
    viewModel.sliderEditingChanged(true)

    // Assert
    XCTAssertTrue(viewModel.isDraggingSlider, "ドラッグ開始時にisDraggingSliderがtrueになるべき")
  }

  func testViewModel_sliderEditingChanged_endDragging() {
    // Arrange
    viewModel.sliderValue = 60.0
    viewModel.isDraggingSlider = true

    // Act
    viewModel.sliderEditingChanged(false)

    // Assert
    XCTAssertFalse(viewModel.isDraggingSlider, "ドラッグ終了時にisDraggingSliderがfalseになるべき")
    // Note: seek()の呼び出しを確認するにはモックが必要
  }

  func testViewModel_sliderValue_updatesWhenNotDragging() {
    // Arrange
    let expectation = XCTestExpectation(description: "スライダー値が更新される")

    viewModel.$sliderValue
      .dropFirst() // 初期値をスキップ
      .sink { value in
        if value == 50.0 {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act
    mockAudioPlayerManager.currentTime = 50.0

    // Assert
    wait(for: [expectation], timeout: 1.0)
  }

  func testViewModel_sliderValue_doesNotUpdateWhenDragging() {
    // Arrange
    viewModel.isDraggingSlider = true
    viewModel.sliderValue = 30.0

    // Act
    mockAudioPlayerManager.currentTime = 50.0

    // Assert
    // ドラッグ中はスライダー値は更新されないべき
    XCTAssertEqual(viewModel.sliderValue, 30.0, "ドラッグ中はスライダー値が更新されないべき")
  }

  // MARK: - コメントアウト: AudioPlayerManagerが実際のオーディオファイルを必要とするため
  // このテストは統合テストで実施する必要があります。
  // モック化するには、AudioPlayerManagerのプロトコル化と依存性注入が必要です。
  /*
  func testViewModel_togglePlayPause() {
    // Arrange
    let initialIsPlaying = mockAudioPlayerManager.isPlaying

    // Act
    viewModel.togglePlayPause()

    // Assert
    XCTAssertNotEqual(mockAudioPlayerManager.isPlaying, initialIsPlaying, "再生状態がトグルされるべき")
  }
  */

  func testViewModel_skipForward() {
    // Arrange
    mockAudioPlayerManager.currentTime = 30.0
    mockAudioPlayerManager.duration = 300.0

    // Act
    viewModel.skipForward()

    // Assert
    XCTAssertEqual(mockAudioPlayerManager.currentTime, 60.0, "30秒スキップされるべき")
  }

  func testViewModel_skipBackward() {
    // Arrange
    mockAudioPlayerManager.currentTime = 60.0
    mockAudioPlayerManager.duration = 300.0

    // Act
    viewModel.skipBackward()

    // Assert
    XCTAssertEqual(mockAudioPlayerManager.currentTime, 30.0, "30秒戻るべき")
  }

  func testViewModel_skipBackward_doesNotGoNegative() {
    // Arrange
    mockAudioPlayerManager.currentTime = 15.0
    mockAudioPlayerManager.duration = 300.0

    // Act
    viewModel.skipBackward()

    // Assert
    XCTAssertEqual(mockAudioPlayerManager.currentTime, 0.0, "0秒未満にはならないべき")
  }

  // MARK: - isPlaying同期のテスト

  func testViewModel_isPlaying_initializesToFalse() {
    // Assert
    XCTAssertFalse(viewModel.isPlaying, "初期状態ではisPlayingがfalseであるべき")
  }

  func testViewModel_isPlaying_synchronizesWithManager() {
    // Arrange
    let expectation = XCTestExpectation(description: "isPlayingがAudioPlayerManagerと同期する")

    viewModel.$isPlaying
      .dropFirst() // 初期値をスキップ
      .sink { value in
        if value == true {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act: AudioPlayerManagerのisPlayingを変更
    mockAudioPlayerManager.isPlaying = true

    // Assert
    wait(for: [expectation], timeout: 1.0)
    XCTAssertTrue(viewModel.isPlaying, "ViewModelのisPlayingがManagerと同期しているべき")
  }

  func testViewModel_isPlaying_synchronizesFromTrueToFalse() {
    // Arrange
    mockAudioPlayerManager.isPlaying = true
    let expectation = XCTestExpectation(description: "isPlayingがtrueからfalseに同期する")

    viewModel.$isPlaying
      .dropFirst() // 現在のtrueをスキップ
      .sink { value in
        if value == false {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act: AudioPlayerManagerのisPlayingをfalseに変更
    mockAudioPlayerManager.isPlaying = false

    // Assert
    wait(for: [expectation], timeout: 1.0)
    XCTAssertFalse(viewModel.isPlaying, "ViewModelのisPlayingがfalseに同期しているべき")
  }

  func testViewModel_isPlaying_publisherEmitsCorrectValues() {
    // Arrange
    var receivedValues: [Bool] = []
    let expectation = XCTestExpectation(description: "isPlayingのPublisherが正しい値を発行する")
    expectation.expectedFulfillmentCount = 3 // 初期値 + 2回の変更

    viewModel.$isPlaying
      .sink { value in
        receivedValues.append(value)
        if receivedValues.count == 3 {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act: 複数回の状態変更
    mockAudioPlayerManager.isPlaying = true
    mockAudioPlayerManager.isPlaying = false

    // Assert
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(receivedValues, [false, true, false], "Publisherが正しい順序で値を発行するべき")
  }
}
