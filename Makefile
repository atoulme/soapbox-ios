.PHONY: protobuf setup format test lint autocorrect clean build

APP="Soapbox"

# Apple
ifeq ($(shell uname),Darwin)
	PLATFORM=apple
	XCPRETTY_STATUS=$(shell xcpretty -v &>/dev/null; echo $$?)
	ifeq ($(XCPRETTY_STATUS),0)
		XCPRETTY=xcpretty
	else
		XCPRETTY=cat
	endif
endif

setup:
	tuist generate -P

install_deps:
	pod install
ifneq ($(XCPRETTY_STATUS),0)
	@echo "xcpretty not found: Run \`gem install xcpretty\` for nicer xcodebuild output.\n"
endif

clean:
	rm -rf .build $(APP).xcodeproj $(APP).xcworkspace Package.pins Pods Podfile.lock

test: clean setup install_deps
	set -o pipefail && swift test | $(XCPRETTY)

build: clean setup install_deps
	set -o pipefail && swift build | $(XCPRETTY)

lint:
	swiftlint

autocorrect:
	swiftlint autocorrect

linuxmain:
	swift test --generate-linuxmain

format:
	swiftformat .

protobuf:
	 buf generate https://github.com/soapboxsocial/protobufs.git --path soapbox/v1/room.proto --path soapbox/v1/signal.proto
