# Go コーディング規約

## 原則

- **優先順位は Clarity > Simplicity > Concision > Maintainability > Consistency**。衝突したらこの順で裁定し、同点なら Consistency を取る。Consistency の効力は package 内 > チーム > コードベース全体の順に強い。
- **least mechanism を選ぶ**: 言語組み込み → 標準ライブラリ → 準標準ライブラリ (`golang.org/x/*` や `google/go-cmp` のようにエコシステムで準公式の地位を持つもの) → その他の外部依存の順に、要求を満たす一番手前の手段で解く。複雑さは足すのは簡単で後から取り除くのは難しい。
- **不変条件ごとに一番安いエンフォース手段を選ぶ**: 階段は「変更が別の力で抑止されているなら何もしない → 命名 → コメント → defined type (`type UserID string`。ただし untyped constant の代入は止まらないので `f("a", "b")` のような取り違えは防げない) → package 境界 + unexported field + constructor → `go vet` / staticcheck → codegen で手書きの余地を消す」。ただしこれはコストの階段であって強度の階段ではない。**コンパイラが強制する段 (unexported field + package 境界) が Go の実質的な天井**で、analyzer はそれを補うものであって上位ではない (suppress できるし、library の消費者のビルドでは走らない)。analyzer の自作は、既存 analyzer で表せずかつ CI で全消費者に強制できるときだけ。
- **zero value の穴を前提に設計する**: `var x pkg.T` は他 package から常に書けるので、constructor を通ったことを型は保証しない。取れる手は (a) zero value を有効な既定値にする (`sync.Mutex` のようにフィールドの zero がそのまま正しい型か、`sync.Map` / `http.Transport` のようにメソッド側で lazy init する型)、(b) zero value を無効と決めて使用時に検出する (nil map への write が panic するのと同型) の 2 つだけ。(a) を既定にし、(b) を選ぶなら検出点を決めて書く。**zero value が無効なのに検出もしない型を作らない**。
- **parse, don't validate は package 境界までしか運べない**: 外界の値は境界で一度 parse し、以降は unexported field を持つ型で運ぶ。ただし zero value で偽装できるため「この型を受け取った = 検証済み」を証明できるわけではない。その残りは受け取り側の再検証ではなく型自身に持たせる (上の zero value の項)。
- **誤用しにくさは命名ではなく型で作る**: パス脱出を防ぐなら呼び出し側の律儀さに頼る検証引数を足すのではなく、`os.Root` のように脱出経路を持たない型を新設する。
- **既存プロジェクトの確立したパターンがこの規約に優先する**: interface の配置、assertion の流儀、エラー方針が既に決まっているコードベースでは、そちらに合わせる。この規約は新規に決めるときの既定であって、動いているコードを書き換える理由にはならない。
- **同期 API を既定にする**: 呼び出し側は必要なら自分で goroutine 化できるが、呼び出された側が勝手に足した並行性を呼び出し側が取り除くことはできない。goroutine の起動は内部実装に隠し、channel や future を返す非同期 API を先回りで作らない。

## API / package 設計

- interface は**利用側の package で定義する**。実装側に置いてよいのは複数の実装が並存する場合だけで、mocking のためだけの interface を実装側に置かない
- interface を先回りで作らない。`Service` / `Repository` のような抽象名の interface を、必要が生じる前に切らない
- 「accept interfaces, return structs」を定型句として適用しない。呼び出し元が具象型を知るべきでなく複数バックエンドが並存する API (`crypto.Signer` 型) では、interface を返すのが正しい
- **振る舞いを完全に規定できる interface だけ切る**。薄すぎる interface は埋め込んだ側が意図せず満たしてしまい実行時に壊れる (protobuf v1 の `proto.Message` の事故)。narrowing をどこで止めるかは、メソッド数ではなく副作用の所有権で決める (`io.WriteCloser` で止めると `Close()` を呼ぶ責任が曖昧になる)
- 1 メソッドの interface を定義したくなったら、関数型 (`type Option func(*T)`) で足りないか先に問う。型宣言・フィールド・constructor が丸ごと不要になる
- 公開 struct のフィールドレイアウトは将来にわたって固定される。進化させたい型は具象 struct を公開せず、逃げ道になるメソッドを持たせる。ただの値の袋 (config・DTO・レスポンス型) は公開 struct のままでよい
- 引数が増えたら、多くの呼び出し側が指定するなら option struct、まれにしか指定しないなら functional options。**option struct に `context.Context` を含めない**
- functional options を採るのは「API が今後拡張される」「引数が自己文書化されている必要がある」「nil を渡されても壊れない」「既定動作が単純であるべき」が揃うとき。オプションが 3〜4 個以下で拡張予定も無いなら間接層が増えるだけなので、直接引数か option struct にする
- **`util` / `common` / `base` を作らない**。生まれる原因は import cycle 回避なので、対策は「呼び出し元にコードを戻して重複を許容する」か「関連するコードを 1 package に統合する」(`net/http` の `client.go` / `server.go` / `transport.go` モデル) のどちらかで、package を増やすことではない
- package 名は import 先の全呼び出し箇所で永続的な prefix になる (`http.Get`)。呼び出し側から見た形で評価し、内部構成を名前に漏らさない
- **まず 1 package、分割は最後**。Go には public/private の 2 値しか無く中間可視性が無いので、package 分割は他言語より公開範囲への影響が大きい決断になる
- `internal/` はツールチェインが強制する唯一の可視性制限。命名規約やコメントによる自己規律と同列に扱わない
- getter に `Get` prefix を付けない (`Counts()` であって `GetCounts()` ではない)。計算コストが高いなら `Compute` / `Fetch` で呼び出し側に負荷を伝える
- receiver 型は同じ型の全メソッドで統一する。mutate する・非コピー可能なフィールドを持つ・大きい型は pointer receiver、迷ったら pointer receiver
- channel は送信専用・受信専用の方向を型で明示し、所有権を伝える
- `package main` は composition root に留める。flag 解析・接続確立・トップレベルの組み立てだけを置き、ロジックは import 可能な package に出す
- **`func main()` にロジックを直書きしない**。`main` はテストから呼べないので、`func run(ctx context.Context, args []string, stdout, stderr io.Writer) error` のような名前付き関数に落として `main` は終了コードへの変換だけにする。ただし `run` が実 I/O を張る場合は関数を切っただけでは `run` 自体はテスト不能なままで、そこまでテストしたいなら clock・接続・signal を差し替え可能にする依存注入が別途要る

## エラー

- exported 関数は具体的なエラー型ではなく `error` で返す。nil の具体型 pointer を interface に包むと非 nil になる
- **error を文字列一致で判定させない**。`errors.Is` / `errors.As` で判定できる sentinel か構造化エラー型にする
- `%w` と `%v` を使い分ける。呼び出し側に構造的な検査をさせたいなら `%w`、内部構造を隠したいなら `%v`。`%w` は原則メッセージ末尾に置き、well-known な sentinel をラップするときだけ先頭に置いて種別を即伝える
- ラップで足すのは**新しく分かる文脈だけ**。下位のエラーが既に持つ情報を繰り返さない
- error メッセージは小文字始まり・末尾に句読点なし (上位が連結するため)
- **「ハンドルする」とはエラーを検査して 1 つの決定をすること**。log して return するのは決定を 2 回下しており、「1 エラー 1 ハンドリング」への違反。呼び出し元に返す error をその場でログしない
- 公開した sentinel error は恒久的に公開 API の一部になり、呼び出し元に等価比較のためだけの import を強制する。判定可能性のために必要なときだけ公開する
- 振る舞いで判定するなら型でも値でもなく interface assertion を使う (`interface{ Temporary() bool }`)
- **エラー処理を足す前に、エラーが起きうる形自体を消せないか考える**。`bufio.Reader` の `io.EOF` 分岐は `bufio.Scanner` の bool ループにすると構造的に消える
- 早期 return でエラーを処理し正常系を `else` にネストしない。ただし二値分岐を `switch` に形式化するのは過剰なので、`else` そのものを忌避しない
- エラーを `_` で捨てるなら安全な理由をコメントに書く
- 設定・flag の誤りは main まで伝播させて人間向けメッセージで終了する。深部で `log.Fatal` / `os.Exit` を呼ばない (defer が飛んで cleanup が走らず、その関数がテストから呼べなくなる)
- `panic` は API の誤用と、続行するほうが危険な不変条件違反にだけ使う。並行コードでは panic 中の defer がデッドロックしたり壊れた状態を伝播するので、goroutine の内側では特に避ける
- recover は原則使わない。例外は package 内部の実装詳細として panic-recover を使い、**package 境界を越える前に必ず error へ変換する**場合だけ
- `pkg/errors` を新規採用しない。stack trace 収集以外の用途は標準の `%w` / `errors.Is` / `errors.As` / `errors.Join` で足りる

## 並行処理

- goroutine は**今まさに並行実行すべき作業があるとき**に起動する。将来のリクエストに備えて事前に何本も用意する設計を既定にしない
- **worker pool を先回りで導入しない**。goroutine は初期スタックが小さく起動コストが低いのでアイドル worker を維持する優位性は薄く、デバッグとプロファイリングを複雑にするだけになりやすい
- 複数 goroutine が同じメモリへ排他アクセスするだけなら mutex を使う。channel は値そのもの (接続・トークン・バッファ) の受け渡しと所有権の移譲に使う。共有変数への操作を channel で「通知」するだけの設計は share memory by communicating を満たさない
- **`sync.Cond` を新規コードで使わない**。spurious wakeup・signal の取りこぼし・waiter 間の starvation・cancellation への応答遅延を抱えるので、buffered channel をセマフォや通知として使う
- **goroutine を起動したら、終了する経路 (正常完了 or cancellation) を起動元で説明できること**。説明できないなら起動しない。「送るが誰も受け取らない」「受け取るが誰も送らない」channel 操作はブロックしたまま漏れ、GC も回収しない
- pipeline の各 stage は**自分が所有する出力 channel だけを close する**
- 下流が早期 return しうる pipeline では、上流の送信を `select` で done channel と競合させ、cancellation 時に送信でブロックしないようにする
- cancellation は close による broadcast で伝える。close された channel からの受信は即座に成功するので、待機している goroutine 数によらず一括で解除できる
- buffered channel の容量を「ちょうど収まるはず」の数に決め打ちして、cancellation やブロック回避の代わりにしない。送受信の個数が変わると破綻する
- cancellation は親から子への一方向にする。子が親をキャンセルできる経路を作らない
- 単純な fan-out で待つだけなら `sync.WaitGroup` の `Go` メソッド (Go 1.25+)、エラー集約と cancellation 伝播が要るなら `errgroup`。**WaitGroup + エラー channel を手書きしない** (cancellation の伝播漏れを作り込む)
- worker pool を作らないことと並行数を制限しないことは別。上限が要るなら `errgroup.SetLimit` か buffered channel のセマフォで、goroutine を使い回さずに数だけ絞る
- 可変な package グローバル変数を持たない。データ競合とテスト間の状態漏れの温床になる

## context

- `context.Context` は関数の第一引数として明示的に渡す。struct のフィールドに埋めると、その値がどのリクエストスコープに属するのか呼び出し箇所から追えない
- `context.Background()` を呼んでよいのは main / init / test / リクエストの最上位だけ。深部で新しい Background を作ると上位の cancellation とデッドラインが伝播しなくなる
- `WithValue` で運ぶのはリクエストスコープの値だけ。必須パラメータを Context 経由で渡すと依存がシグネチャから消える
- cancel の権限は `WithCancel` / `WithTimeout` を呼んだ側だけが持つ。Context に `Cancel()` を生やして子から親を止めない

## 型とデータ

- nil slice と空 slice はほとんどの場面で等価。ローカル変数は nil 初期化を優先し、空判定は `== nil` ではなく `len()` で行う
- **標準ライブラリの新しい API を古い書き方で置き換えない**: 複数エラーの集約は `errors.Join` (1.20)、slice/map 操作と `min`/`max` は `slices` / `maps` (1.21)、ゼロ値フォールバックは `cmp.Or` (1.22)、パス脱出耐性は `os.Root` (1.24)。訓練データの古い idiom に引きずられて手書きしない
- **Go 1.22 以降、for ループの変数はイテレーションごとに再生成される**。goroutine やクロージャのために `v := v` と再束縛しない。このセマンティクスを決めるのはインストール済み toolchain ではなく **`go.mod` の `go` ディレクティブ**なので、`go` が 1.21 以前の module を触るときだけ従来の再束縛が要る

## 実装の落とし穴

いずれもコンパイルも vet も通り、テストでも顕在化しにくい。

- **sub-slice への `append` はバッキング配列を共有する**。`base[:2]` に `append` すると `base[2]` が書き換わる。sub-slice を返す・受け取る API では full slice expression (`base[:2:2]`) で capacity を切り、共有を断つ
- **ループ内の `defer` はループごとに走らない**。関数が return するまで積み上がるので、反復のたびに獲得するリソースは `defer` ではなくループ本体で解放するか、1 反復を関数に切り出す
- **`time.Time` を `==` で比較しない**。`==` は monotonic reading と location まで含めて比較するため、同じ時刻でも `t == t.UTC()` は false になる。同一時刻の判定は `Equal` を使う

## generics

- 値に対してやりたいことがメソッド呼び出しだけなら、型パラメータではなく interface を使う。型パラメータはメソッドの多態性のための機構ではない
- 型ごとに**実装内容そのものが異なる**なら interface。generics が適するのは、同じコードが型に依存せずそのまま複数の型で動く場合だけ
- 型だけが違う同じロジックのコピーが複数箇所に出てから型パラメータ化を検討する。使えるからという理由で先に generics 化しない
- 抽象的なアルゴリズムのためではなく実際の要件のために使う。エラー処理やテストアサーションを generics で DSL 化しない

## 依存と後方互換

互換性の項目は**外部に利用者がいる package / module** が対象。単一 binary で外部消費者がいないなら、公開 API の削除や `/v2` の判断はそもそも対象が無いので持ち込まない。

- 依存を追加する前に、issue tracker の未解決バグの滞留・直近のコミット活動・release cadence でメンテ状態を測る。テストが無いリポジトリは品質の下限すら分からず、広範な採用実績はこの確認を代替しない
- 推移的依存のツリー全体を把握する。間接依存の欠陥は直接依存の欠陥と同じだけ効く。脆弱性は目視ではなく `govulncheck ./...` で見る (実際に到達するコードパスだけを報告する)
- **公開 interface にメソッドを追加すると既存の実装が全てコンパイルエラーになる**。拡張は新メソッドだけの別 interface を定義し、呼び出し側で type assertion により対応の有無を判定させる。逆に外部実装を最初から許さないなら、unexported method を 1 つ埋めて interface を封印しておくとメソッド追加権を保持できる
- 公開 API・型の削除と、同じ入力に対する挙動の変更は互換を壊す。追加・内部最適化・バグ修正は互換とみなす
- 破壊的変更は同じ import path で挙動を変えず、module path に `/v2` を付けて別モジュールとして出す

## テスト

- 失敗メッセージは対象の関数名と入力を含める (`Foo(input) = got, want want`)。got を want より先に書く
- **assertion library を自作しない**。判定と失敗メッセージ生成を混ぜると文脈が失われる。go-cmp (`github.com/google/go-cmp/cmp`) と `fmt` を使い、helper は値やエラーを返して呼び出し元の Test 関数で判定する
- 構造体の比較は go-cmp の `cmp.Equal` / `cmp.Diff` を使う (標準の `cmp` パッケージとは別物)。差分が読める出力になり、`cmpopts` で比較セマンティクス (無視するフィールド・許容誤差・順序) を明示できる。unexported field があると go-cmp は panic するので `cmpopts.IgnoreUnexported` で明示的に許可する
- 自分が所有していない package の出力 (`json.Marshal` の結果等) を文字列一致で比較しない。意味的に重要な部分だけをパースして比較する
- table-driven test のケース名はテストデータの内側に持たせ (struct の name フィールドか map のキー)、`t.Run` に渡す。各ケースの struct literal は field 名を明示する
- 1 つの失敗で止めず `t.Error` で全ての不一致を報告する。`t.Fatal` は後続の検証が無意味になる場合だけ
- 自分で失敗を報告する helper (fixture 構築や `MustXxx` 系) では `t.Helper()` を呼び、失敗の帰属を呼び出し元に移す
- クリーンアップは `t.Cleanup` に登録する
- `t.Setenv` / `t.Chdir` を呼んだテストは `t.Parallel()` にできない (呼ぶと panic する)。プロセス全体の状態に触るテストは並列化を諦めるか、その依存を引数に出す
- **並行コードのテストで実時間の sleep を使って同期しない**。`testing/synctest` の bubble で仮想クロックを確定的に進める (Go 1.24 で実験導入、1.25 で正式)
- 統合テストでは client 側を手でモックせず実際の transport を通し、backend 側だけ test double にする
- 期待する出力を事前に列挙できない性質 (往復変換の不変条件、panic しない、valid な入力に valid な出力) は table-driven ではなく `go test -fuzz` で検証する。シードコーパスは `f.Add` で明示的に足す

## 検証

- コードを変更したら `go build ./... && go vet ./... && go test -race ./...` が通ることを確認する。`.golangci.yml` や `staticcheck.conf` があればそれも回す
- race detector は実行時に実際に踏まれたパスの競合しか検出しない。単体テストだけで並行バグが無いことにせず、並行部分を実際に踏むテストで `-race` を有効にする
