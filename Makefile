all:
	@mkdir -p Kite.app/Contents/MacOS
	clang++ -std=c++17 -fobjc-arc \
		-mmacosx-version-min=11.0 \
		Sources/main.mm \
		-framework Cocoa \
		-framework WebKit \
		-framework QuartzCore \
		-o Kite.app/Contents/MacOS/Kite
	@cp -f Info.plist Kite.app/Contents/Info.plist
	@codesign --force --deep --sign - Kite.app

clean:
	rm -rf Kite Kite.app Kite-v1.0.0-beta.macOS.zip
