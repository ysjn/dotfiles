---
date: 2026-11-09
type: guide
author: codex
related:
  - "[[30_Areas/ai/setup]]"
---

# エージェント運用のセットアップ

## 正本と登録

個人・チーム固有のSkillはVaultの `30_Areas/ai/skills/<名前>/` を正本にする。共有Skillは別Gitの `~/dev/skills/skills/<名前>/` を正本とし、共通の `recipes/` も同じリポジトリで管理する。Skill内部の相対参照はsymlinkの実体を基準に解決する。

共有先は [GHE jyoshida/skills](https://ghe.corp.yahoo.co.jp/jyoshida/skills)。`orchestration-core`・`gemini-double-check`・`herdr-ops`・`herdr-restart-agents`・`slack-handoff` を置く。`slack-handoff` は本人の指定により現行版のまま移設し、送信先などの設定の汎用化は別途進める。 接続記録とlockも共有リポジトリのローカル `~/dev/skills/skills/slack-handoff/scripts/handoffs/` に保存し、Gitから除外する。Vault内の旧Skillディレクトリと逆向きsymlinkは残さない。

Vaultの `30_Areas/ai/shared-skills` は共有リポジトリのルートへのsymlinkを1本置く。現在の標準配置では `../../../../dev/skills` を指し、共有Skillとrecipesをまとめて参照・編集できる。VaultのGitが追跡するのはリンクだけで、共有本文と履歴はGHE側だけが追跡する。共有Skillは共有側でcommit/pushし、利用者の更新は `git -C ~/dev/skills pull --ff-only` で行う。

新しいマシンでは、Vaultの復元に加えて次を実行する。別の場所へcloneする場合はsymlinkの相対パスも合わせる。

```sh
git clone git@ghe.corp.yahoo.co.jp:jyoshida/skills.git ~/dev/skills
ln -s ../../../../dev/skills <Vaultの絶対パス>/30_Areas/ai/shared-skills
```

VaultのGitでsymlinkを復元済みなら `ln -s` は不要。Obsidianでの表示・検索はアプリ側で確認する。Dreamingの走査はsymlinkをたどらないため、共有本文はVaultの自動内省対象に含まれない。

Codexは `~/.codex/skills/<名前>` から正本へSkill単位のsymlinkを置く。標準Skill・プラグイン配布物は移さない。Codex以外のLLMで設定作業をした場合も、Codex向けの登録を省略しない。他ハーネス自身にSkillを登録する場合はその検出先を公式仕様・実機で別途確認する。Codexへのsymlinkだけでは他ハーネスへの登録にならない。

Skillを追加・移動・改名したら、次を実行してリンク先と検出を確認する。

```sh
node ~/dev/dotfiles/obsidian/link-skills.ts <Vaultの絶対パス> <Codex設定ディレクトリ>
```

引数省略時は `~/Documents/Obsidian` と `CODEX_HOME` または `~/.codex` を使う。この登録処理はdotfiles/install.sh → obsidian/install.shからも呼ばれ、個人Skillと `shared-skills/skills/` の両方を走査して実体へ登録する。同名重複や共有リンク切れがあれば書き込み前に停止する。既存の実ディレクトリ・異なるリンク先と競合したら上書きせず停止する。移設前にバックアップを取り、差分確認後にリンクへ置換する。CodexのSkill一覧で同名が重複していないことを確認し、反映されなければ再起動する。

TypeScriptスクリプトはsymlink経由の実行とimport時の非実行を検証する。VaultのSKILL.mdだけを移してscripts・references・agentsを取り残さない。

## 共通ボード

既定は `~/.agent-board`。別のLLMでも同じボード規約に従えば使える。保存先を変える場合はボードのinit/cleanupへ `--board-dir <絶対パス>` を渡し、委任へ解決済み絶対パスを含める。Codexのセッションやcwdから推測しない。複数タスクのIDは分け、同一タスクのマスターは1体にする。

ボードはGit管理せず、開始・終了時に完了と報告から7日経過したタスクだけ清掃する。必要な最終成果物はユーザー指定先、指定がなければ `~/Documents/AgentReports/<task_id>/` へ保存する。未完了・認証待ち・承認待ち・状態不明・別保存未確認は残す。利用しない間は掃除しない。TODOの持ち越し状態をボードへ移さない。

## 定期タスク

タスクには使用Skillとタスク固有の対象・認可・通知条件を記載し、Skill本文の処理手順を複製しない。Skill名・互換symlink・既存の作業フォルダは維持する。ローカルVaultとMCPが必要なタスクはMacローカルで実行する。定期タスクの変更は対応する管理画面・管理ツールで行い、ローカル設定ファイルの直接変更だけで反映済みとはしない。

移動・改名時は、旧登録が自分のSkillを指すsymlinkであることを確認して解除し、新しい正本を登録し直す。無関係なsymlinkや実ディレクトリは変更しない。登録スクリプトは古い登録を自動削除しない。
