all: fmt apply

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
