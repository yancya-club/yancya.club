# AGENTS.md

## Claude -> Codex handoff (2026-09-11)

このセクションは Claude Code セッション群での運用実績をもとに、Codex（や他エージェント）が単独で引き継ぐ際に見落としやすい点をまとめたもの。手順自体（新シーズン追加・イベント追加）は README.md を参照。ここには README に書かれていない、または経緯を知らないと分からない情報のみを記す。

### リポジトリの正体
- Ruby 製の静的サイトジェネレータ + GitHub Pages 配信サイト（`yancya.club`、個人ライブ配信「やんちゃクラブ」の告知・アーカイブページ）。
- `docs/` が配信ルート。`.github/workflows/static.yml` が `main` への push で GitHub Pages に自動デプロイする。
- **`main` への merge = 即座に本番デプロイ。** そのため通常のブランチ作業では `main` に直接 commit しない。feature ブランチで PR を作り、CI green を確認したうえで **merge するかどうかは必ず人間の判断を待つ**（実装・push は進めてよいが、merge 実行は明示的な承認を得てから）。過去セッションでも「push は GO 済みでも merge は別」という運用で一貫している。

### `git wt` を使う
- ブランチ作成・切り替えは `git wt <branch> [start-point]`（新規）、`git wt <branch>`（既存）を使う。`.wt/` 以下に worktree が作られる。
- 作業開始前に必ず `git fetch origin main && git branch -f main origin/main` でローカル main を最新化してから `git wt <new-branch> main` すること（ローカル main が stale なまま分岐して、PR のベースが古くなる事故が過去に発生した）。

### テスト
- `ruby test/new_season_test.rb`: `scripts/new_season.rb` の `NewSeason` モジュールの単体テスト（一時ディレクトリに fixture 画像を置いて生成 HTML を厳密比較）。golden file 的に completeness を保証している。
- `ruby test/events_test.rb`: `docs/events/index.html` のプレースホルダ表示・日付降順・`docs/events/_template/index.html` の必須セクションを検証。
- 外部 gem 不要、`minitest/autorun` のみ。CI に組み込まれた自動テスト実行 workflow は無い（ローカルで手動実行する運用）。

### CI（`.github/workflows/`）
- `static.yml`: `docs/` を GitHub Pages にデプロイ（`main` push トリガー）。
- `link-checker.yml` (`Check Links`): lychee で `docs/**/*.html` のリンク切れを push/PR/週次 cron でチェック。**2026-08-20 に一度事故った教訓が残っている**:
  - `href="/"` のようなルート相対リンクを lychee が解決できず false positive になるので `--root-dir ./docs` が必須。
  - `docs/events/_template/index.html` はプレースホルダ画像 `image.webp` を含まないテンプレートなので `--exclude-path 'docs/events/_template'` で対象外にしている。
  - 失敗時に issue を自動作成する `Create Issue From File` ステップがあるが、job に `permissions: issues: write` が無いと `Resource not accessible by integration` で失敗する（付与済み）。
  - 新ページの canonical/og:url が公開前の本番URLを指すと 404 になるため、`--remap '^https://yancya\.club/(.*)$ file://<workspace>/docs/$1'` で自サイトの絶対URLを `docs/` の実ファイルに読み替えて検証している（2026-09-29、PR #26）。
  - `x.com` は bot アクセスを 403 で拒否するため `--exclude '^https://x\.com/'` で除外している。
  - 変更を加えるときは `brew install lychee` してローカルで `lychee --offline --root-dir ./docs --exclude-path 'docs/events/_template' 'docs/**/*.html'` を実行すると速い（`--offline` は外部URLをスキップするので、ローカル/相対リンクの検証専用）。
- `auto-assign.yml`: 詳細未調査。PR 作成者への auto-assign 目的と思われる。

### シーズンページ運用の実データ
- 100 話ごとに `docs/yancya-club-<開始>-<終了>/` ディレクトリ（サムネイル100枚 + `index.html`）を追加する。2026-09-11 時点で `001-100` 〜 `1701-1800` まで存在（最新は 2026/05/13〜2026/08/20 配信分）。
- 画像は人間（yancya さん）が用意する前提。エージェント側では生成しない。
- `scripts/new_season.rb` は先頭 3 枚（`NewSeason::EAGER_COUNT`）だけ `loading="lazy"` を付けない（ファーストビュー最適化）。すべての `<img>` に `decoding="async"` と alt（`やんちゃクラブ #<話数> サムネイル`）を付与する。
- 次の追加候補は `1801-1900` シーズン（現行進行中）。README の手順通りでよいが、開始日・終了日（配信日）はユーザーに確認する必要がある（過去、終了日を推測せず必ず本人に聞く運用にしている）。

### イベントページ運用
- `docs/events/_template/index.html` をコピーして使う。OGP・Twitter Card・募集要項（場所・日時・料金・予約要否）を埋める。画像は `image.webp` としてイベントディレクトリに置く。
- `docs/events/index.html` の「やんちゃクラブイベント予定」セクションが空のときは `<p>現在告知中のイベントはありません。</p>` のプレースホルダを表示する仕様（2026-08 頃に追加）。イベントを追記したらこの文言を削除する。
- 「実施済みイベント」セクションは開催日降順を維持。

### トップページ (`docs/index.html`) の構造
- `<h2>Links</h2>` 配下に SNS・外部サービスへのリンク一覧がある。命名・URL の変更は都度発生している（例: `twitter.yancya.club` → `x.yancya.club`、`qa.yancya.club` (note質問箱) の追加）。個々のサブドメインの DNS/リダイレクト設定はこのリポジトリの管轄外（Cloudflare 等インフラ側、`yancya-club/db` など別リポジトリで管理されている節がある）。
- アイコン画像は `docs/yancya-icon-1000.jpeg`（1000x1000 jpeg）としてリポジトリ直下 `docs/` に置かれている。`https://yancya.club/yancya-icon-1000.jpeg` で直接参照される想定。

### GitHub issue 運用
- issue #7, #9 はロードマップ/親トラッキング issue。#10, #11 は共通CSS抽出・OGP/favicon/lang/viewport整備で#7の子。着手前に `gh issue view` で依存関係と受け入れ条件を確認すること（過去 issue には「前提（人間タスク）」「受け入れ条件」が明記されているものが多い）。
- issue 本文に実行時期・前提条件（例: 現行シーズン終了後まで着手しない、等）が書かれていることがあるので、着手前に必ず読むこと。

### コミット規約
- 日本語のコミットメッセージ、要約1行 + 空行 + 詳細（必要なら）。`Closes #<番号>` を本文に入れると PR merge 時に issue が自動クローズされる。
- PR 本文には `## Summary` / `## Test plan` の2セクションを置く運用が定着している。

### 音声/動画文字起こし（このリポジトリ外の付随作業）
- 配信アーカイブ動画（`~/Downloads/yancya-club-<話数>-<YYYYMMDD>.m4v`）の文字起こし・チャプター生成は、このリポジトリのコードとは無関係な運用タスクとして頻繁に依頼される。リポジトリの commit 対象ではない。
- 2026-09-30 から文字起こしは ElevenLabs Scribe v2 に切り替えた（whisper より誤変換・繰り返しの誤作動が明確に少なかった）。`ruby ~/sandbox/recording_textup/yancya_club/bin/transcribe --out <DIR> VIDEO...` で `<key>.txt/.vtt` を出す。表記ゆれは同ディレクトリの `terms.yml`（keyterms と置換辞書）に足していく。API 応答 `<key>.json` を保存・再利用するので、辞書更新後の再整形に課金はかからない。
- Codex で `ELEVENLABS_API_KEY` が未設定の場合、fish の export 済み universal 変数を確認する（2026-11-21 実機確認）。通常の `fish -c 'ruby ...'` では継承されたが、zsh と `fish --no-config` では未設定だった。キー値は表示・転記せず、fish 経由で既存スクリプトを実行する。
- 音声抽出の速度に注意（2026-11-21）: 既存 `transcribe` は16kHz・モノラル・64kbps AACへ再エンコードし、1889（約62分）の抽出に約11分かかった。AAC音声を含む1891（約22分）の `ffmpeg -i VIDEO -map 0:a:0 -c:a copy AUDIO.m4a` は実測3.827秒で、長さも一致。次回は入力コーデックを確認し、AACなら音声コピーを優先する。元スクリプト自体はまだ未改修。2026-11-22 に1893（約23分）で `ffmpeg -map 0:a:0 -c:a copy` した `yancya-club-<話数>-<日付>.m4a` をそのまま `transcribe` に渡して成功（抽出0.3秒、キーはファイル名から取られるので命名を揃えれば出力名も同じ）。`transcribe` は `.ts.txt` を出さないので、チャプター作業用には vtt から `MM:SS 本文` 形式を Ruby で生成している。
