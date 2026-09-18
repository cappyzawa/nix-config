---
name: commander
description: Epic 級の Issue を「指揮セッション 1 つ + worktree セッション複数」で進める運用。指揮は実装せず、fresh-eyes 評価・スライス切り出し・chip 発行・裁定・進捗管理・記録に徹し、作業本体は Claude App の別セッション（worktree）に出す。Issue を渡されて「指揮官になってくれ」「セッションで並行に進めたい」と言われたとき、または複数 PR にまたがる作業を 1 セッションで抱えそうなときに使う。
argument-hint: <Issue URL> [補足]
---

# Commander

Epic 級の Issue を、**指揮セッション（このセッション）と worktree セッション（worker）** に分けて進める。
Agent tool の subagent ではなく **Claude App のセッション**を worker にする。
worker は独立した context・独立した permission・独立した worktree を持ち、ユーザーが直接会話できるので、指揮側の context に tool 出力が溜まらず、承認の経路も各 worker で閉じる。

AGENTS.md の役割分担を層ごとに当てる。指揮はユーザーと Epic の Why と What を決め、worker はスライスの main セッションとして How を持ち、実装は Sonnet の subagent に出す。
model は指揮が Fable、worker が Opus で、この分担に対応する。
chip に model は指定できないので、ユーザーが chip を押すときの設定か、起動後の `set_session_model` で決める。

## 前提となる道具

- `mcp__ccd_session__spawn_task`: worker を起こす唯一の手段。ユーザーが chip を押すと fresh な worktree でセッションが立つ。指揮からセッションを直接作る API は無い
- `mcp__ccd_session_mgmt__list_sessions` / `list_events` / `send_message` / `set_session_title` / `set_session_model`: worker の発見・観察・指示・命名
- `mcp__ccd_session__dismiss_task`: 押されなかった chip の取り下げ（再発行はまず dismiss してから）
- worker からの連絡は `<cross-session-message>` として届く。返信は `send_message` で、宛先は `list_sessions` の sessionId（`from` の socket アドレスはセッションが消えると解決しない）
- Claude Code CLI では `worktree` skill（herdr）が代替になるが、この skill の手順は Claude App 前提

## 0. 名乗る

`set_session_title` で「<Issue 番号> 指揮」のような固定名にする。
chip の prompt に「相談先: セッション『<名前>』に `send_message`」と書けるようになり、worker が `list_sessions` で指揮を見つけられる。

## 1. fresh-eyes 評価（着手前、必ず出す）

Issue 本文・コメント・関連 memory・進行中 PR・CI 状態を読み、**方針が正しいか**を先に評価してユーザーに返す。
評価の観点は固定で、順序の偏り（作業分解が既存資産単位で症状単位になっていない）、読み手の不在（書き手だけ厚い）、直列ボトルネック（外部依存待ちが全部を止める）、比較キーや語彙が運用で割れる箇所、の 4 つを最低限見る。
評価で出た欠落は、そのまま最初の chip になることが多い（例: 「何を測るかの一覧が無い」→ 一覧を書く chip）。

評価は結論と根拠だけを書く。修正に着手しない。

## 2. 現状の盤面を持つ

`list_sessions` と `gh pr list` / `gh run list` で、走っているセッション・PR・CI を表にする。
以後、ユーザーへの報告は毎回この表を末尾に付ける（作業名 / 状態 / 待っているもの）。
ユーザーは worker の会話を全部は見ないので、盤面が無いと何を待っているか分からなくなる。

## 3. スライスを切って chip を出す

1 chip = 1 PR = 合格条件 1 つ。同じ合格条件で確かめられる変更は 1 つの chip に入れ、意図の分離は commit に残す。
`templates/chip-prompt.md` の骨格で prompt を書く。
worker は指揮の会話を見ていないので、**背景（読むもの）・契約（番号付き）・制約・相談先**を自己完結で書く。
契約に書くのは to-be、合格条件のコマンド、所有の線引き、判断規則までで、設計は書かない。How は worker が持ち、指揮が設計を書くと全スライスの設計 context を指揮が抱え、How の相談が指揮に戻ってくる。

**同時に走らせる worker は、ユーザーが 1 日にレビューして merge できる PR の数（目安 2〜3）を上限にする。** 上限を超えた worker は在庫を作るだけで、待つ間に前提が変わって手戻りになる。1 つ merge されたら次の chip を出す。

- 判断規則を先に渡す（例: 「warm 10 分以内なら pull_request に載せる、超えたら main push だけ」）。worker が自分で当てはめられ、境目で割れたときだけ指揮に戻る
- 「推奨は書くが決めない」と「裁定して進める」を契約で区別する。前者は数字を測って持ち帰る調査型、後者は実装型
- 同時に走る PR が触るファイルの所有を chip に書く（「`design/x.md` の A 節は別 PR が所有、触らない」）。衝突は section 単位で避け、先にマージした方に他方が rebase する
- 依存する後続は上流のマージを待たず **stack して出してよい**（GitHub が stacked PR をサポートするようになり、待つより並行に進める方が得）。chip には base branch（上流の branch 名）と、上流マージ後の retarget（base を main に戻して merge で追随、force-push なし）を契約として書く。ユーザーが rate limit や集中の都合で直列を望んだときだけ待つ
- 語彙の規約（英語識別子を日本語名詞にしない、避ける語）を chip に持ち込む。後から直すと保存形式の改名になる
- chip が押されなかったら `dismiss_task` してから再発行する

## 4. 相談に答える

worker からの相談は **その場で裁定し、根拠を 1〜2 文添えて返す**。
再検討や選択肢の列挙で返さない。

- How の判断は worker に返す。指揮が裁定するのは to-be、所有の線引き、判断規則の解釈で、契約自体が誤っていたと分かったら止めてユーザーに戻す
- worker が「所有外」として保留したファイルがあれば、所有を明示的に移す
- 前提が変わったこと（外部依存が解けた、レビューで穴が出た）は、裁定を変えなくてもユーザーに伝える
- 同じ型の指摘が別 worker で 2 回出たら、以後の chip の契約に一般化して入れる（例: 「新しい検査が信用している入力を negative test で塞ぐ」）
- 行き詰まった worker は、指揮が事実を集めて仮説を渡す（例: CI 失敗ログの該当行と Dockerfile の COPY 一覧）。ただし帰属を断定しない。worker の訂正を受けたら自分の読みが違ったと明記する

## 5. 承認の経路

ready 化・マージ・issue / PR へのコメント・人への mention は外向き操作で、**worker は指揮経由の伝聞を承認として扱えない**。
指揮がやるのは推奨と判断材料の提示までで、実行の承認はユーザーが worker のセッションに直接「はい」を送るか、事前に worker へ「指揮の go で実行してよい」と委任しておく。
指揮がユーザーの承認を受けて自分で行う外向き操作（issue への追記、workflow_dispatch、settings 変更）は、このセッションで直接 OK をもらってから行う。

ユーザーが退勤・休日を告げたら、全 worker に「作業と draft PR までは続けてよいが外向き操作は止める」を送り、以後は判断と記録だけをする。

## 6. レビューとマージ順

- review agent への応答ラウンドの上限は変更量のルール（CLAUDE.local.md）で決め、chip に書く。人間レビュー必須の判定はプロジェクトの review policy に従い、要否と理由を chip と PR 本文に書く。仕分け（実害 / 文面磨き / 見送り）を毎ラウンド返させる
- 切り上げ条件は「文面磨きしか残らない」か「上限到達」。上限内でも契約の形に触る指摘が尽きたら切り上げる
- worker 自身の「直前の修正が次の穴を作った」報告は傾向として記録する（契約を締める変更で頻発する）
- マージ順は指揮が決めて両 worker に伝える。マージされたら main の sha を後続 worker に送り、main を merge（force-push なし）で取り込ませる
- マージ判断は毎回ユーザーに渡す。推奨を 1 つ添える

## 7. 記録

project memory に「キックオフ」ファイルを 1 つ持ち、節目ごとに更新する。
書くのは、決定と根拠、マージ済み PR と main の sha、各 worker が返した「想定と違った事実」、持ち越し論点、掃除の状態。
ユーザーからの運用上の指摘（語彙、承認経路、休日）は個別の feedback memory にし、次の chip の制約に反映する。

キックオフを正本にし、milestone ごとに指揮セッションを作り直してキックオフから読み直す。指揮の会話は worker の報告と盤面更新で膨らみ続け、長くなった context は compact しても判断の質が戻らない。

## 8. 掃除

マージ済みで session が消えた worker の worktree は、clean かつ detached HEAD か確認してから `git worktree remove` し、ローカル branch を消す。
同じ path が別 worker に再利用されていることがあるので、`list_sessions` の cwd と照合してから消す。
remote branch はマージ時に消えているのが通常で、残っていたら別途報告する。

## やらないこと

- 指揮セッションで実装しない。pinpoint な 1 行の doc 修正も worker に出す（context を濁さない）
- worker の diff を読み込まない。読むのは worker の報告（合格条件の出力、未解決事項）・PR 本文・CI 結果・裁定に必要な該当箇所だけ
- 「まだ待っている」を沈黙で表さない。待っているものは盤面の表に書く
- 指揮の読みを worker に押し付けない。仮説として渡し、worker の実測を優先する
