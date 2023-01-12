DOCKER = docker-compose run --rm

fmt:
	${DOCKER} prettier npx prettier --write *.md **/*.yml
	${DOCKER} black black --line-length=100 **/*.py

fmt_check:
	${DOCKER} prettier npx prettier --check *.md **/*.yml
	${DOCKER} black black --check --line-length=100 **/*.py
