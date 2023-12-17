BUILD_DIR=./build
GIT_TAG=$(shell git describe --abbrev=7 --always --tags)

APP_NAME=ChromeBuddy
APP_BUNDLE=$(BUILD_DIR)/$(APP_NAME).app
APP_VERSION=$(shell (echo ${GIT_TAG} | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$') && echo ${GIT_TAG} | cut -c2- || echo "9999.9.9" )
APP_BUNDLE_IDENTIFIER=com.apple.ScriptEditor.id.$(APP_NAME)
APP_ICON_NAME="$(APP_NAME)"
APP_PLIST=$(APP_BUNDLE)/Contents/Info.plist

.PHONY: all clean prepare compile build version sign package help

all: help

clean: ## Clean build directory
	rm -rf $(BUILD_DIR)

prepare: clean ## Prepare for build, copy files and setting version
	mkdir $(BUILD_DIR)
	cp ChromeBuddy.applescript $(BUILD_DIR)

	@##### Set version number for about window
	sed -i '' "s/x.x.x/$(APP_VERSION)/g" $(BUILD_DIR)/ChromeBuddy.applescript

compile: prepare ## Compile app bundle
	@##### Build app from script
	osacompile -x -o $(APP_BUNDLE) $(BUILD_DIR)/ChromeBuddy.applescript

build: compile ## Adjusting app Info.plist, updating icon, removing signature and unneeded files
	@##### Remove signature
	codesign --remove-signature $(APP_BUNDLE)

	@##### Update Plist
	@plutil -replace CFBundleIconFile -string $(APP_ICON_NAME) $(APP_PLIST)
	@plutil -insert CFBundleIdentifier -string $(APP_BUNDLE_IDENTIFIER) $(APP_PLIST)
	@plutil -insert CFBundleShortVersionString -string $(APP_VERSION) $(APP_PLIST)
	@plutil -insert CFBundleVersion -string $(APP_VERSION) $(APP_PLIST)
	@plutil -insert LSUIElement -bool true $(APP_PLIST)
	@plutil -insert CFBundleURLTypes -json '[{"CFBundleURLName":"Web site URL","CFBundleURLSchemes":["http","https"]}]' $(APP_PLIST)
	@plutil -insert CFBundleDocumentTypes -json '[{"CFBundleTypeRole":"Viewer","CFBundleTypeName":"HTML document","LSItemContentTypes":["public.html"]},{"CFBundleTypeRole":"Viewer","CFBundleTypeName":"XHTML document","LSItemContentTypes":["public.xhtml"]}]' $(APP_PLIST)

	@##### Remove unneeded files
	rm -f $(APP_BUNDLE)/Contents/Resources/applet.icns
	rmdir $(APP_BUNDLE)/Contents/_CodeSignature

	@##### Copy app icon
	cp ./resources/$(APP_ICON_NAME).icns $(APP_BUNDLE)/Contents/Resources

sign: build ## Sign app bundle for local usage
	codesign --force --deep --sign - $(APP_BUNDLE)

version: ## Pring current version
	@#@echo Git tag: $(GIT_TAG)
	@echo Version: $(APP_VERSION)

package: build ## Package the app to zip archive for distribution
	ditto -c -k --norsrc --noextattr --noqtn --keepParent $(APP_BUNDLE) $(BUILD_DIR)/$(APP_NAME).zip

help: ## Print this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
