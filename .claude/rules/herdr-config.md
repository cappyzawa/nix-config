---
paths:
  - "config/herdr/**"
---

# Herdr Config

- `config/herdr/config.toml` を変更したら `herdr config check` で検証する。未知キーは
  "unknown config key" で exit 1 になるので、ok は全キー名が実在する証明になる
- check が読むのは `~/.config/herdr/config.toml`（make switch 済みの store symlink）で、
  作業ツリーの編集は見ない。編集中のファイルは XDG_CONFIG_HOME を差し替えて検証する:

```bash
TMP=$(mktemp -d) && mkdir -p "$TMP/herdr" && cp config/herdr/config.toml "$TMP/herdr/" && XDG_CONFIG_HOME="$TMP" herdr config check
```

- 稼働中の server への反映は make switch 後に `herdr server reload-config`
