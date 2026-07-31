APP_NAME := Focus
PROJECT := $(APP_NAME).xcodeproj
DERIVED_DATA := .build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(APP_NAME) -destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA)

.PHONY: all generate build run open dev close kill clean

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

clean:
	rm -rf $(DERIVED_DATA) $(PROJECT)
