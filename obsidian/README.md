# Obsidian と外部メモリ

## 導入

macOS、Homebrew、Node.js 22.6 以降を用意し、dotfiles のルートで実行する。

```sh
bash obsidian/install.sh
```

`install.sh` 全体からも同じ処理を呼ぶ。Obsidian を Homebrew Cask で導入し、既定では `~/Documents/Obsidian` を作る。別の場所なら `bash obsidian/install.sh /path/to/Obsidian` を使う。

アプリを開き「保管庫としてフォルダを開く」で Obsidian を選択する。Daily notes・Templates は標準プラグインで有効化済み。新規ノートは Inbox、添付は Attachments に保存する。

再実行は不足ファイルだけを追加し、既存ノート・設定は上書きしない。雛形はコピーするので dotfiles に個人のメモが混入しない。雛形の変更は既存Vaultに自動反映されない。

## Codex の共通指示

導入時に `~/.codex/AGENTS.md`（`CODEX_HOME` 指定時はその配下）を Vault の `AGENTS.md` への symlink にする。共通指示の正本は Vault 内に置き、どのプロジェクトで起動した Codex にも読み込ませる。設定後は新しい Codex セッションを開始する。

既存の共通指示が通常ファイルなら、内容を Vault に統合し、両方の変更前ファイルをタイムスタンプ付きでバックアップする。別の symlink や優先される `AGENTS.override.md` がある場合は停止する。再実行で重複統合しない。

既存 Vault の復元後など、リンクだけを設定する場合:

```sh
node --experimental-strip-types obsidian/link-codex.ts
```

共通指示を変更するときは Vault の `AGENTS.md` を編集する。雛形の変更は既存ファイルには反映されない。バックアップファイルには元の共通指示が含まれるため、Vault と同様に扱う。

## LLM から使う

Codex は普段のプロジェクトを作業フォルダとして使える。過去の情報が必要なときは、共通指示に従い Vault を参照する。例えば次のように依頼する。

> AGENTS.md、INDEX.md、MEMORY.md を読んでください。○○について関連ノートを検索し、ファイル名と確認日を示して答えてください。

共通の AGENTS.md には、決定・調査結果・問題解決・進捗の変化を作業中のLLMが判断し、個別の保存依頼なしで関連ノートへ記録する手順を定義している。保存先と記録内容を報告し、MEMORY.md への昇格・整理は専用のDreamingまたは見直しの依頼時に分けて行う。通常会話ではDreamingを起動・期限確認しない。

AIがVaultへの書き込み権限を持つ必要がある。CLAUDE.md と GEMINI.md も共通ルールへの入口として配置する。各ツールの自動読込に依存せず、初回は明示的に読ませる。指示による記録には実行漏れの可能性があり、他の会話の履歴を自動収集するものではない。

Obsidian 自体がLLMを学習させるわけではない。モデルを替えるときも同じフォルダを読み書きさせる。他のAIツールやWeb版LLMには別途、共通指示やファイル参照の連携が必要。

## 別デバイスへの移行とバックアップ

dotfiles はアプリ設定と空の雛形だけを管理する。実際の記憶は Obsidian フォルダ全体（隠しフォルダ `.obsidian` を含む）を別途バックアップ・復元する必要がある。新しいMacでは、上記の導入後にバックアップを復元し、Obsidianで開く。

クラウド同期プラグインや同期専用の定期監視は使わない。Git の origin と追跡ブランチを設定した Vault では、LLMがノートを更新した作業の区切りごとに、更新ファイルをまとめてコミット・プッシュする。記録・コミット・プッシュの成否を報告し、競合や認証エラー時は停止する。この動作は共通の AGENTS.md の指示によるもので、手動編集を常時監視するものではない。

新規 Vault の履歴管理は次のように初期化する。リモートは用途に応じてユーザーが指定したリポジトリに設定する。

```sh
cd ~/Documents/Obsidian
git init
git add .
git commit -m "Initialize portable memory vault"
git remote add origin <リポジトリURL>
git push -u origin HEAD
```

既存 Vault を別のMacで復元する場合は、リポジトリを `~/Documents/Obsidian` に clone してから `node --experimental-strip-types obsidian/link-codex.ts` を実行する。空ディレクトリは Git に含まれないため、必要なら `node --experimental-strip-types obsidian/setup.ts` も実行する。Git の認証は新しいMacでも設定が必要。Git 同期は別途のバックアップを代替しない。

Git 接続は原則 SSH を使う。新しいMacでは SSH 鍵の登録に加え、接続先のホスト鍵を確認して known_hosts に登録する必要がある。先に `ssh -T git@<Gitホスト>` で接続を確認する。未登録のホスト鍵は非対話の Git 操作では確認に応答できず `Host key verification failed` になる。ユーザー鍵の登録とは別の手順なので、接続失敗時は原因を確認し、ホスト鍵の検証を無効化しない。

週次整理はDreamingに統合し、専用枠で日次差分と週次横断を確認する。Dailyの原文は保持し、履歴を `50_Knowledge/dreaming-log.md`、期間レポートを対象週の月曜日付き `50_Knowledge/dreaming-YYYY-MM-DD.md` に残す。具体的な実行時刻とSkill導入は利用者ごとに設定する。Macローカルの定期実行はMacとアプリの稼働が必要で、停止中の処理は次に起動できた定期枠へ持ち越す。知識は反映できるが行動ルール変更は提案までとし、未確認事項を確定させない。ローカル状態と実行所有者を置く `.dreaming/` はGitから除外する。

矛盾・古い情報・リンク切れ・Inbox残件の点検は、必要に応じてAIに依頼する。APIキー等はVaultに保存しない。

## 検証

```sh
node --experimental-strip-types obsidian/setup.test.ts
```

作成と再実行時の既存ノート・設定の保護、シンボリックリンク先への誤書き込み拒否を検証する。
