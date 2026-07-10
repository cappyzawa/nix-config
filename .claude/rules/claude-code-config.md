---
paths:
  - "nix/home/default.nix"
  - "config/claude/**"
  - "hosts/*/claude-memory.md"
  - "hosts/*/claude-settings.json"
---

# Claude Code 設定 (Home Manager)

## 管理方式

`programs.claude-code` モジュールは使っていない。`nix/home/default.nix` の
`home.activation` にある命令的スクリプトで `~/.claude/` を組み立てる。
settings.json を書き込み可能な実ファイルにしたい（Claude Code が runtime に
toggle 状態を書き込む）ことと、host 固有のマージを柔軟に行いたいことが理由。

activation ブロック (`nix/home/default.nix`):

- `updateClaudeMcp` — `~/.claude.json` の `.mcpServers` だけを jq で置換（他キーは保持）
- `installClaude` — claude CLI が無ければ公式インストーラで導入（CLI が自己更新するので毎回は入れ直さない）
- `setupClaude` — 下記の設定ファイル群を生成・リンク

## setupClaude が生成する各ファイル

| 対象 | ソース | 反映方法 |
|---|---|---|
| `~/.claude/settings.json` | `config/claude/settings.json` (+ `hosts/<host>/claude-settings.json`) | jq マージ後、書き込み可能な実ファイルとしてコピー（symlink ではない） |
| `~/.claude/CLAUDE.md` | `config/claude/CLAUDE.md` (+ `hosts/<host>/claude-memory.md`) | 連結してコピー |
| `~/.claude/rules` | `config/claude/rules` | ディレクトリ symlink |
| `~/.claude/skills` | `config/claude/skills` | ディレクトリ symlink |
| `~/.claude/agents` | `config/claude/agents` (+ `hosts/<host>/claude-agents`) | host 固有があれば個別ファイルを symlink でマージ、無ければディレクトリ symlink |

## settings.json のマージ規則

- base (`config/claude/settings.json`) と host (`hosts/<host>/claude-settings.json`) を `$base * $host` で deep merge する
- `permissions.allow` / `permissions.deny` は上書きでなく配列連結
- **symlink ではなく実ファイルとしてコピーする**。Claude Code が runtime に書き込む値（`voiceEnabled` など）で git working tree を汚さないため
- コピーは毎回上書きなので、runtime が書き込む値を switch 後も残したいなら base（または host）側に宣言しておく必要がある。宣言していないキーは switch のたびに消える
  - 例: `/plugin install`（user scope）が書く `enabledPlugins`。宣言していないと switch で有効化フラグが消え、plugin が無効化される

## このプロジェクトの規約

- 設定ファイルは `config/claude/` 配下に置く（rules / skills / agents / settings.json / CLAUDE.md）
- 新規ディレクトリ・ファイルを作った場合は `git add` してから `make check` すること（flake が未追跡パスを参照できないため）
- host 固有の上書きは `hosts/<host>/` に置く（`claude-settings.json` / `claude-memory.md` / `claude-agents/`）
