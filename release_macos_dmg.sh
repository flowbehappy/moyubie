flutter build macos
mkdir -p ./release
rm -rf ./release/Moyubie-Installer.dmg
rm -rf ./release/rw.Moyubie-Installer.dmg
create-dmg \
  --volname "Moyubie Installer" \
  --volicon "./build/macos/Build/Products/Release/moyubie.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Moyubie.app" 200 190 \
  --hide-extension "Moyubie.app" \
  --app-drop-link 600 185 \
  "./release/Moyubie-Installer.dmg" \
  "./build/macos/Build/Products/Release/moyubie.app"
