//
//  SleepTimerManagerTests.swift
//  PickupPlayerTests
//
//  Created by Yoshifumi Sato on 2025/11/09.
//

import XCTest
import Combine
@testable import PickupPlayer

final class SleepTimerManagerTests: XCTestCase {

  var sleepTimerManager: SleepTimerManager!
  var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()
    sleepTimerManager = SleepTimerManager.shared
    cancellables = []
    // 各テスト開始時にタイマーをキャンセル
    sleepTimerManager.cancelTimer()
  }

  override func tearDown() {
    sleepTimerManager.cancelTimer()
    sleepTimerManager = nil
    cancellables = nil
    super.tearDown()
  }

  // MARK: - 初期状態のテスト

  func testSleepTimerManager_initialState() {
    // Assert
    XCTAssertFalse(sleepTimerManager.isActive, "初期状態ではタイマーは非アクティブであるべき")
    XCTAssertEqual(sleepTimerManager.remainingTime, 0, "初期状態では残り時間は0であるべき")
  }

  // MARK: - タイマー開始のテスト

  func testSleepTimerManager_startTimer_activatesTimer() {
    // Arrange
    let expectation = XCTestExpectation(description: "タイマーがアクティブになる")

    sleepTimerManager.$isActive
      .dropFirst() // 初期値をスキップ
      .sink { isActive in
        if isActive {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act
    sleepTimerManager.startTimer(duration: 300) {}

    // Assert
    wait(for: [expectation], timeout: 1.0)
    XCTAssertTrue(sleepTimerManager.isActive, "タイマー開始後はアクティブであるべき")
    XCTAssertGreaterThan(sleepTimerManager.remainingTime, 0, "残り時間が0より大きいべき")
  }

  func testSleepTimerManager_startTimer_setsRemainingTime() {
    // Arrange
    let duration: TimeInterval = 600 // 10分

    // Act
    sleepTimerManager.startTimer(duration: duration) {}

    // Assert
    XCTAssertEqual(sleepTimerManager.remainingTime, duration, accuracy: 0.1, "残り時間が設定されるべき")
  }

  // MARK: - タイマーキャンセルのテスト

  func testSleepTimerManager_cancelTimer_deactivatesTimer() {
    // Arrange
    sleepTimerManager.startTimer(duration: 300) {}
    XCTAssertTrue(sleepTimerManager.isActive, "タイマーが開始されているべき")

    let expectation = XCTestExpectation(description: "タイマーがキャンセルされる")

    sleepTimerManager.$isActive
      .dropFirst() // 現在のtrueをスキップ
      .sink { isActive in
        if !isActive {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act
    sleepTimerManager.cancelTimer()

    // Assert
    wait(for: [expectation], timeout: 1.0)
    XCTAssertFalse(sleepTimerManager.isActive, "キャンセル後はタイマーが非アクティブであるべき")
    XCTAssertEqual(sleepTimerManager.remainingTime, 0, "キャンセル後は残り時間が0であるべき")
  }

  // MARK: - タイマー終了のテスト

  func testSleepTimerManager_timerEnd_callsCallback() {
    // Arrange
    let expectation = XCTestExpectation(description: "タイマー終了時にコールバックが呼ばれる")
    var callbackCalled = false

    // Act: 非常に短い時間でタイマーを開始
    sleepTimerManager.startTimer(duration: 0.1) {
      callbackCalled = true
      expectation.fulfill()
    }

    // Assert
    wait(for: [expectation], timeout: 2.0)
    XCTAssertTrue(callbackCalled, "コールバックが呼ばれるべき")
    XCTAssertFalse(sleepTimerManager.isActive, "タイマー終了後は非アクティブであるべき")
    XCTAssertEqual(sleepTimerManager.remainingTime, 0, "タイマー終了後は残り時間が0であるべき")
  }

  // MARK: - 残り時間の更新テスト

  func testSleepTimerManager_remainingTime_decreases() {
    // Arrange
    let initialDuration: TimeInterval = 2.0

    // Act
    sleepTimerManager.startTimer(duration: initialDuration) {}
    let firstValue = sleepTimerManager.remainingTime

    // 1.2秒待機
    let expectation = XCTestExpectation(description: "時間が経過する")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.5)

    // Assert
    let secondValue = sleepTimerManager.remainingTime
    XCTAssertGreaterThan(firstValue, 0, "最初の値は0より大きいべき")
    XCTAssertLessThan(secondValue, firstValue, "時間が経過すると残り時間が減少するべき")
  }

  // MARK: - 複数回の開始テスト

  func testSleepTimerManager_startTimer_multipleTimes_replacesTimer() {
    // Arrange
    sleepTimerManager.startTimer(duration: 600) {}
    let firstRemainingTime = sleepTimerManager.remainingTime

    // Act: 異なる時間で再度開始
    sleepTimerManager.startTimer(duration: 300) {}

    // Assert
    XCTAssertTrue(sleepTimerManager.isActive, "タイマーがアクティブであるべき")
    XCTAssertNotEqual(sleepTimerManager.remainingTime, firstRemainingTime, "新しい時間が設定されるべき")
    XCTAssertEqual(sleepTimerManager.remainingTime, 300, accuracy: 0.1, "新しい残り時間が設定されるべき")
  }

  // MARK: - Publisherのテスト

  func testSleepTimerManager_isActive_publishesCorrectly() {
    // Arrange
    let startExpectation = XCTestExpectation(description: "タイマー開始でtrueが発行される")

    sleepTimerManager.$isActive
      .dropFirst() // 初期値をスキップ
      .sink { value in
        if value == true {
          startExpectation.fulfill()
        }
      }
      .store(in: &cancellables)

    // Act
    sleepTimerManager.startTimer(duration: 300) {}

    // Assert
    wait(for: [startExpectation], timeout: 0.5)
    XCTAssertTrue(sleepTimerManager.isActive, "タイマーがアクティブであるべき")

    // キャンセルのテスト
    let cancelExpectation = XCTestExpectation(description: "タイマーキャンセルでfalseが発行される")
    cancellables.removeAll()

    sleepTimerManager.$isActive
      .dropFirst() // 現在のtrueをスキップ
      .sink { value in
        if value == false {
          cancelExpectation.fulfill()
        }
      }
      .store(in: &cancellables)

    sleepTimerManager.cancelTimer()

    wait(for: [cancelExpectation], timeout: 0.5)
    XCTAssertFalse(sleepTimerManager.isActive, "タイマーがキャンセルされているべき")
  }
}
