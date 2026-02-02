.PHONY: help setup validate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Run setup.sh (install dependencies, configure gitignore)
	./setup.sh

validate: ## Validate Vagrantfile syntax and lint setup.sh
	vagrant validate
	shellcheck setup.sh
