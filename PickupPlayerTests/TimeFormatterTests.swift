//
//  TimeFormatterTests.swift
//  AudioFilePlayerTests
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import XCTest
@testable import PickupPlayer

final class TimeFormatterTests: XCTestCase {

  func testFormatTime_seconds() {
    // 秒のみ
    let result = TimeFormatter.formatTime(45)
    XCTAssertEqual(result, "0:45", "45秒は '0:45' とフォーマットされるべき")
  }

  func testFormatTime_minutes() {
    // 分と秒
    let result = TimeFormatter.formatTime(125)
    XCTAssertEqual(result, "2:05", "125秒は '2:05' とフォーマットされるべき")
  }

  func testFormatTime_hours() {
    // 時間、分、秒
    let result = TimeFormatter.formatTime(3665)
    XCTAssertEqual(result, "1:01:05", "3665秒は '1:01:05' とフォーマットされるべき")
  }

  func testFormatTime_zero() {
    // ゼロ秒
    let result = TimeFormatter.formatTime(0)
    XCTAssertEqual(result, "0:00", "0秒は '0:00' とフォーマットされるべき")
  }

  func testFormatTime_exactMinute() {
    // ちょうど1分
    let result = TimeFormatter.formatTime(60)
    XCTAssertEqual(result, "1:00", "60秒は '1:00' とフォーマットされるべき")
  }

  func testFormatTime_exactHour() {
    // ちょうど1時間
    let result = TimeFormatter.formatTime(3600)
    XCTAssertEqual(result, "1:00:00", "3600秒は '1:00:00' とフォーマットされるべき")
  }

  func testFormatTime_multipleHours() {
    // 複数時間
    let result = TimeFormatter.formatTime(7384)
    XCTAssertEqual(result, "2:03:04", "7384秒は '2:03:04' とフォーマットされるべき")
  }
}
