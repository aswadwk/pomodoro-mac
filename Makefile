APP_NAME := Focus
PROJECT := $(APP_NAME).xcodeproj
DERIVED_DATA := .build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app
MARKETING_VERSION := 0.1.0
DMG_PATH := dist/$(APP_NAME)-$(MARKETING_VERSION).dmg
DMG_STAGING := .build/dmg-staging
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(APP_NAME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA)

.PHONY: all generate build run open dev close kill clean release dmg test test-unit test-feature

all: build

generate:
	xcodegen generate

build: generate
	$(XCODEBUILD) build

run: build
	open "$(APP_PATH)"

open: run

dev:
	-$(MAKE) kill
	$(MAKE) run

close:
	-killall $(APP_NAME) 2>/dev/null || true

kill: close

release: generate
	$(XCODEBUILD) -configuration Release build

test: generate
	$(XCODEBUILD) test

test-unit: generate
	$(XCODEBUILD) test -only-testing:FocusTests

test-feature: generate
	$(XCODEBUILD) test -only-testing:FocusFeatureTests

dmg: release
	rm -rf $(DMG_STAGING) "$(DMG_PATH)"
	mkdir -p $(DMG_STAGING)
	cp -R "$(RELEASE_APP)" $(DMG_STAGING)/
	create-dmg \
		--volname "$(APP_NAME)" \
		--background design/dmg-background.png \
		--window-size 660 400 \
		--icon-size 128 \
		--icon "$(APP_NAME).app" 190 230 \
		--app-drop-link 470 230 \
		--no-internet-enable \
		--format UDZO \
		"$(DMG_PATH)" $(DMG_STAGING)
	rm -rf $(DMG_STAGING)

clean:
	rm -rf $(DERIVED_DATA) $(PROJECT) dist
