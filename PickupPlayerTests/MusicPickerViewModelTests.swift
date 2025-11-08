//
//  MusicPickerViewModelTests.swift
//  AudioFilePlayerTests
//
//  Created by Yoshifumi Sato on 2025/11/07.
//

import XCTest
import MediaPlayer
@testable import PickupPlayer

final class MusicPickerViewModelTests: XCTestCase {

  var viewModel: MusicPickerViewModel!
  var playlist: Playlist!

  override func setUp() {
    super.setUp()
    // UserDefaultsをクリア
    UserDefaults.standard.removeObject(forKey: "playlist")
    playlist = Playlist()
    viewModel = MusicPickerViewModel(playlist: playlist)
  }

  override func tearDown() {
    UserDefaults.standard.removeObject(forKey: "playlist")
    viewModel = nil
    playlist = nil
    super.tearDown()
  }

  // MARK: - 初期状態のテスト

  func testViewModel_initialState() {
    // Assert
    XCTAssertFalse(viewModel.isExporting, "初期状態ではエクスポート中でないべき")
    XCTAssertEqual(viewModel.exportTasks.count, 0, "初期状態でのエクスポートタスクは空であるべき")
    XCTAssertNil(viewModel.errorMessage, "初期状態ではエラーメッセージはnilであるべき")
  }

  // MARK: - エラー状態のテスト

  func testViewModel_errorMessageCanBeSet() {
    // Act
    viewModel.errorMessage = "テストエラー"

    // Assert
    XCTAssertEqual(viewModel.errorMessage, "テストエラー", "エラーメッセージが正しく設定されるべき")
  }

  func testViewModel_errorMessageCanBeCleared() {
    // Arrange
    viewModel.errorMessage = "テストエラー"

    // Act
    viewModel.errorMessage = nil

    // Assert
    XCTAssertNil(viewModel.errorMessage, "エラーメッセージがクリアされるべき")
  }

  // MARK: - エクスポート状態のテスト

  func testViewModel_isExportingReturnsTrueWhenTaskIsExporting() {
    // Arrange
    let task = ExportTask(fileName: "test.m4a", status: .exporting)

    // Act
    viewModel.exportTasks.append(task)

    // Assert
    XCTAssertTrue(viewModel.isExporting, "エクスポートタスクがある場合、isExportingはtrueであるべき")
  }

  func testViewModel_isExportingReturnsFalseWhenNoTasksExporting() {
    // Arrange
    let task = ExportTask(fileName: "test.m4a", status: .completed)

    // Act
    viewModel.exportTasks.append(task)

    // Assert
    XCTAssertFalse(viewModel.isExporting, "エクスポート中のタスクがない場合、isExportingはfalseであるべき")
  }

  // MARK: - handleSelectedMediaItems のテスト
  // 注意: MPMediaItemCollectionは実際のミュージックライブラリが必要なため、
  // このメソッドの完全なテストは統合テストで行う必要があります。
  // ここでは基本的な動作のみをテストします。

  func testViewModel_handleSelectedMediaItems_withEmptyCollection() {
    // Arrange
    let emptyCollection = MPMediaItemCollection(items: [])

    // Act
    viewModel.handleSelectedMediaItems(emptyCollection)

    // Assert
    // 空のコレクションの場合、プレイリストに何も追加されないべき
    XCTAssertEqual(playlist.items.count, 0, "空のコレクションではプレイリストは空のままであるべき")
  }

  // MARK: - 統合テストのためのコメント
  // 以下のテストは実際のオーディオファイルとミュージックライブラリが必要なため、
  // 統合テストまたはUIテストで実装することを推奨します。
  //
  // 1. testViewModel_handleSelectedMediaItems_withValidItems
  //    - 実際のMPMediaItemを使用してファイルがエクスポートされることを確認
  //
  // 2. testViewModel_exportMusicFile_success
  //    - 実際のミュージックファイルのエクスポートが成功することを確認
  //
  // 3. testViewModel_exportMusicFile_failure
  //    - 無効なファイルのエクスポートが失敗することを確認
  //
  // 4. testViewModel_exportAndAddToPlaylist_success
  //    - エクスポート後にプレイリストにアイテムが追加されることを確認
  //
  // 5. testViewModel_exportMusicFile_setsExportingState
  //    - エクスポート中にisExportingがtrueになることを確認
  //
  // 6. testViewModel_exportMusicFile_handlesSpecialCharactersInTitle
  //    - ファイル名に特殊文字が含まれる場合の処理を確認
  //
  // 7. testViewModel_exportMusicFile_handlesDuplicateFileNames
  //    - 同名ファイルが既に存在する場合の上書き処理を確認

  // MARK: - モック実装の例（将来の拡張用）
  // ViewModelをより詳細にテストするには、以下のようなモックの実装が推奨されます：
  //
  // 1. MockAVAssetExportSession
  //    - AVAssetExportSessionの動作をモック化
  //    - エクスポートの成功/失敗をシミュレート
  //
  // 2. MockFileManager
  //    - ファイルシステム操作をモック化
  //    - ファイルの存在チェックやコピー操作をシミュレート
  //
  // 3. Dependency Injection の改善
  //    - ViewModelにFileManagerやExportSessionFactoryを注入可能にする
  //    - テスト時にモックを注入してテストを容易にする
}
