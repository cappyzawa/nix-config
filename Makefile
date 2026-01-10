.DEFAULT_GOAL := help

switch: ## Apply nix-darwin and home-manager configuration
	sudo /run/current-system/sw/bin/darwin-rebuild switch --flake '.#cappyzawa'

update: ## Update flake inputs and apply
	nix flake update
	sudo /run/current-system/sw/bin/darwin-rebuild switch --flake '.#cappyzawa'

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
