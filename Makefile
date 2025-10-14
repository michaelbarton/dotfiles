DOCKER = docker-compose run --rm

all: fmt apply

apply:
	uv run ansible-playbook -i ~/.dotfiles/ansible/inventory.ini ~/.dotfiles/ansible/dotfiles.yml

fmt:
	${DOCKER} prettier npx prettier --write *.md **/*.yml
	${DOCKER} black black --line-length=100 **/*.py

fmt_check:
	${DOCKER} prettier npx prettier --check *.md **/*.yml
	${DOCKER} black black --check --line-length=100 **/*.py

build:
	docker-compose build

nvim-health:
	nvim --headless "+checkhealth" +qa
