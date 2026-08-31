---
name: ponchi
allowed-tools: Bash(ponchi:*), Bash(curl:*), Bash(mkdir:*), Bash(kill:*), Bash(pkill:*)
description: >-
  Draw a hand-drawn-style diagram to align with a human on structure — state
  machines, flows, request paths, component maps, lifecycles. Use when a textual
  explanation would be easier to judge as a rough sketch, when the user asks for
  a diagram / 図 / ぽんち絵, or when you want a human to see and approve the shape
  of a design before you commit to it. Renders entirely on the local machine
  (no network), with a live browser view the human can watch.
---

# ponchi

ponchi turns a declarative scene (nodes + edges) into a hand-drawn-style diagram.
Everything runs locally — nothing is sent over the network. The point is **shared
understanding**: you sketch, the human watches the same picture live in a browser,
and you refine it by reading the rendered PNG yourself.

## The core loop (serve mode — the default)

Prefer `serve`. It gives the human a live view and lets you self-check the same
pixels they see.

1. **Make sure `ponchi` is installed** (see Setup).
2. **Start the server in the background from a temp work dir**, capture its PID,
   and wait until it is actually listening — poll the log, do not fixed-sleep
   (the log is often still empty right after launch):
   ```sh
   mkdir -p /tmp/ponchi-work && cd /tmp/ponchi-work
   ponchi serve > serve.log 2>&1 &
   PONCHI_PID=$!
   for _ in $(seq 1 30); do grep -q listening serve.log && break; sleep 0.3; done
   cat serve.log
   # ponchi serve listening on http://127.0.0.1:<PORT>/
   # POST token (Authorization: Bearer ...): <TOKEN>
   ```
   The port is OS-assigned (multiple sessions won't collide). Parse `<PORT>` and
   `<TOKEN>` from the log. Running from `/tmp/ponchi-work` keeps the output it
   writes (`out/latest.{png,svg}`, relative to the launch dir) out of any repo.

   If your environment kills background processes between commands (some sandboxes
   do — a later `curl` then fails and the PID is gone), don't fight it: use render
   mode instead (below). serve needs a process that survives across your commands.
3. **Tell the human the URL** so they can open it in a browser. The view
   auto-refreshes whenever you push a new scene.
4. **Write a scene** to a temp file (see Scene format) and POST it. Scenes are
   throwaway input — write them under `/tmp`, not in a repo:
   ```sh
   # write the scene JSON to e.g. /tmp/ponchi-scene.json, then:
   curl -s -X POST "http://127.0.0.1:<PORT>/api/scene" \
     -H "Authorization: Bearer <TOKEN>" \
     -H "Content-Type: application/json" \
     --data-binary @/tmp/ponchi-scene.json
   # -> {"version":N}   (HTTP 400 with a message if the scene is invalid)
   ```
5. **Self-check**: the server writes the render to `/tmp/ponchi-work/out/latest.png`
   (relative to where you started it). Read that PNG and actually look at it.
   Confirm the POST response `version` went up and the image matches what you
   sent — if the version rises but the picture is stale, the server isn't running.
   Anything overlapping, mislabeled, or unclear? Fix the JSON and POST again. This
   is the whole value — don't skip it.
6. When done, stop the server: `kill "$PONCHI_PID"` (or `pkill -f "ponchi serve"`).
   Don't rely on `kill %1` — job control may not carry across commands.

`render` mode is the alternative: one-shot, no server, no human view. Use it for
CI or when you only need a file:
```sh
ponchi render /tmp/ponchi-scene.json -o /tmp/diagram.png   # or .svg
```

## Setup

`ponchi` is installed declaratively via Nix (Home Manager) on this machine, so it
is normally already on `PATH`. Check first:
```sh
command -v ponchi
```

If it is missing, it has not been built/applied yet — do **not** `cargo install`
or download a release binary. Ask the human to apply the Nix config instead:
```sh
make switch   # in the nix-config repo
```
The binary is pinned in `nix/home/default.nix` (`rustPlatform.buildRustPackage`);
the handwriting font is embedded, so it is self-contained.

## Scene format

JSON. The recommended mode is **auto layout**: you describe *relationships only*
and the engine places everything. Do not write coordinates in auto mode.

```jsonc
{
  "schema_version": "ponchi.scene/v0",
  "layout": {
    "mode": "auto",
    "engine": "layered",
    "direction": "LR",     // "LR" left-to-right, or "TB" top-to-bottom
    "fit": "grow"          // grow the canvas to fit the content
  },
  "nodes": [
    { "id": "draft",  "label": "Draft",     "shape": "rect",    "role": "process" },
    { "id": "review", "label": "Review",    "shape": "rect",    "role": "input" },
    { "id": "done",   "label": "Published", "shape": "ellipse", "role": "persistence" }
  ],
  "edges": [
    { "id": "e1", "from": "draft",  "to": "review", "label": "submit" },
    { "id": "e2", "from": "review", "to": "done",   "label": "approve" }
  ]
}
```

- `shape`: `rect` | `ellipse` | `diamond`.
- `role` (optional, drives color): `input` | `process` | `external` |
  `persistence` | `transformation`. The names are just color buckets — choose by
  what reads naturally (e.g. an external client → `external`, a datastore →
  `persistence`, a worker → `process`), and keep the scheme consistent so color
  carries meaning. For a state machine specifically, a success/terminal state →
  `persistence` and an error state → `external` reads well; keep success and
  failure visibly distinct.
- `label`: any text; `\n` makes multiple lines. CJK works (the font renders it).
- `edge`: `from`/`to` reference node ids; `label` is optional; `style` is
  `arrow` (default) or `line`; `dashed: true` for dashed.
- `id`s must be unique within their kind; every edge endpoint must be an existing
  node id (otherwise the scene is rejected — a clear error, not a silent drop).

Optional annotations (these need coordinates even in auto mode): `texts`
(free-standing notes) and `zones` (labeled background boxes). With `fit: "grow"`
the canvas expands to include them. Keep them sparse.

Manual mode (omit the `layout` block) requires `x`/`y`/`w`/`h` on every node —
only reach for it when you need precise placement. Auto is almost always better.

## Traps (learn these before drawing)

- **Scenes are throwaway intermediate input — write them under `/tmp`, not in a
  repo.** The human cares about the diagram, not the JSON. Keeping scenes out of
  the working tree also means there is nothing to accidentally commit.
- **Drawing private/internal content is fine** — ponchi is local-only and sends
  nothing over the network, so sketch sensitive designs freely. Only when you
  *deliberately* share a rendered PNG/SVG should you review what's in it, like
  any other artifact.
- **In auto mode, don't set `x`/`y` on nodes** — it's rejected. Let the engine place.
- **Start `serve` in the background**, not the foreground — it runs until killed
  and will otherwise block you.
- **Always read back the rendered PNG** and judge it. The layout you imagined and
  the layout the engine produced are not the same; looking is how you catch it.
- **Keep labels short.** Long labels make wide nodes and crowd the layout; put
  detail in prose, keep the sketch structural.
- **If back-edges or cycles crowd the layout, try the other `direction`.** A
  returning edge (e.g. a retry loop) often routes more cleanly with `TB` than
  `LR` (or vice versa). Re-render and compare — it's a one-word change.

## When NOT to use ponchi

For a trivial 2–3 box idea, ASCII or prose is faster. ponchi earns its keep when
the structure (branches, cycles, multiple paths, lifecycles) is what the human
needs to see and judge.
