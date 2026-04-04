# Proxy Support

Proxy configuration for geo-testing, rate limiting avoidance, and corporate environments.

**Related**: [commands.md](commands.md) for global options, [SKILL.md](../SKILL.md) for quick start.

## Basic Proxy Configuration

```bash
# Via CLI flag
agent-browser --proxy "http://proxy.example.com:8080" open https://example.com

# Via environment variable
export HTTP_PROXY="http://proxy.example.com:8080"
agent-browser open https://example.com
```

## Authenticated Proxy

```bash
export HTTP_PROXY="http://username:password@proxy.example.com:8080"
agent-browser open https://example.com
```

## SOCKS Proxy

```bash
export ALL_PROXY="socks5://proxy.example.com:1080"
agent-browser open https://example.com
```

## Proxy Bypass

```bash
# Via CLI flag
agent-browser --proxy "http://proxy.example.com:8080" --proxy-bypass "localhost,*.internal.com" open https://example.com

# Via environment variable
export NO_PROXY="localhost,127.0.0.1,.internal.company.com"
```

## Common Use Cases

### Geo-Location Testing

```bash
#!/bin/bash
PROXIES=("http://us-proxy.example.com:8080" "http://eu-proxy.example.com:8080")
for proxy in "${PROXIES[@]}"; do
    export HTTP_PROXY="$proxy"
    export HTTPS_PROXY="$proxy"
    region=$(echo "$proxy" | grep -oP '^\w+-\w+')
    agent-browser --session "$region" open https://example.com
    agent-browser --session "$region" screenshot "./screenshots/$region.png"
    agent-browser --session "$region" close
done
```

### Corporate Network Access

```bash
export HTTP_PROXY="http://corpproxy.company.com:8080"
export HTTPS_PROXY="http://corpproxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1,.company.com"
agent-browser open https://external-vendor.com
```

## Verifying Proxy Connection

```bash
agent-browser open https://httpbin.org/ip
agent-browser get text body
```

## Troubleshooting

### SSL/TLS Errors Through Proxy

```bash
# For testing only
agent-browser open https://example.com --ignore-https-errors
```

## Best Practices

1. **Use environment variables** - Don't hardcode proxy credentials
2. **Set NO_PROXY appropriately** - Avoid routing local traffic through proxy
3. **Test proxy before automation** - Verify connectivity first
4. **Rotate proxies for large scraping jobs**
