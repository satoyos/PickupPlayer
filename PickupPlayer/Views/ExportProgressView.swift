//
//  ExportProgressView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/08.
//

import SwiftUI

struct ExportProgressView: View {
  let exportTasks: [ExportTask]

  var body: some View {
    VStack(spacing: 8) {
      ForEach(exportTasks.filter { $0.status == .exporting || $0.status == .waiting }) { task in
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Image(systemName: task.status == .exporting ? "arrow.down.circle.fill" : "clock.fill")
              .foregroundColor(task.status == .exporting ? .blue : .gray)
              .font(.system(size: 16))

            Text(task.fileName)
              .font(.subheadline)
              .lineLimit(1)
              .foregroundColor(.primary)

            Spacer()

            if task.status == .exporting {
              Text("\(Int(task.progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
              Text("待機中")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          if task.status == .exporting {
            ProgressView(value: task.progress)
              .progressViewStyle(.linear)
              .tint(.blue)
          } else {
            ProgressView(value: 0.0)
              .progressViewStyle(.linear)
              .tint(.gray.opacity(0.3))
          }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
      }
    }
    .padding(.horizontal)
    .padding(.bottom, 16)
  }
}
