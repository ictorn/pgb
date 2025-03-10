install: release
	install .build/release/pgb ~/.local/bin/pgb

gzip: release
	gzip -k .build/release/pgb
	shasum -a 256 .build/release/pgb.gz

build:
	swift build

update: 
	swift package update

release:
	swift build -c release

clean:
	swift build clean

run:
	swift run pgb
