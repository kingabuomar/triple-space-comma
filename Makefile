.PHONY: build test install uninstall package clean

build:
	./scripts/build.sh

test:
	./scripts/test.sh
	bash -n scripts/*.sh *.command

install:
	./scripts/install.sh

uninstall:
	./scripts/uninstall.sh

package:
	./scripts/package-release.sh

clean:
	swift package clean
	rm -rf dist release
