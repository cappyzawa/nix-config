# Nix コーディング規約

## 原則

- **再現性がすべて**: 同じ入力から同じ出力が得られることを保証する。flake.lock を信頼し、impure な操作を持ち込まない。
- **宣言的に表現する**: 手続き的なスクリプトではなく、あるべき状態を宣言する。命令的な activation script は最後の手段。
- **コンポーザブルに設計する**: 小さく焦点を絞ったモジュールを組み合わせる。一つのファイルに詰め込まない。
- **実用主義**: Nix で全てを解決しようとしない。Homebrew cask が適切なら使う。完璧より動くことを優先する。

## Flake

- inputs は必要最小限にする。依存が増えるほど `nix flake update` の影響範囲が広がる
- `follows` で nixpkgs の重複を避ける
- flake の outputs はシンプルに保つ。複雑なロジックはヘルパー関数やモジュールに分離する

## モジュール・設定

- オプションには型 (`types.bool`, `types.str`, `types.listOf`, `types.attrsOf` 等) を必ず付ける
- `mkEnableOption` と `mkOption` で宣言的なインターフェースを作る
- `lib.mkDefault` で上書き可能なデフォルト値を設定し、host 固有の設定で `lib.mkForce` なしに変更できるようにする
- `with lib;` のスコープは最小限に。何がどこから来ているか追えなくなる
- 条件付きの config は `if-then-else` ではなく `lib.mkIf` で書く (if は条件の評価を option の解決より先に強制し、infinite recursion の典型因になる)
- `let ... in` で中間値に意味のある名前を付け、ネストを浅く保つ
- リスト操作には `map`, `filter`, `genAttrs`, `listToAttrs` を活用する。手続き的に組み立てない

## パッケージ追加の判断

- CLI ツールは `home.packages` (Nix) を優先する
- GUI アプリは `homebrew.casks` に追加する (Nix の darwin GUI サポートは不完全なため)
- プログラムに home-manager モジュールがある場合 (`programs.X`) はそれを使う。`home.packages` に直接入れるより設定が宣言的になる
- 静的な設定ファイルは `config/` に置き `xdg.configFile` でシンボリックリンクする

## スタイル

- フォーマットは `nix fmt` (nixfmt) に任せる。手動で整形しない
- `inherit` を使って冗長な `x = x;` を避ける
- `rec` attrset を避ける。`mkDerivation` では `finalAttrs:` パターン、それ以外は `let ... in` を使う (`rec` の自己参照は `overrideAttrs` の上書きに追従せず古い値を掴む)
- アトリビュートセットは関連するものをまとめ、空行で論理グループを区切る

## よくあるトラブルシューティング

- **infinite recursion**: `lib.mkDefault` / `lib.mkForce` の優先度衝突、または自己参照するモジュール。依存グラフを確認する
- **attribute not found**: inputs の `follows` ミス、またはオプション名のタイポ。`nix repl` で確認する
- **hash mismatch**: `outputHash` を持つ fixed-output derivation。`lib.fakeHash` で一度ビルドし、正しいハッシュに差し替える
- **flake が新しいファイルを見つけない**: `git add` し忘れ。ステージングすれば解決する
