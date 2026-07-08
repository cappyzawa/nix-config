---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
---

# Terraform コーディング規約

## 原則

- **再利用可能なモジュール**: モジュールは小さくコンポーザブルに。入出力の契約を明確にする。
- **暗黙より明示**: provider とモジュールのバージョンを固定し、全ての variable に型と validation を宣言する。
- **デフォルトで安全**: IAM は最小権限、暗号化は有効、明示的に要求されない限りパブリックアクセスは禁止。
- **DRY な構成**: locals、variables、modules で繰り返しを避ける。キーに意味がある場合は `count` より `for_each` を使う。

## コードの書き方

- プロジェクト既存の命名規則に従う。なければ全識別子に `snake_case` を使う
- 全ての variable と output に `description` を付ける
- 意味のある場合は variable に `type` と `validation` ブロックを追加する
- 複数の類似リソースには `for_each` (maps/sets) を使う。`count` は単純な on/off トグルのみ
- `dynamic` ブロックは控えめに。構造が固定なら明示的なブロックを優先する
- 全リソースに最低限 `Name` と `ManagedBy = "terraform"` をタグ付けする
- 関連リソースは同じファイルにまとめ、論理的に異なる関心事は別ファイルにする
