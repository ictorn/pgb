.PHONY: install
install: release
	install .build/release/pgb /Applications/CLI/pgb

.PHONY: gzip
gzip: release
	du -h .build/release/pgb
	gzip --keep --force .build/release/pgb
	du -h .build/release/pgb.gz
	shasum -a 256 .build/release/pgb.gz

.PHONY: build
build:
	swift build

.PHONY: update
update:
	swift package update

.PHONY: release
release:
	swift build -c release

.PHONY: clean
clean:
	swift build clean

.PHONY: run
run:
	swift run pgb
