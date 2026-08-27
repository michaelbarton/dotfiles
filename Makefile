YAML_FILES := $(shell git ls-files '*.yml' '*.yaml' | while IFS= read -r file; do [ -f "$$file" ] && printf "%s " "$$file"; done)
MARKDOWN_FILES := $(shell git ls-files '*.md' | while IFS= read -r file; do [ -f "$$file" ] && printf "%s " "$$file"; done)
PYTHON_FILES := $(shell git ls-files '*.py' | while IFS= read -r file; do [ -f "$$file" ] && printf "%s " "$$file"; done)
LUA_FILES := $(shell git ls-files '*.lua' | while IFS= read -r file; do [ -f "$$file" ] && printf "%s " "$$file"; done)
# Shell scripts: *.sh/*.bash plus any tracked file with an sh/bash/dash/ksh
# shebang (catches aspell/sort_dictionary, osx/get-pass, bash/bashrc).
# zsh is deliberately excluded: shellcheck rejects it outright with SC1071.
SHELL_FILES := $(shell git ls-files | while IFS= read -r file; do [ -f "$$file" ] || continue; case "$$file" in (*.sh|*.bash) printf "%s " "$$file"; continue;; esac; head -1 "$$file" 2>/dev/null | grep -qE '^\#!.*/(env +)?(sh|bash|dash|ksh)$$' && printf "%s " "$$file"; done)
FISH_FILES := $(shell git ls-files '*.fish' | while IFS= read -r file; do [ -f "$$file" ] && printf "%s " "$$file"; done)

PRETTIER_VERSION := 3.5.3
STYLUA_VERSION := 2.5.2
RUFF_VERSION := 0.16.5

.PHONY: all apply fmt fmt_check nvim-health nvim-check nvim-update packages packages-bio

all: fmt apply nvim-check

apply:
	uv run ansible-playbook -i ~/.dotfiles/ansible/inventory.ini ~/.dotfiles/ansible/dotfiles.yml

packages:
	brew bundle install --file=Brewfile --no-upgrade
	brew autoremove
	brew cleanup

packages-bio:
	brew bundle install --file=Brewfile.bio --no-upgrade

fmt:
	@if [ -n "$(YAML_FILES)" ]; then npx --loglevel error --yes prettier@$(PRETTIER_VERSION) --write $(YAML_FILES); fi
	@if [ -n "$(MARKDOWN_FILES)" ]; then uvx --with mdformat-gfm --with mdformat-frontmatter mdformat --wrap 80 --number $(MARKDOWN_FILES); fi
	@if [ -n "$(PYTHON_FILES)" ]; then uvx ruff@$(RUFF_VERSION) format --line-length=100 $(PYTHON_FILES); fi
	@if [ -n "$(PYTHON_FILES)" ]; then uvx ruff@$(RUFF_VERSION) check --fix --line-length=100 $(PYTHON_FILES); fi
	@if [ -n "$(LUA_FILES)" ]; then npx --loglevel error --yes @johnnymorganz/stylua-bin@$(STYLUA_VERSION) -- $(LUA_FILES); fi

fmt_check:
	@if [ -n "$(YAML_FILES)" ]; then npx --loglevel error --yes prettier@$(PRETTIER_VERSION) --check $(YAML_FILES); fi
	@if [ -n "$(MARKDOWN_FILES)" ]; then uvx --with mdformat-gfm --with mdformat-frontmatter mdformat --check --wrap 80 --number $(MARKDOWN_FILES); fi
	@if [ -n "$(PYTHON_FILES)" ]; then uvx ruff@$(RUFF_VERSION) format --check --line-length=100 $(PYTHON_FILES); fi
	@if [ -n "$(PYTHON_FILES)" ]; then uvx ruff@$(RUFF_VERSION) check --line-length=100 $(PYTHON_FILES); fi
	@if [ -n "$(LUA_FILES)" ]; then npx --loglevel error --yes @johnnymorganz/stylua-bin@$(STYLUA_VERSION) --check -- $(LUA_FILES); fi
	@if [ -n "$(SHELL_FILES)" ]; then shellcheck -e SC1091 $(SHELL_FILES); fi
	@for f in $(FISH_FILES); do fish --no-execute $$f; fish_indent --check $$f; done
	@ansible-lint ansible/dotfiles.yml
	@actionlint .github/workflows/*.yml

nvim-health:
	nvim --headless "+checkhealth" +qa

# Smoke test: boot nvim with representative filetypes and fail on startup errors/warnings.
# Catches plugin misconfigurations (e.g. missing tree-sitter parsers, broken submodules)
# that produce warnings in :messages but pass :checkhealth.
NVIM_CHECK_FILETYPES := R py lua md qmd
NVIM_CHECK_TMPDIR := /tmp/_nvim_check
NVIM_CHECK_TIMEOUT := 30

nvim-check:
	@mkdir -p $(NVIM_CHECK_TMPDIR)
	@fail=0; \
	for ft in $(NVIM_CHECK_FILETYPES); do \
	  tmpfile="$(NVIM_CHECK_TMPDIR)/test.$$ft"; \
	  msgfile="$(NVIM_CHECK_TMPDIR)/messages_$$ft.txt"; \
	  touch "$$tmpfile"; \
	  timeout $(NVIM_CHECK_TIMEOUT) nvim --headless \
	    +"edit $$tmpfile" \
	    +"sleep 3" \
	    +"redir! > $$msgfile | silent messages | redir END" \
	    +"qall!" 2>/dev/null || true; \
	  if grep -qiE '(error|warning)' "$$msgfile" 2>/dev/null; then \
	    echo "FAIL [$$ft]: startup errors detected"; \
	    cat "$$msgfile"; \
	    fail=1; \
	  else \
	    echo "PASS [$$ft]: clean startup"; \
	  fi; \
	done; \
	rm -rf $(NVIM_CHECK_TMPDIR); \
	[ "$$fail" -eq 0 ] || (echo "nvim-check: some filetypes had errors" && exit 1)

nvim-update:
	nvim --headless "+Lazy! sync" "+qa"
	cp ~/.config/nvim/lazy-lock.json nvim/lazy-lock.json
