//
//  MusicPickerView.swift
//  PickupPlayer
//
//  Created by Yoshifumi Sato on 2025/11/06.
//

import SwiftUI
import MediaPlayer

struct MusicPickerView: UIViewControllerRepresentable {
  @ObservedObject var viewModel: MusicPickerViewModel
  @Environment(\.dismiss) var dismiss

  func makeUIViewController(context: Context) -> MPMediaPickerController {
    let picker = MPMediaPickerController(mediaTypes: .music)
    picker.allowsPickingMultipleItems = true
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, MPMediaPickerControllerDelegate {
    let parent: MusicPickerView

    init(_ parent: MusicPickerView) {
      self.parent = parent
    }

    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
      parent.viewModel.handleSelectedMediaItems(mediaItemCollection)
      parent.dismiss()
    }

    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
      parent.dismiss()
    }
  }
}
