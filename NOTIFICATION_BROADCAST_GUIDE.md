# 運営お知らせ配信手順

## 概要
Firestore の `adminBroadcasts` にドキュメントを 1 件追加すると、以下が同時に実行されます。

- 全ユーザーに Push 通知を送信
- 各ユーザーの通知ボックス（`users/{uid}/adminNotifications`）に保存

## 前提
- Cloud Functions `publishAdminBroadcast` がデプロイ済みであること
- アプリ側が最新バージョンで通知受信に対応していること

## 配信手順
1. Firebase Console を開く
2. `Firestore Database` を開く
3. `adminBroadcasts` コレクションを開く（なければ作成）
4. `ドキュメントを追加` を押す
5. `ドキュメントID` は `自動ID` のままで OK
6. 次の 2 フィールドを追加して保存する

- `title`（string）
  - 例: `運営からのお知らせ`
- `body`（string）
  - 例: `本日22:00にメンテナンスを実施します。`

## 動作確認
- 端末に Push 通知が届く
- アプリの通知ボックスに同じ内容が表示される
- 未読がある間はマイページの下部ナビに赤いマークが表示される

## よくある注意点
- `adminBroadcasts` への追加は全体配信です（個別配信ではありません）
- `body` が空だと配信されません
- 通知を受けるには、ユーザー端末で通知許可が必要です

## 将来の拡張（必要なら）
- 予約配信（`scheduledAt`）
- テンプレート配信（メンテ・障害・更新）
- 個別配信（`targetUid` 指定）
