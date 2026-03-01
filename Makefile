all: fmt apply nvim-check

apply:
	uv run ansible-playbook -i ~/.dotfiles/ansible/inventory.ini ~/.dotfiles/ansible/dotfiles.yml

fmt:
	npx --yes prettier --write *.md **/*.yml
	uvx black --line-length=100 **/*.py

fmt_check:
	npx --yes prettier --check *.md **/*.yml
	uvx black --check --line-length=100 **/*.py

nvim-health:
	nvim --headless "+checkhealth" +qa

# Smoke test: boot nvim with representative filetypes and fail on startup errors/warnings.
# Catches plugin misconfigurations (e.g. missing tree-sitter parsers, broken submodules)
# that produce warnings in :messages but pass :checkhealth.
NVIM_CHECK_FILETYPES := R py lua md
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
