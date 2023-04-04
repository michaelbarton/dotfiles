DOCKER = docker-compose run --rm

all: fmt apply

apply:
	./ansible/apply_ansible

fmt:
	${DOCKER} prettier npx prettier --write *.md **/*.yml
	${DOCKER} black black --line-length=100 **/*.py

fmt_check:
	${DOCKER} prettier npx prettier --check *.md **/*.yml
	${DOCKER} black black --check --line-length=100 **/*.py

build:
	docker-compose build

