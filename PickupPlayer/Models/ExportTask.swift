//
//  ExportTask.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/08.
//

import Foundation

struct ExportTask: Identifiable {
  let id: UUID
  let fileName: String
  var progress: Double
  var status: Status

  enum Status: Equatable {
    case waiting
    case exporting
    case completed
    case failed(String)
  }

  init(id: UUID = UUID(), fileName: String, progress: Double = 0.0, status: Status = .waiting) {
    self.id = id
    self.fileName = fileName
    self.progress = progress
    self.status = status
  }
}
