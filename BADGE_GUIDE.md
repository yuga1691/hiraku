# バッジ運用ガイド

## 1. アイコンのつけ方（既存2種）
対象ユーザーの Firestore `users/{userId}` にフラグを設定します。

- 初期ユーザーバッジ（`rocket_launch`）  
`hasInitialUserBadge: true`
- 公式公認バッジ（`workspace_premium`）  
`hasOfficialBadge: true`

例:

```json
{
  "hasInitialUserBadge": true,
  "hasOfficialBadge": false
}
```

補足:

- `false` にすれば非表示になります。
- 画面反映は、必要に応じて `R`（Hot Restart）か画面再表示で確認してください。

## 2. アイコン説明文（触った時の文言）の変え方
`hint: '...'` を書き換えます。

編集ファイル:

- `lib/widgets/app_card.dart`
- `lib/screens/my_page_screen.dart`

変更箇所の例:

- `hint: 'HIRAKUの開発に協力していただいた方です'`
- `hint: '本アプリ開発者です'`

## 3. 新アイコンの導入方法
新しいバッジを増やすときは、下記の順で追加します。

1. Firestoreの`users`に新フラグを追加  
例: `hasCommunityBadge: false`
2. 初期ユーザー作成時のデフォルトを追加  
`lib/services/firestore_service.dart` の `ensureUserDoc`
3. 読み取りモデルを追加  
`UserDisplayInfo` と `fetchUserDisplayInfo` に新フラグを追加
4. テスト一覧表示へ反映  
`lib/widgets/app_card.dart` のバッジ描画（`_PressHintIcon` 呼び出し）を追加
5. マイページ表示へ反映  
`lib/screens/my_page_screen.dart` のバッジ描画（`_PressHintBadge` 呼び出し）を追加
6. `icon` と `hint` を設定  
例: `icon: Icons.star`、`hint: 'コミュニティ貢献バッジです'`
