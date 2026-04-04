# Video Recording

Capture browser automation as video for debugging, documentation, or verification.

**Related**: [commands.md](commands.md) for full command reference, [SKILL.md](../SKILL.md) for quick start.

## Basic Recording

```bash
agent-browser record start ./demo.webm
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser click @e1
agent-browser fill @e2 "test input"
agent-browser record stop
```

## Recording Commands

```bash
agent-browser record start ./output.webm   # Start recording to file
agent-browser record stop                   # Stop current recording
agent-browser record restart ./take2.webm   # Stop current + start new
```

## Use Cases

### Debugging Failed Automation

```bash
#!/bin/bash
agent-browser record start ./debug-$(date +%Y%m%d-%H%M%S).webm
agent-browser open https://app.example.com
agent-browser snapshot -i
agent-browser click @e1 || {
    echo "Click failed - check recording"
    agent-browser record stop
    exit 1
}
agent-browser record stop
```

### Documentation Generation

```bash
#!/bin/bash
agent-browser record start ./docs/how-to-login.webm
agent-browser open https://app.example.com/login
agent-browser wait 1000
agent-browser snapshot -i
agent-browser fill @e1 "demo@example.com"
agent-browser wait 500
agent-browser fill @e2 "password"
agent-browser wait 500
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser wait 1000
agent-browser record stop
```

## Best Practices

1. **Add pauses for clarity** - `agent-browser wait 500` between steps
2. **Use descriptive filenames** - Include context in the filename
3. **Handle recording in error cases** - Use trap to ensure `record stop` runs
4. **Combine with screenshots** - Capture key frames alongside video

## Output Format

- Default format: WebM (VP8/VP9 codec)
- Compatible with all modern browsers and video players

## Limitations

- Recording adds slight overhead to automation
- Large recordings can consume significant disk space
- Some headless environments may have codec limitations
