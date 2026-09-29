## AWS 操作

- `aws` CLI（Bash）で操作する
- 環境は profile で切り替える。コマンドに `--profile <name>` を付ける（利用可能 profile は `aws configure list-profiles` で確認するか、ユーザーに確認）
- production 環境の profile を使うときは事前にユーザーの合意を得る
- READ 系（describe, list, get など）の多くは settings.json で allow 済み。WRITE 系（create, update, delete など）は都度承認になるので、実行前に意図をユーザーに確認する
