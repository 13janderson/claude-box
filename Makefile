.DEFAULT_GOAL := help
.PHONY: help build run shell exec status restart stop clean purge logs prompt

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

build: ## Rebuild the sandbox image
	./sandbox build

run: ## Start an interactive Claude session
	./sandbox

shell: ## Open a bash shell in the sandbox
	./sandbox shell

exec: ## Run a command in the sandbox (e.g. make exec CMD="ls -la")
	./sandbox exec $(CMD)

status: ## Show container status and resource usage
	./sandbox status

restart: ## Restart the sandbox container
	./sandbox restart

stop: ## Stop the sandbox container
	./sandbox stop

clean: ## Stop and remove this directory's container (conversation history is preserved)
	./sandbox clean

purge: ## Stop and remove this directory's container, conversation history, and the shared image
	./sandbox purge

logs: ## Tail container logs
	./sandbox logs

prompt: ## Run a one-shot Claude prompt (e.g. make prompt P="explain main.go")
	./sandbox $(P)
