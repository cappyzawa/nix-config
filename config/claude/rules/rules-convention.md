---
paths:
  - ".claude/rules/**"
  - "config/claude/rules/**"
---

# Rules Convention

- frontmatter のキーは Claude Code 公式仕様 (https://code.claude.com/docs/en/memory.md#path-specific-rules) に従い `paths:` を使用すること
- 特定ファイル編集時のみ適用したい場合は `paths:` でスコープを絞ること
- `paths:` 未指定の場合はセッション全体にロードされる。全セッションで常時参照したい共通ルールはあえて未指定でも構わない
- いずれの場合も CLAUDE.md のインデックスを合わせて更新すること
