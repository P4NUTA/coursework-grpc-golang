#!/bin/bash
DSN="user=postgres password=postgres dbname=postgres sslmode=disable port=5432 host=localhost"
ARGS=$(filter-out $@,$(MAKECMDGOALS))
MAKE_PATH=$(GOPATH)/bin:/bin:/usr/bin:/usr/local/bin:$PATH

PHONY: deps
deps:
	go install \
		github.com/pressly/goose/v3/cmd/goose@latest \
		github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@latest

PHONY: build
build:
	go build -o bin/main ./cmd

PHONY: test
test:
	go test ./...

PHONY: run
run:
	go run cmd/main.go

PHONY: migrate
migrate: deps
	goose -dir migrations postgres $(DSN) up

PHONY: migrate-status
migrate-status: deps
	goose -dir migrations postgres $(DSN) status

PHONY: migrate-gen
migrate-gen: deps
	goose -dir migrations postgres $(DSN) create $(ARGS) sql

PHONY: swagger
swagger:
	swag init -g cmd/main.go


PHONY: generate
generate:
	protoc \
        -I proto \
        -I vendor/protoc-gen-validate \
        -o /dev/null \
        $(find proto -name '*.proto')

MAKE_PATH=$(GOPATH)/bin:/bin:/usr/bin:/usr/local/bin:$PATH

.PHONY: all
all: clean format gen lint

BUF_VERSION=1.6.0

.PHONY: buf-install
buf-install:
ifeq ($(shell uname -s), Darwin)
	@[ ! -f $(GOPATH)/bin/buf ] || exit 0 && \
	tmp=$$(mktemp -d) && cd $$tmp && \
	curl -L -o buf \
		https://github.com/bufbuild/buf/releases/download/v$(BUF_VERSION)/buf-Darwin-arm64 && \
	mv buf $(GOPATH)/bin/buf && \
	chmod +x $(GOPATH)/bin/buf
else
	@[ ! -f $(GOPATH)/bin/buf ] || exit 0 && \
	tmp=$$(mktemp -d) && cd $$tmp && \
	curl -L -o buf \
		https://github.com/bufbuild/buf/releases/download/v$(BUF_VERSION)/buf-Linux-x86_64 && \
	mv buf $(GOPATH)/bin/buf && \
	chmod +x $(GOPATH)/bin/buf
endif

.PHONY: gen
gen: buf-install
	@$(GOPATH)/bin/buf generate
#	@for dir in $(CURDIR)/gen/go/*/; do \
#	  cd $$dir && \
#	  go mod init && go mod tidy; \
  	done

.PHONY: lint
lint: buf-install
	@$(GOPATH)/bin/buf lint --config buf.yaml

.PHONY: format
format: buf-install
	@$(GOPATH)/bin/buf format


.PHONY: clean
clean:
	@rm -rf ./gen || true