DOCKER := "docker-compose run --rm"

fmt:
	{{DOCKER}} prettier npx prettier --write *.md **/*.yml

fmt_check:
	{{DOCKER}} prettier npx prettier --check *.md **/*.yml
