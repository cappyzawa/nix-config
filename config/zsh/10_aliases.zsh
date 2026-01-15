# Aliases (not managed by Nix)

# Architecture switching (macOS specific, requires specific paths)
alias arm='exec arch -arch arm64 /opt/homebrew/bin/zsh'
alias x64='exec arch -arch x86_64 /usr/local/bin/zsh'

# Homebrew-managed tools
if [[ "$(uname -s)" == "Darwin" ]] && command -v brew &>/dev/null; then
    alias ctags="$(brew --prefix)/bin/ctags"
fi
