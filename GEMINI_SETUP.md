# Gemini API セットアップガイド

## Gemini API Key の取得

1. [Google AI Studio](https://makersuite.google.com/app/apikey) にアクセス
2. Googleアカウントでログイン
3. 「Create API Key」をクリック
4. 新しいプロジェクトを作成するか、既存のプロジェクトを選択
5. 生成されたAPI Keyをコピー

## 環境変数の設定

`.env` ファイルに以下を設定：

```bash
GEMINI_API_KEY=YOUR_ACTUAL_API_KEY_HERE
```

## Gemini APIの特徴

- **モデル**: `gemini-pro` を使用
- **多言語対応**: 日本語の精度が高い
- **無料枠**: 月間60リクエスト/分、1,500リクエスト/日
- **安全性**: Built-in safety settings

## API使用量の確認

[Google AI Studio](https://makersuite.google.com/app/apikey) の「Usage」タブで使用量を確認できます。

## 注意事項

- API Keyは絶対に公開リポジトリにコミットしないでください
- 本番環境では適切なレート制限を設定してください
- 商用利用時は利用規約を確認してください