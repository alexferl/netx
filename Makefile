.PHONY: dev pre-commit check test

.DEFAULT: help
help:
	@echo "make dev"
	@echo "	setup development environment"
	@echo "make pre-commit"
	@echo "	run pre-commit hooks"
	@echo "make check"
	@echo "	execute odin check"
	@echo "make test"
	@echo "	execute all tests"

check-pre-commit:
ifeq (, $(shell which pre-commit))
	$(error "pre-commit not in $(PATH), pre-commit (https://pre-commit.com) is required")
endif

dev: check-pre-commit
	pre-commit install

pre-commit: check-pre-commit
	pre-commit run --all-files

check:
	odin check . -disallow-do -no-entry-point -strict-style -vet -vet-style -vet-tabs -warnings-as-errors
	odin check examples/ip -disallow-do -strict-style -vet -vet-style -vet-tabs -warnings-as-errors
	odin check examples/ipam -disallow-do -strict-style -vet -vet-style -vet-tabs -warnings-as-errors

test:
	odin test tests/ -all-packages -disallow-do -sanitize:address -strict-style -vet -vet-style -vet-tabs -warnings-as-errors
