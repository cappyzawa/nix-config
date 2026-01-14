.DEFAULT_GOAL := help

bootstrap: ## First-time setup: bootstrap nix-darwin
	nix run nix-darwin -- switch --flake '.#cappyzawa'

switch: ## Apply nix-darwin and home-manager configuration
	sudo /run/current-system/sw/bin/darwin-rebuild switch --flake '.#cappyzawa'

update: ## Update flake inputs and apply
	nix flake update
	sudo /run/current-system/sw/bin/darwin-rebuild switch --flake '.#cappyzawa'

check: ## Run CI checks locally (flake check, fmt, statix, build)
	nix flake check
	nix fmt -- --ci
	nix run nixpkgs#statix -- check .
	nix build .#darwinConfigurations.cappyzawa.system --dry-run

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
