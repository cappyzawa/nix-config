# Authentication Patterns

Login flows, session persistence, OAuth, 2FA, and authenticated browsing.

**Related**: [session-management.md](session-management.md) for state persistence details, [SKILL.md](../SKILL.md) for quick start.

## Contents

- [Import Auth from Your Browser](#import-auth-from-your-browser)
- [Persistent Profiles](#persistent-profiles)
- [Session Persistence](#session-persistence)
- [Basic Login Flow](#basic-login-flow)
- [Saving Authentication State](#saving-authentication-state)
- [Restoring Authentication](#restoring-authentication)
- [OAuth / SSO Flows](#oauth--sso-flows)
- [Two-Factor Authentication](#two-factor-authentication)
- [HTTP Basic Auth](#http-basic-auth)
- [Cookie-Based Auth](#cookie-based-auth)
- [Token Refresh Handling](#token-refresh-handling)
- [Security Best Practices](#security-best-practices)

## Import Auth from Your Browser

The fastest way to authenticate is to reuse cookies from a Chrome session you are already logged into.

**Step 1: Start Chrome with remote debugging**

```bash
# macOS
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222

# Linux
google-chrome --remote-debugging-port=9222
```

Log in to your target site(s) in this Chrome window as you normally would.

> **Security note:** `--remote-debugging-port` exposes full browser control on localhost. Any local process can connect and read cookies, execute JS, etc. Only use on trusted machines and close Chrome when done.

**Step 2: Grab the auth state**

```bash
# Auto-discover the running Chrome and save its cookies + localStorage
agent-browser --auto-connect state save ./my-auth.json
```

**Step 3: Reuse in automation**

```bash
# Load auth at launch
agent-browser --state ./my-auth.json open https://app.example.com/dashboard

# Or load into an existing session
agent-browser state load ./my-auth.json
agent-browser open https://app.example.com/dashboard
```

> **Security note:** State files contain session tokens in plaintext. Add them to `.gitignore`, delete when no longer needed, and set `AGENT_BROWSER_ENCRYPTION_KEY` for encryption at rest.

**Tip:** Combine with `--session-name` so the imported auth auto-persists across restarts:

```bash
agent-browser --session-name myapp state load ./my-auth.json
```

## Persistent Profiles

Use `--profile` to point agent-browser at a Chrome user data directory:

```bash
# First run: login once
agent-browser --profile ~/.myapp-profile open https://app.example.com/login

# All subsequent runs: already authenticated
agent-browser --profile ~/.myapp-profile open https://app.example.com/dashboard
```

Or set via environment variable:

```bash
export AGENT_BROWSER_PROFILE=~/.myapp-profile
agent-browser open https://app.example.com/dashboard
```

## Session Persistence

Use `--session-name` to auto-save and restore cookies + localStorage by name:

```bash
agent-browser --session-name twitter open https://twitter.com
# ... login flow ...
agent-browser close  # state saved to ~/.agent-browser/sessions/

# Next time: state is automatically restored
agent-browser --session-name twitter open https://twitter.com
```

## Basic Login Flow

```bash
agent-browser open https://app.example.com/login
agent-browser wait --load networkidle
agent-browser snapshot -i
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser get url  # Should be dashboard, not login
```

## Saving Authentication State

```bash
# After logging in:
agent-browser state save ./auth-state.json
```

## Restoring Authentication

```bash
agent-browser state load ./auth-state.json
agent-browser open https://app.example.com/dashboard
agent-browser snapshot -i
```

## OAuth / SSO Flows

```bash
agent-browser open https://app.example.com/auth/google
agent-browser wait --url "**/accounts.google.com**"
agent-browser snapshot -i
agent-browser fill @e1 "user@gmail.com"
agent-browser click @e2
agent-browser wait 2000
agent-browser snapshot -i
agent-browser fill @e3 "password"
agent-browser click @e4
agent-browser wait --url "**/app.example.com**"
agent-browser state save ./oauth-state.json
```

## Two-Factor Authentication

```bash
agent-browser open https://app.example.com/login --headed
agent-browser snapshot -i
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3

# Wait for user to complete 2FA manually
echo "Complete 2FA in the browser window..."
agent-browser wait --url "**/dashboard" --timeout 120000
agent-browser state save ./2fa-state.json
```

## HTTP Basic Auth

```bash
agent-browser set credentials username password
agent-browser open https://protected.example.com/api
```

## Cookie-Based Auth

```bash
agent-browser cookies set session_token "abc123xyz"
agent-browser open https://app.example.com/dashboard
```

## Token Refresh Handling

```bash
#!/bin/bash
STATE_FILE="./auth-state.json"

if [[ -f "$STATE_FILE" ]]; then
    agent-browser state load "$STATE_FILE"
    agent-browser open https://app.example.com/dashboard
    URL=$(agent-browser get url)
    if [[ "$URL" == *"/login"* ]]; then
        echo "Session expired, re-authenticating..."
        agent-browser snapshot -i
        agent-browser fill @e1 "$USERNAME"
        agent-browser fill @e2 "$PASSWORD"
        agent-browser click @e3
        agent-browser wait --url "**/dashboard"
        agent-browser state save "$STATE_FILE"
    fi
else
    agent-browser open https://app.example.com/login
    # ... login flow ...
fi
```

## Security Best Practices

1. **Never commit state files** - They contain session tokens
2. **Use environment variables for credentials**
3. **Clean up after automation** - `agent-browser cookies clear`
4. **Use short-lived sessions for CI/CD**
