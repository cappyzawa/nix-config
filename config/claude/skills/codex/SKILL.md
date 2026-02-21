---
name: codex
description: OpenAI Codex にタスクを委譲する。セカンドオピニオン、最新情報の確認、別視点での調査など、Codex の力を借りたいときに使用する。
allowed-tools: Bash(codex exec -s read-only:*)
---

# Codex

$ARGUMENTS の内容を Codex に委譲して実行する。

## 手順

1. $ARGUMENTS からタスクの内容を取得する
2. `codex exec -s read-only` でタスクを実行する
3. Codex からの結果をユーザーに報告する
