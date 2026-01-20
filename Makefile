.DEFAULT_GOAL := help

# Host configuration file (persisted after first bootstrap)
HOST_FILE := $(HOME)/.config/nix/host

# Available hosts (for validation and help message)
AVAILABLE_HOSTS := cappyzawa

# Determine NIXNAME: CLI arg > file > error
ifdef NIXNAME
  _NIXNAME := $(NIXNAME)
else ifneq (,$(wildcard $(HOST_FILE)))
  _NIXNAME := $(shell cat $(HOST_FILE))
else
  _NIXNAME :=
endif

# Validation function
define check_nixname
	@if [ -z "$(_NIXNAME)" ]; then \
		echo "Error: NIXNAME not specified and $(HOST_FILE) not found."; \
		echo "Usage: make $(1) NIXNAME=<host>"; \
		echo "Available hosts: $(AVAILABLE_HOSTS)"; \
		exit 1; \
	fi
endef

# Save NIXNAME to file for future use
define save_nixname
	@mkdir -p $(dir $(HOST_FILE))
	@echo "$(_NIXNAME)" > $(HOST_FILE)
	@echo "Saved host '$(_NIXNAME)' to $(HOST_FILE)"
endef

bootstrap: ## First-time setup: bootstrap nix-darwin (NIXNAME=<host> required on first run)
	$(call check_nixname,bootstrap)
	nix run nix-darwin -- switch --flake '.#$(_NIXNAME)'
	$(call save_nixname)

switch: ## Apply nix-darwin and home-manager configuration
	$(call check_nixname,switch)
	sudo /run/current-system/sw/bin/darwin-rebuild switch --flake '.#$(_NIXNAME)'

update: ## Update flake inputs and apply
	$(call check_nixname,update)
	nix flake update
	sudo /run/current-system/sw/bin/darwin-rebuild switch --flake '.#$(_NIXNAME)'

rollback: ## Select a generation with fzf and switch to it
	@gen=$$(sudo darwin-rebuild --list-generations | fzf --tac | awk '{print $$1}') && \
	sudo darwin-rebuild switch --switch-generation $$gen

check: ## Run CI checks locally (flake check, fmt, statix, build)
	nix flake check
	nix fmt -- --ci
	nix run nixpkgs#statix -- check .
	@for host in $(AVAILABLE_HOSTS); do \
		echo "Building $$host..."; \
		nix build .#darwinConfigurations.$$host.system --dry-run; \
	done

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Available hosts: $(AVAILABLE_HOSTS)"
	@if [ -f $(HOST_FILE) ]; then \
		echo "Current host: $$(cat $(HOST_FILE))"; \
	else \
		echo "Current host: (not set - run 'make bootstrap NIXNAME=<host>')"; \
	fi
