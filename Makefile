include .make

DEST ?= "change-me"
PWD = $(shell pwd)
ROLE_NAME ?= $(shell basename $$(pwd))

.DEFAULT_GOAL := help
.PHONY: help

## Run tests on any file change
watch: test_deps
	while sleep 1; do \
		find defaults/ meta/ tasks/ templates/ tests/test.yml tests/vagrant/Vagrantfile \
		| entr -d make lint; \
	done

## Create symlink in given `vendor` folder
# Usage:
#   make install_link DEST=~/workspace/my-project/ansible/vendor
install_link:
	@if [ ! -d "$(DEST)" ]; then echo "DEST folder does not exists."; exit 1; fi;
	@ln -s $(PWD) $(DEST)/ansible-city.$(ROLE_NAME)
	@echo "intalled in $(DEST)/ansible-city.$(ROLE_NAME)"

## Run tests
test: test_deps lint

## Lint role
# You need to install ansible-lint
lint:
	find defaults/ meta/ tasks/ templates/ -name "*.yml" | xargs -I{} ansible-lint {}

## Clean up
clean:
	rm -rf .make

## Prints this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		skip { next } \
		/^#/ { doc=doc "\n" substr($$0, 2); next } \
		/:/ { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

.make:
	echo "" > .make
