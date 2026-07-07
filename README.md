# yancya.club
yancya.club のコンテンツ

## 新シーズン追加手順

やんちゃクラブは100回ごとにシーズンページ（サムネイル100枚 + index.html）を追加する。
例として 1701-1800 シーズンを追加する場合:

1. **画像を配置する**

   `docs/yancya-club-1701-1800/` を作り、サムネイル画像を
   `yancya-club-1701-1800.001.jpeg` 〜 `yancya-club-1701-1800.100.jpeg` の命名で置く
   （連番3桁ゼロ埋め。枚数は100固定でなくてもよい）。

2. **生成スクリプトを実行する**（開始日・終了日は配信日）

   ```sh
   ruby scripts/new_season.rb docs/yancya-club-1701-1800 2026/05/13 2026/08/20
   ```

   ディレクトリ内の jpeg を昇順に列挙した `index.html` が生成され、
   トップページに追記すべき1行が標準出力に表示される。
   書き込む前に内容を確認したいときは `--dry-run` を付ける。

3. **トップページにリンクを追記する**

   `docs/index.html` の「Past seasons」セクション末尾に、手順2で表示された
   `<p><a href="yancya-club-1701-1800">やんちゃクラブ１７０１〜１８００</a> (2026/05/13〜2026/08/20)</p>`
   形式の行を追記する。

4. **push する**

   main に push すると GitHub Pages（`.github/workflows/static.yml`、`docs/` 配信）が自動デプロイする。

### テスト

```sh
ruby test/new_season_test.rb
```

生成 HTML が既存の `docs/yancya-club-1601-1700/index.html` と完全一致することを含めて検証する。
