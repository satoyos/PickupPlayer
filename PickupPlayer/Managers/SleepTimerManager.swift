//
//  SleepTimerManager.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/09.
//

import Foundation
import Combine

class SleepTimerManager: ObservableObject {
  static let shared = SleepTimerManager()

  @Published var isActive = false
  @Published var remainingTime: TimeInterval = 0

  private var timer: Timer?
  private var endTime: Date?
  private var onTimerEnd: (() -> Void)?

  private init() {}

  // タイマーを開始
  func startTimer(duration: TimeInterval, onEnd: @escaping () -> Void) {
    cancelTimer()

    endTime = Date().addingTimeInterval(duration)
    remainingTime = duration
    isActive = true
    onTimerEnd = onEnd

    // 1秒ごとに残り時間を更新
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.updateRemainingTime()
    }
  }

  // タイマーをキャンセル
  func cancelTimer() {
    timer?.invalidate()
    timer = nil
    endTime = nil
    remainingTime = 0
    isActive = false
    onTimerEnd = nil
  }

  private func updateRemainingTime() {
    guard let endTime = endTime else {
      cancelTimer()
      return
    }

    let remaining = endTime.timeIntervalSinceNow

    if remaining <= 0 {
      // タイマー終了
      let callback = onTimerEnd
      cancelTimer()
      callback?()
    } else {
      remainingTime = remaining
    }
  }
}
