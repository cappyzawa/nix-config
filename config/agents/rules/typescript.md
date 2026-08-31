# TypeScript コーディング規約

## 原則

- **型に仕事をさせる**: 型はドキュメントではなくロジックである。不正な状態をコンパイルエラーにする。
- **不変条件ごとに一番安いエンフォース手段を選ぶ**: 階段は「変更が別の力で抑止されているなら何もしない → コメント / 命名 → eslint / tsconfig で機械的に落とす → 境界の parse 関数 (schema 検証) → discriminated union で不正状態を表現不能に → branded type → module 境界で非公開 → 型レベルプログラミング」。下の段で足りる不変条件に上の段を使わない。
- **parse, don't validate**: 検査は boolean を返さず、検査済みであることを表す狭い型の値を返す。validate は検査した知識が呼び出し元に残らないため、後段で `!` や再検査を強いる。parse なら知識が型に載り、失われない。TS の型は erase されるので直列化境界 (API 応答・JSON・env・form data) では特にこれが効く — 境界で一度 parse (schema 検証) して `unknown` から型に落とし、以降は型を信じる。`as` キャストは「検証したふりの witness」であり parse の代替にしない。失敗しない total な変換に throw や Result を付けて parser に偽装しない。
- **推論を信頼する**: TypeScript の型推論は強力。明示的な型注釈は公開 API の境界と、推論が不十分な箇所にのみ書く。内部コードに冗長な型注釈を付けない。
- **`any` は型システムの穴**: `unknown` + type guard で代替する。どうしても避けられない場合は理由付きで `// eslint-disable` を付ける。
- **常に strict モード**: tsconfig.json の `strict: true` は必須。新規に tsconfig を書くときは `noUncheckedIndexedAccess` と `verbatimModuleSyntax` も検討する (どちらも `strict` に含まれず、前者が無いと index アクセスの `undefined` が型から消える)。

## 型設計

### 型で状態を表現する

- 状態とバリアントはクラス階層ではなく discriminated union でモデリングする
- switch で網羅チェック (`never`) を行い、将来のバリアント追加時にコンパイルエラーで漏れを検出する
- boolean フラグの組み合わせより、状態を明示した union 型を使う (`{ status: "loading" } | { status: "error"; error: Error } | { status: "success"; data: T }`)

### 型レベルプログラミング

エンフォース階段の最上段。zod / tRPC のような「型を提供する側」のコードでは正当化されるが、アプリケーションコードの不変条件はまず下の段 (parse 関数・discriminated union) で足りるか確認する。使う場合の道具:

- template literal types でリテラル文字列を型レベルで操作する (`type EventName<T extends string> = \`on${Capitalize<T>}\``)
- conditional types と `infer` で型から情報を抽出する
- mapped types で型の変換を宣言的に表現する (`{ [K in keyof T]: ... }`)
- generic に過度な制約を課さない。呼び出し側で推論が効くよう、必要最小限の constraint にとどめる

### 型の精度を上げる

- 取り違えが実害になるドメイン識別子 (同じ primitive に複数の意味が同居する場合) には branded type (`type UserId = string & { readonly __brand: unique symbol }`) を使い、`string` との混同を防ぐ。brand はコンパイル時だけの witness で `as` で破れるため、実行時保証が要る値では境界の parse と併用する
- `satisfies` でリテラル型を保持しつつ型の整合性を検証する。`as` によるキャストより安全
- `as const` でリテラルタプル・オブジェクトの widen を防ぐ
- `readonly` で不変性を型レベルで保証する。プロパティ、パラメータ、配列に適用する

## コードの書き方

- プロジェクト既存のパターン (imports、エラーハンドリング、モジュール構成) に従う
- 拡張される可能性のあるオブジェクト型には `interface` を、union・intersection・computed 型には `type` を使う
- `enum` は使わず、string literal union か `as const` オブジェクトで代替する (enum は型消去だけでは JS にならない構文で、Node の type stripping や `erasableSyntaxOnly` と衝突する)
- 型としてだけ使う import は `import type` で書く (単一ファイル transpiler は import が型か値か判別できず、消すべき import が runtime に残る。`verbatimModuleSyntax` 無しではコンパイラも落とさない)
- キーが動的な場合はプレーンオブジェクトより `Map`/`Set` を優先する
- type guard 関数 (`x is T`) を使い、型の絞り込みを再利用可能にする
- オーバーロードより union 引数 + conditional return type を検討する。型推論との相性が良い
- ユーティリティ型 (`Pick`, `Omit`, `Partial`, `Required`, `Record`) を活用し、型の重複を避ける
- public な関数には JSDoc (`/** */`) を書く。自明でない場合は `@param`, `@returns`, `@example` を含める

## エラーハンドリング

- ドメインエラーは例外サブクラスではなく discriminated union で定義する
- 予測可能な失敗には `Result<T, E>` パターン (またはプロジェクトの同等品) を使う
- `throw` は本当に例外的・回復不能な状況にのみ使う
- catch したエラーは `instanceof` や type guard で型を絞ってからプロパティにアクセスする
