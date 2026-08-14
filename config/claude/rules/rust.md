---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

# Rust コーディング規約

## 原則

- **誤用しにくい API を作る**: 正しい使い方が自然で、間違った使い方がコンパイルエラーになるよう設計する。newtype、type state、builder パターンを活用する。
- **コンパイル時にできることは実行時にやらない**: 型システム、const、derive マクロで保証できることにランタイムチェックを使わない。
- **所有権を先に設計する**: コードを書く前にデータの所有権と借用を設計する。clone は最後の手段。
- **エラーハンドリング**: ライブラリには `thiserror` で精密な型付きエラー、アプリケーションには `anyhow`。`?` で伝播し、テスト以外で `.unwrap()` を避ける。エラーメッセージ (`Display` / `#[error("...")]`) は小文字始まり・末尾に句読点を付けない (上位が `: ` で連結するため)。
- **unsafe は最小限**: `unsafe` ブロックは小さく隔離する。安全性の不変条件を `// SAFETY:` コメントで文書化する。安全な抽象で包んで呼び出し側に unsafe を漏らさない。

## API 設計

- 公開 API の表面は最小限にする。公開する必要がないものは `pub` にしない
- 引数には具体型より trait bound を取る (`&str` > `&String`、`impl AsRef<Path>` > `&PathBuf`)
- 戻り値には `impl Trait` を使い実装詳細を隠す (ただし trait object が必要な場合は `Box<dyn Trait>`)
- 戻り値を無視するとバグになりそうな関数には `#[must_use]` を付ける
- semver を壊す変更に注意する。構造体には `#[non_exhaustive]` を検討する
- 命名は API Guidelines の変換規約に従う: `as_` は無コストの借用ビュー、`to_` は高コストの複製、`into_` は所有権の移動。getter に `get_` prefix を付けない (`fn len()` であって `fn get_len()` ではない。clippy はこれを検出しない)

## 型とデータ

- 不正な状態を表現不可能にする。`Option` のネストや bool フラグの組み合わせより enum を使う
- newtype で意味のある型を作る (`struct Meters(f64)` > 生の `f64`)
- 適切な場合は標準トレイト (`Debug`, `Clone`, `PartialEq`, `Display`) を derive する
- `Cow<'_, str>` はアロケーションが必要かどうか呼び出し側に依存する場合に使う

## 実装スタイル

- プロジェクト既存のパターン (エラーハンドリング、ロギング、モジュール構成) に従う
- 単純なジェネリック境界には引数位置の `impl Trait` を使い、複雑な場合は `where` 句を使う
- 明瞭性が向上する場合、手動ループよりイテレータとコンビネータを優先する
- derive マクロでボイラープレートを減らす。手で書くより正確で保守しやすい
- 依存は慎重に選ぶ。依存を追加する前に、そのクレートの品質・メンテナンス状況・依存の深さを考慮する
- public なアイテムには doc コメント (`///`) を書き、`# Examples` セクションで使い方を示す。doctest はテストでもありドキュメントでもある

## モジュール構成 (特に binary crate)

- **内部詳細を top-level の `pub(crate)` に漏らさない module tree を組む**。これがモジュール分割の主眼。あるモジュール専用の補助関数・型 (そこからしか呼ばれないもの) は top-level の兄弟モジュールに出さず、親モジュールの子モジュール (`mod parent { mod child; }`、ファイルは `parent/child.rs`) にして `pub(super)` に閉じる。兄弟モジュール間で共有が必要になったときだけ `pub(crate)` へ上げる。
- **「小さい main」自体を目的化しない**。狙いは main をテスト不能なまま放置しないこと。`#[tokio::main] fn main` はテストから呼べないので、ロジックは名前付き関数 (`run()` 等) やモジュールへ押し出し、テストが到達できる単位にする。main は wiring と委譲だけに絞る。
- ただし `run()` が実 I/O (gRPC 接続・HTTP・signal 等) を張る場合、モジュール分割だけでは `run()` 自体はテスト不能なまま。純粋ロジック (計算・変換・状態遷移・batching・backoff 等) を副作用から切り離して隣接テストを付けるところまでが分割の効果で、`run()` までテストしたいなら依存注入 (forwarder/clock/signal を差し替え可能にする) が別途必要、という切り分けを持つ。
- 「常に 3 行 main」は誤解。実在の Rust プロジェクトでも main.rs が数百行のことはある。重要なのは行数でなく、内部実装を facade の裏に閉じ込め公開表面を最小にすること。
- **lib+bin 分割を既定にしない**。bin-only + よく切ったモジュール + `#[cfg(test)]` で `run()`/`run_with()` を含め十分テストできる (bin crate も `cfg(test)` でコンパイルされる)。別 crate がロジックを再利用する具体的見込みが出た時に lib へ切り出せばよく、retrofit は behavior-preserving で安い。公開 API が製品・複数 bin でロジック共有・ハウススタイル統一、のいずれかが理由になる時だけ先回りして lib+bin にする。

## テストの流儀

成熟した crate によく見られる流儀。「必ずこうする」規則ではなく方針として扱う。**多くが library / 公開 API 中心の crate 由来で、application / binary crate には対象が無い項目がある**。まず crate 種別によらず効くものを挙げ、次に公開 API を持つ crate 向けを分ける。

**crate 種別によらず効く**

- **観測可能な契約を利用者が見る高さでテストし、残りはコンパイラに検査させる**。型で保証できるものにテストを重ねない。app/bin では「観測可能な契約」= 出力・ログ・exit code・副作用。
- **境界をモックせず実物を通す**。固定入力を基本にする (encode/decode の対があれば round-trip)。統合の継ぎ目こそ実物で通す価値が高い。
- **汎用モックや巨大 assertion DSL を避け、目的特化の小道具 + 手書き helper で契約を直接表現する**。依存ゼロの意味ではない (trybuild/serde_test のような特化ツールは積極的に使う)。
- **環境差を黙って吸収せず明示する**。feature / OS の違い、時刻・ネットワーク・FS の非決定性を、条件としてコードやコメントに書く。
- **white-box な検証は in-crate に置く**。非同期の配線、時計/IO/signal の注入、内部カウンタの検査など公開 API では観測できない振る舞いは、公開表面を `pub` 汚染してまで `tests/` に出さず、`#[cfg(test)]` の in-crate テストに置く。テスト容易性のために公開 API を広げない。

**公開 API を持つ crate 向け (application / binary には対象が無いことが多い)**

- **公開 API は外から叩く**。integration test (`tests/*.rs`) は各ファイルが別 crate としてコンパイルされるのでブラックボックス性がある。大規模なら serde の `test_suite` のように専用 test package を切る。ただし「公開 API だけでテストできる = 契約が十分」とは言えない (内部不変条件・性能は別)。**app/bin での対応物はプロセス e2e** — バイナリを起動して stdout/stderr/exit/副作用を見る。`env!("CARGO_BIN_EXE_<bin>")` + `std::process::Command` で dev-dep ゼロで書けるので、`assert_cmd` / `trycmd` の追加を理由に見送らない。純関数のテストは「その関数がどこで呼ばれるか」を固定しないので、配線・呼び出し位置を直す変更では回帰が素通りする。
- **誤用を compile-fail でテストする** (`trybuild`: `tests/ui/*.rs` + 正規化した `*.stderr` golden)。何でも compile-fail にはせず、狙ったエラーメッセージ・誤用 UX と診断の span 品質 (誤った token の直下に出るか) に限定する。**公開 API やマクロを持つ crate 用**。
- **doctest で公開 API の代表例を docs と同期させる**。すべての doc block がテストである必要はない。**公開 API がある crate 用** — app/bin の使い方は `--help` / README に置く。

## 検証

- コードを変更したら `cargo clippy --all-targets --all-features -- -D warnings` で指摘が無いことを確認する
