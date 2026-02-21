## AWS 操作

- READ 系（describe, list, get など）は AWS MCP サーバー (`aws-aegs-staging`, `aws-aegs-production`) を使うこと
- WRITE 系（create, update, delete など）は Bash の `aws` コマンドを使うこと
  - MCP サーバーは `READ_OPERATIONS_ONLY=true` で制限されているため write はエラーになる
