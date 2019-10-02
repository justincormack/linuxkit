#!/bin/sh

set -e

usage() {
	echo "Usage: dir"
	exit 1
}

[ $# = 0 ] && usage

dir="$1"

cd "$dir"

# lint before building
>&2 echo "gofmt..."
test -z $(gofmt -s -l .| grep -v .pb. | grep -v vendor/ | tee /dev/stderr)

>&2 echo "govet..."
test -z $(GOOS=linux go vet ./... | tee /dev/stderr)

>&2 echo "golint..."
test -z $(find . -type f -name "*.go" -not -path "*/vendor/*" -not -name "*.pb.*" -exec golint {} \; | tee /dev/stderr)

>&2 echo "ineffassign..."
test -z $(find . -type f -name "*.go" -not -path "*/vendor/*" -not -name "*.pb.*" -exec ineffassign {} \; | tee /dev/stderr)

>&2 echo "go test..."
go test

>&2 echo "go build..."

[ "${REQUIRE_CGO}" = 1 ] || export CGO_ENABLED=0

go install -buildmode pie -ldflags "-s -w ${ldflags} -extldflags \"-fno-PIC -static\""
