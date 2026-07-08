---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---

# TypeScript コーディング規約

## 原則

- **型に仕事をさせる**: 型はドキュメントではなくロジックである。型レベルで制約を表現し、不正な状態をコンパイルエラーにする。
- **推論を信頼する**: TypeScript の型推論は強力。明示的な型注釈は公開 API の境界と、推論が不十分な箇所にのみ書く。内部コードに冗長な型注釈を付けない。
- **`any` は型システムの穴**: `unknown` + type guard で代替する。どうしても避けられない場合は理由付きで `// eslint-disable` を付ける。
- **常に strict モード**: tsconfig.json の `strict: true` は必須。

## 型設計

### 型で状態を表現する

- 状態とバリアントはクラス階層ではなく discriminated union でモデリングする
- switch で網羅チェック (`never`) を行い、将来のバリアント追加時にコンパイルエラーで漏れを検出する
- boolean フラグの組み合わせより、状態を明示した union 型を使う (`{ status: "loading" } | { status: "error"; error: Error } | { status: "success"; data: T }`)

### 型レベルプログラミング

- template literal types でリテラル文字列を型レベルで操作する (`type EventName<T extends string> = \`on${Capitalize<T>}\``)
- conditional types と `infer` で型から情報を抽出する
- mapped types で型の変換を宣言的に表現する (`{ [K in keyof T]: ... }`)
- generic に過度な制約を課さない。呼び出し側で推論が効くよう、必要最小限の constraint にとどめる

### 型の精度を上げる

- ドメイン識別子には branded type (`type UserId = string & { readonly __brand: unique symbol }`) を使い、`string` との混同を防ぐ
- `satisfies` でリテラル型を保持しつつ型の整合性を検証する。`as` によるキャストより安全
- `as const` でリテラルタプル・オブジェクトの widen を防ぐ
- `readonly` で不変性を型レベルで保証する。プロパティ、パラメータ、配列に適用する

## コードの書き方

- プロジェクト既存のパターン (imports、エラーハンドリング、モジュール構成) に従う
- 拡張される可能性のあるオブジェクト型には `interface` を、union・intersection・computed 型には `type` を使う
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
