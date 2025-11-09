# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## アプリの概要

### アプリ名
**PickupPlayer** - 中断した音声コンテンツを、続きから簡単に再開できる音声プレーヤー

### 機能概要

- このアプリは、iOSデバイス(iPhone/iPad)内の音声ファイルを再生するためのアプリである。
- ファイルの再生位置(冒頭から何秒まで再生したか)を保存(永続化)しておき、次に同じファイルを再生するときには、保存していた位置から再生を再開できることを特徴とする。
- ポッドキャストやオーディオブックなど、長時間の音声コンテンツの再生に適している。

### 音声ファイルの再生（Player画面）
- 再生用の画面は、次の部品を持つ：
  - **アートワーク画像**: 画面上半分を占める大きな表示
  - **タイトル表示**: 音声ファイルのタイトル
  - **再生時間表示**: 現在の再生位置（mm:ss形式）と総再生時間
  - **再生位置スライダー**:
    - スライダーをドラッグすることで、ユーザが再生位置を変更できる
    - ドラッグ中は、リアルタイムで時間表示（mm:ss）が更新される
  - **コントロールボタン**:
    - 30秒巻き戻しボタン
    - Play/Pauseボタン
    - 30秒早送りボタン

### プレイリスト機能（Playlist画面）

#### ファイルの追加方法
アプリは2つの方法でファイルをプレイリストに追加できる：

1. **ミュージックライブラリから追加**:
   - デバイスのミュージックライブラリ（Apple Music、購入した音楽など）から選択
   - ファイルはアプリのDocumentsディレクトリにエクスポートされる
   - エクスポート中は進捗バーが表示される
   - 複数ファイルの同時エクスポートに対応
   - MPMediaItemから直接アートワークを取得

2. **Files appから追加**:
   - iCloud Drive、OneDrive、その他のクラウドストレージから選択可能
   - ファイルは自動的にアプリのDocumentsディレクトリにコピーされる
   - 複数ファイルの同時選択に対応
   - 対応フォーマット: .mp3, .m4a, .mp4（音声のみ再生）など

#### プレイリストの機能
- **アイテム表示**: 各アイテムにはアートワークのサムネイル、タイトル、再生時間が表示される
- **並び替え**: リスト内のアイテムをドラッグ＆ドロップで並び替え可能
- **削除**: スワイプでアイテムを削除
- **再生開始**: アイテムをタップすると、自動的にPlayer画面に移動して再生開始
- **永続化**: プレイリストの内容はUserDefaultsに保存され、アプリ再起動後も保持される

### ロック画面での機能（Now Playing）
- 他のアプリを起動したり、画面がロックしたりしても、バックグラウンド再生を継続
- ロック画面とコントロールセンターに以下を表示：
   - アートワーク画像
   - ファイル名（タイトル）
   - 再生時間情報
   - Play/Pauseボタン
   - 30秒巻き戻しボタン
   - 30秒早送りボタン
- ロック画面からの操作でも、アプリ内の状態が正しく更新される

## データ永続化の実装

### ファイルの保存方式
- **音声ファイル**: アプリのDocumentsディレクトリに保存
- **ファイルパスの管理**:
  - 相対パス（ファイル名のみ）で保存することで、アプリ更新時のコンテナUUID変更に対応
  - 実行時にDocumentsディレクトリのパスと結合してフルパスを生成
- **アートワーク**:
  - Documentsディレクトリ内の`Artworks`サブディレクトリに個別のJPEGファイルとして保存
  - ファイル名: `{UUID}.jpg`（AudioFileのIDと対応）
  - 相対パスで管理
- **プレイリスト**: UserDefaultsにJSON形式で保存
- **再生位置**: PlaybackStateManagerがUserDefaultsに保存（ファイルIDをキーとして管理）

### 旧バージョンからのデータ移行
- 絶対パスで保存された旧データを自動的に相対パスに変換
- デコード時に旧形式（絶対パスのURL）と新形式（相対パスのfileName）の両方に対応

## アーキテクチャ

### デザインパターン
- **MVVM（Model-View-ViewModel）**: SwiftUIのベストプラクティスに従う
- **Singleton**: 共有リソース管理（AudioPlayerManager、ArtworkManager、NowPlayingManagerなど）

### 主要なファイル構成

#### Models
- `AudioFile.swift`: 音声ファイルのデータモデル（Codable、Identifiable、Equatable）
- `Playlist.swift`: プレイリストの管理（ObservableObject）
- `ExportTask.swift`: エクスポート進捗の管理

#### Views
- `ContentView.swift`: タブビューのルート
- `PlayerView.swift`: 再生画面
- `PlaylistView.swift`: プレイリスト画面
- `DocumentPickerView.swift`: ファイルピッカーのUIRepresentable
- `MusicPickerView.swift`: ミュージックライブラリピッカーのUIRepresentable

#### ViewModels
- `PlayerViewModel.swift`: Player画面のロジック
- `MusicPickerViewModel.swift`: ミュージックライブラリからのエクスポート管理

#### Managers
- `AudioPlayerManager.swift`: 音声再生の中核（AVAudioPlayer管理）
- `NowPlayingManager.swift`: Now Playing情報とリモートコントロールの管理
- `PlaybackStateManager.swift`: 再生位置の永続化
- `ArtworkManager.swift`: アートワーク画像の保存・読み込み

#### Utilities
- `TimeFormatter.swift`: TimeInterval → mm:ss形式の変換
- `ArtworkExtractor.swift`: 音声ファイルからアートワークを抽出

## 開発時の注意点

### コーディング規約
- **インデント**: 半角スペースを使用（タブは使用しない）
- **インデント幅**: 2スペース
- 既存のSwiftファイルと一貫性を保つため

### セキュリティとエラーハンドリング
- ファイルの存在確認を必ず行う
- ファイルアクセス失敗時は適切にエラー状態をクリアする
- Now Playing情報もエラー時にクリアして、ロック画面の表示が残らないようにする

### iOS固有の注意点
- **AVAudioSession**: `.playback`カテゴリを設定してバックグラウンド再生を有効化
- **MPRemoteCommandCenter**: リモートコントロールコマンドをNotificationCenterで中継
- **Security-Scoped Resources**: Files appからのファイルは`asCopy: true`でコピーするため、セキュリティスコープアクセスは基本的に不要

## Claude Code対応指示

### コミュニケーション言語
- **検討過程と回答**: 日本語で表示すること
- **コード分析や実装検討**: 日本語で説明すること
- **技術的な議論**: 日本語で行うこと

### ビルドとテスト
- **使用するシミュレータ**: `iPhone 17`
- **ビルドコマンド例**:
  ```bash
  xcodebuild -project PickupPlayer.xcodeproj -scheme PickupPlayer \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```

