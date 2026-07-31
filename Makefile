APP_NAME := Focus
PROJECT := $(APP_NAME).xcodeproj
DERIVED_DATA := .build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app
MARKETING_VERSION := 0.1.0
DMG_PATH := dist/$(APP_NAME)-$(MARKETING_VERSION).dmg
DMG_STAGING := .build/dmg-staging
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(APP_NAME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA)

.PHONY: all generate build run open dev close kill clean release dmg

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

dmg: release
	rm -rf $(DMG_STAGING)
	mkdir -p $(DMG_STAGING)
	cp -R "$(RELEASE_APP)" $(DMG_STAGING)/
	ln -s /Applications $(DMG_STAGING)/Applications
	mkdir -p dist
	hdiutil create -volname "$(APP_NAME)" -srcfolder $(DMG_STAGING) -ov -format UDZO "$(DMG_PATH)"
	rm -rf $(DMG_STAGING)

clean:
	rm -rf $(DERIVED_DATA) $(PROJECT) dist
