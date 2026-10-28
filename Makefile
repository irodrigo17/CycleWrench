PROJECT := CycleWrench.xcodeproj

.PHONY: generate build

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme CycleWrench -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
