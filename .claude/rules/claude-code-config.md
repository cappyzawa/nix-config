---
paths:
  - "nix/home/default.nix"
  - "config/claude/**"
  - "hosts/*/claude-memory.md"
---

# Claude Code 設定 (Home Manager)

## モジュールの所在

`programs.claude-code` は home-manager 本体に同梱されている (`modules/programs/claude-code.nix`)。
別の flake input は不要。

## 利用可能なオプション

- `settings` - JSON 設定 (permissions, hooks, env, vim, attribution, statusLine など)
- `memory` - CLAUDE.md (`memory.text` を使用。共通部分は `builtins.readFile` で読み込み、ホスト固有は `lib.mkAfter` で追記)
- `mcpServers` - MCP サーバー設定 (**`package` が必須**。ラッパーで `--mcp-config` を注入するため)
- `enableMcpIntegration` - `programs.mcp.servers` との統合

### ファイル系オプション (inline と Dir は排他)

| inline | Dir | 配置先 |
|---|---|---|
| `rules` | `rulesDir` | `.claude/rules/` |
| `commands` | `commandsDir` | `.claude/commands/` |
| `skills` | `skillsDir` | `.claude/skills/<name>/SKILL.md` |
| `agents` | `agentsDir` | `.claude/agents/` |
| `hooks` | `hooksDir` | `.claude/hooks/` |

## このプロジェクトの規約

- `*Dir` パターンを使い、`config/claude/` 配下にファイルを置く
- 新規ディレクトリを作った場合は `git add` してから `make check` すること（flake が未追跡パスを参照できないため）
