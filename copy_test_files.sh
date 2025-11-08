#!/bin/bash

# AudioFilePlayerアプリのテスト用音声ファイルをシミュレータにコピーするスクリプト

BUNDLE_ID="com.sato0123.AudioFilePlayer"

# シミュレータが起動しているか確認
if ! xcrun simctl list devices | grep -q "Booted"; then
  echo "エラー: シミュレータが起動していません"
  echo "Xcodeでアプリを起動してから、このスクリプトを実行してください"
  exit 1
fi

# アプリのコンテナパスを取得
APP_CONTAINER=$(xcrun simctl get_app_container booted "$BUNDLE_ID" data 2>/dev/null)

if [ -z "$APP_CONTAINER" ]; then
  echo "エラー: アプリがインストールされていません"
  echo "Xcodeでアプリをビルド＆実行してから、このスクリプトを実行してください"
  exit 1
fi

DOCUMENTS_DIR="$APP_CONTAINER/Documents"

echo "アプリのDocumentsディレクトリ: $DOCUMENTS_DIR"
echo ""

# Documentsディレクトリが存在することを確認
if [ ! -d "$DOCUMENTS_DIR" ]; then
  mkdir -p "$DOCUMENTS_DIR"
  echo "Documentsディレクトリを作成しました"
fi

# テスト用音声ファイルをコピー
# ここでは、ユーザーがファイルパスを引数として渡すことを想定
if [ $# -eq 0 ]; then
  echo "使用方法:"
  echo "  $0 <音声ファイルのパス> [<音声ファイルのパス2> ...]"
  echo ""
  echo "例:"
  echo "  $0 ~/Music/sample.mp3"
  echo "  $0 ~/Music/sample1.mp3 ~/Music/sample2.m4a"
  echo ""
  echo "現在のDocumentsディレクトリの内容:"
  ls -lh "$DOCUMENTS_DIR"
  exit 0
fi

# 引数で指定されたすべてのファイルをコピー
COPIED_COUNT=0
for FILE_PATH in "$@"; do
  if [ -f "$FILE_PATH" ]; then
    FILE_NAME=$(basename "$FILE_PATH")
    cp "$FILE_PATH" "$DOCUMENTS_DIR/$FILE_NAME"
    echo "✓ コピーしました: $FILE_NAME"
    COPIED_COUNT=$((COPIED_COUNT + 1))
  else
    echo "✗ ファイルが見つかりません: $FILE_PATH"
  fi
done

echo ""
echo "$COPIED_COUNT 個のファイルをコピーしました"
echo ""
echo "Documentsディレクトリの内容:"
ls -lh "$DOCUMENTS_DIR"
