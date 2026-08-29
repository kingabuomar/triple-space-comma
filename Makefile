.PHONY: build test install uninstall package clean

build:
	bash ./scripts/build.sh

test:
	bash ./scripts/test.sh
	bash -n scripts/*.sh *.command

install:
	bash ./scripts/install.sh

uninstall:
	bash ./scripts/uninstall.sh

package:
	bash ./scripts/package-release.sh

clean:
	swift package clean
	rm -rf dist release
