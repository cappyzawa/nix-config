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
| `~/.claude/settings.json` | `config/claude/settings.json` (+ `hosts/<host>/claude-settings.json` + `~/.config/nix-config-local/claude-settings-secrets.json`) | jq マージ後、書き込み可能な実ファイルとしてコピー（symlink ではない） |
| `~/.claude/CLAUDE.md` | `config/claude/CLAUDE.md` symlink経由の`config/agents/AGENTS.md` (+ `hosts/<host>/claude-memory.md`) | 連結し、Claude専用の `@~/.claude/CLAUDE.local.md` importを末尾へ付けてコピー |
| `~/.claude/rules` | `config/claude/rules` | ディレクトリ symlink |
| `~/.claude/skills` | `config/claude/skills` | ディレクトリ symlink |
| `~/.claude/agents/*` | `config/claude/agents` (あれば) + `hosts/<host>/claude-agents` | 存在するディレクトリの中身を個別ファイルで symlink |

## settings.json のマージ規則

- base (`config/claude/settings.json`) と host (`hosts/<host>/claude-settings.json`) を `$base * $host` で deep merge する
- 最後に `~/.config/nix-config-local/claude-settings-secrets.json` があれば重ねる
  - secret（MCP token など）の置き場で、この public repo には値を置かない
  - Claude Code は settings の `env` を自身のプロセス環境へ入れてからプレースホルダを展開するので、MCP token はここに置けば届く
  - skill 経由の Codex も Claude の Bash から起動するのでこの env を継承する（ターミナルから直に叩く Codex だけは shell 側の export が必要）
  - shell rc には置けない（desktop app は launchd 起動で rc を読まず、プレースホルダが未展開のまま server へ渡る）
  - activation 時にローカルファイルから読むので、値は world-readable な Nix store に入らない
  - 重ねるのは `env` だけで、他のキーがあれば activation を止める（`permissions` の緩和や hook 差し替えが紛れ込むのを防ぐ）
  - mode が 400 / 600 でなければ値を出さずに activation を止める
  - 生成物は staging を `$CLAUDE_DIR` 内に作って `chmod 600` してから rename する。異常終了と dry-run では trap が staging を消す
  - 実値を持つファイルなので `permissions.deny` の `Read(...)` に加える
  - ただし `deny` は誤操作除けであって隔離ではない（`Bash(cat:*)` が allow にあり、token は Claude のプロセス環境から全子プロセスへ継承される）
- 生成後に、MCP 定義のプレースホルダが settings の `env` で解決されているかを検査し、未解決の変数名を switch 出力に出す
  - 未解決のプレースホルダは文字列のまま server へ渡り、remote API が unauthorized を返す。接続不良に見えて原因が分かりにくいため名前を出す
  - 検査自体の失敗は報告するだけで switch を止めない
- `permissions.allow` / `permissions.deny` は上書きでなく配列連結
- **symlink ではなく実ファイルとしてコピーする**。Claude Code が runtime に書き込む値（`voice` など）で git working tree を汚さないため
- コピーは毎回上書きなので、runtime が書き込む値を switch 後も残したいなら base（または host）側に宣言しておく必要がある。宣言していないキーは switch のたびに消える
  - 例: `/plugin install`（user scope）が書く `enabledPlugins`。宣言していないと switch で有効化フラグが消え、plugin が無効化される

## このプロジェクトの規約

- 共通 instructions と共通 skill は `config/agents/` に置く。rule と Claude 固有の設定は `config/claude/` 配下に置く
- 新規ディレクトリ・ファイルを作った場合は `git add` してから `make check` すること（flake が未追跡パスを参照できないため）
- host 固有の上書きは `hosts/<host>/` に置く（`claude-settings.json` / `claude-memory.md` / `claude-agents/`）
