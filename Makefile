IMAGE := qa-m-a
COMPOSE := docker compose

.PHONY: build test verify up run down logs shell lint format security clean

## build: image through the run itself (full suite log + exit code produced, pass/fail NOT yet gated)
build:
	docker build --target test-run -t $(IMAGE):test-run .

## test: the gate — fails if the suite captured by `build` was red
test:
	docker build --target test -t $(IMAGE):test .

## verify: build + test, per the Docker standard
verify: build test

## up: this repo has no persistent service to bring up (every spec drives a
## live third-party production site — turbo.az/abb-bank.az/yelo.az — nothing
## of this repo's own to serve) — "up" means running the suite once via
## compose, gated behind verify first.
up: verify
	$(COMPOSE) up --build --abort-on-container-exit --exit-code-from e2e
	$(COMPOSE) down

## run: ad-hoc live re-run (does not require the test gate to have passed)
run: build
	$(COMPOSE) run --rm e2e

down:
	$(COMPOSE) down -v --remove-orphans

logs:
	$(COMPOSE) logs -f e2e

shell: build
	docker run --rm -it --entrypoint sh $(IMAGE):test-run

## lint / format: no linter or formatter (ESLint/Prettier/etc.) is
## configured anywhere in this repo today (confirmed: package.json has no
## such devDependency or script) — see docs/TECHNICAL_DEBT.md. Nothing to
## run; not invented here (Phase 5 is Docker/Make only, adding tooling is
## Phase 9's call per standing decision 3).
lint:
	@echo "No linter configured in this repo (see docs/TECHNICAL_DEBT.md) - nothing to run."

format:
	@echo "No formatter configured in this repo (see docs/TECHNICAL_DEBT.md) - nothing to run."

security: build
	docker scout cves $(IMAGE):test-run

## clean: never deletes without an explicit confirm flag
clean:
ifndef CONFIRM
	@echo "Refusing to delete images/containers without CONFIRM=1 (e.g. 'make clean CONFIRM=1')."
else
	$(COMPOSE) down -v --remove-orphans
	-docker rmi $(IMAGE):test-run $(IMAGE):test
endif
