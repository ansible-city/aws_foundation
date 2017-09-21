include .mk

ANSIBLE_CONFIG ?= tests/ansible.cfg
DEST ?= "change-me"
PWD = $(shell pwd)
REGION ?= eu-west-1
ROLE_NAME ?= $(shell basename $$(pwd))
VENV ?= .venv

PATH := $(VENV)/bin:$(shell printenv PATH)
SHELL := env PATH=$(PATH) /bin/bash

export ANSIBLE_CONFIG
export AWS_DEFAULT_REGION=$(REGION)
export AWS_REGION=$(REGION)
export PATH

.DEFAULT_GOAL := help
.PHONY: help

## Run tests on any file change
watch: test_deps
	while sleep 1; do \
		find defaults/ meta/ tasks/ templates/ tests/test.yml tests/vagrant/Vagrantfile \
		| entr -d make lint; \
	done

## Create symlink in given destination folder
# Usage:
#   make install.symlink DEST=~/workspace/my-project/ansible/roles/vendor
install.symlink:
	@if [ ! -d "$(DEST)" ]; then echo "DEST folder does not exists."; exit 1; fi;
	@ln -s $(PWD) $(DEST)/ansible-city.$(ROLE_NAME)
	@echo "intalled in $(DEST)/ansible-city.$(ROLE_NAME)"

## Lint role
# You need to install ansible-lint
lint: $(VENV)
	find defaults/ meta/ tasks/ -name "*.yml" | xargs -I{} ansible-lint {}

## Run tests
test: test_deps lint

## Executes playbook against a AWS account
# This can/will generate costs on your AWS account!
# Usage:
#   make run
run: $(VENV) tests/roles/ansible-city.$(ROLE_NAME)
	ansible-playbook \
		-i inventory \
		-e hosts=localhost \
		playbook.yml

tests/roles/ansible-city.$(ROLE_NAME):
	@mkdir -p $(PWD)/tests/roles
	@ln -s $(PWD) $(PWD)/tests/roles/ansible-city.$(ROLE_NAME)

## Sudo for AWS Roles
# Usage:
#   $(make aws-sudo PROFILE=my-profile-name)
#   $(make aws-sudo PROFILE=my-profile-name-with-mfa TOKEN=123789)
aws-sudo: $(VENV)
	@(printenv TOKEN > /dev/null && aws-sudo -m $(TOKEN) $(PROFILE) ) || ( \
		aws-sudo $(PROFILE) \
	)

# install dependencies in virtualenv
$(VENV):
	@which virtualenv > /dev/null || (\
		echo "please install virtualenv: http://docs.python-guide.org/en/latest/dev/virtualenvs/" \
		&& exit 1 \
	)
	virtualenv $(VENV)
	$(VENV)/bin/pip install -U "pip<9.0"
	$(VENV)/bin/pip install pyopenssl urllib3[secure] requests[security]
	$(VENV)/bin/pip install -r requirements.txt --ignore-installed
	virtualenv --relocatable $(VENV)

## Clean up
clean:
	rm -f .make
	rm -rf $(VENV)
	rm -rf tests/roles

## Prints this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		skip { next } \
		/^#/ { doc=doc "\n" substr($$0, 2); next } \
		/:/ { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

.mk:
	echo "" > .mk
