PROJECT := CycleWrench.xcodeproj
SIMULATOR_ID ?= $(shell python3 scripts/select_simulator.py)
DESTINATION ?= platform=iOS Simulator,id=$(SIMULATOR_ID)
RESULT_BUNDLE_PATH ?= build/TestResults-$(shell date +%Y%m%d-%H%M%S).xcresult

.PHONY: generate build test

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme CycleWrench -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build

test: generate
	xcodebuild -project $(PROJECT) -scheme CycleWrench -destination "$(DESTINATION)" -derivedDataPath build -resultBundlePath "$(RESULT_BUNDLE_PATH)" -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO test
