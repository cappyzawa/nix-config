## AWS 操作

- READ 系（describe, list, get など）は AWS MCP サーバー (`aws`) を使うこと
  - 環境は profile で切り替える。`call_aws` のコマンド内に `--profile <name>` を付ける（利用可能 profile は `aws configure list-profiles` で確認するか、ユーザーに確認）
  - `suggest_aws_commands` は profile を扱わないため、提案コマンドに自分で `--profile` を補う
  - production 環境の profile を使うときは事前にユーザーの合意を得る
- WRITE 系（create, update, delete など）は Bash の `aws` コマンドを使うこと
  - MCP サーバーは `READ_OPERATIONS_ONLY=true` で制限されているため write はエラーになる
