# AI専門相談チャットアプリ

AI専門家とチャット形式で相談できるWebアプリケーション

## 技術スタック

### バックエンド (backend/)
- Rails 7 (API モード)
- PostgreSQL
- Gemini API統合

### フロントエンド (frontend/)
- Vue.js 3
- Chakra UI または Material-UI

## 主な機能

1. ユーザー認証（サインアップ、ログイン）
2. 専門家AI選択機能
3. リアルタイムチャット機能
4. 会話履歴の保存・表示

## 専門家AI一覧

- 法律アドバイザー
- キャリアアドバイザー
- 心理カウンセラー
- 金融アドバイザー
- 健康アドバイザー

## セットアップ

### 前提条件
- Docker & Docker Compose
- Gemini API Key

### 1. 環境変数の設定

```bash
# backend/.env ファイルを作成
cp backend/.env.example backend/.env
```

backend/.env ファイルを編集し、以下を設定：
```
GEMINI_API_KEY=your_gemini_api_key_here
DATABASE_URL=postgresql://postgres:password@db:5432/ai_chat_development
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base_here
```

### 2. Docker Composeで起動

```bash
# 全サービスを起動
docker-compose up -d

# ログを確認
docker-compose logs -f
```

### 3. データベースの初期化

```bash
# Railsコンテナ内でマイグレーション実行
docker-compose exec backend rails db:create
docker-compose exec backend rails db:migrate
```

### 4. アクセス

- フロントエンド: http://localhost:8080
- バックエンドAPI: http://localhost:3000
- PostgreSQL: localhost:5432

### 開発用コマンド

```bash
# サービス停止
docker-compose down

# 特定サービスの再起動
docker-compose restart backend

# Railsコンソール
docker-compose exec backend rails console

# ログ確認
docker-compose logs backend
docker-compose logs frontend
```

## デプロイ

- フロントエンド: Vercel
- バックエンド・DB: Render