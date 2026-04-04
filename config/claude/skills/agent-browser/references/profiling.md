# Profiling

Capture Chrome DevTools performance profiles during browser automation for performance analysis.

**Related**: [commands.md](commands.md) for full command reference, [SKILL.md](../SKILL.md) for quick start.

## Basic Profiling

```bash
agent-browser profiler start
agent-browser navigate https://example.com
agent-browser click "#button"
agent-browser wait 1000
agent-browser profiler stop ./trace.json
```

## Profiler Commands

```bash
agent-browser profiler start                                                    # Start with default categories
agent-browser profiler start --categories "devtools.timeline,v8.execute,blink.user_timing"  # Custom categories
agent-browser profiler stop ./trace.json                                        # Stop and save
```

## Categories

Default categories include:
- `devtools.timeline` -- standard DevTools performance traces
- `v8.execute` -- time spent running JavaScript
- `blink` -- renderer events
- `blink.user_timing` -- `performance.mark()` / `performance.measure()` calls
- `latencyInfo` -- input-to-latency tracking
- `renderer.scheduler` -- task scheduling and execution
- `toplevel` -- broad-spectrum basic events

## Use Cases

### Diagnosing Slow Page Loads

```bash
agent-browser profiler start
agent-browser navigate https://app.example.com
agent-browser wait --load networkidle
agent-browser profiler stop ./page-load-profile.json
```

### Profiling User Interactions

```bash
agent-browser navigate https://app.example.com
agent-browser profiler start
agent-browser click "#submit"
agent-browser wait 2000
agent-browser profiler stop ./interaction-profile.json
```

## Output Format

Chrome Trace Event format JSON. View in:
- **Chrome DevTools**: Performance panel > Load profile
- **Perfetto UI**: https://ui.perfetto.dev/
- **Trace Viewer**: `chrome://tracing`

## Limitations

- Only works with Chromium-based browsers
- Trace data accumulates in memory (capped at 5M events)
- Data collection on stop has a 30-second timeout
