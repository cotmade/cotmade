#!/bin/sh

# ci_post_clone.sh
# Runner

# Make sure to setup XCode Cloud and link your repo to trigger the build

# Created by logickoder on 17/09/2024 with help from Dirisu Jesse
#

# Fail this script if any subcommand fails.
#set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b 3.22.0 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install FlutterFire CLI
echo "Installing FlutterFire CLI..."
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Install Flutter artifacts for iOS (--ios) platform.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
pod install # run `pod install` in the `ios` directory.

# Check flutter installation health
flutter doctor -v

# Build iOS app
# xcodebuild -project Runner.xcodeproj -archivePath ../../build/ios/archive/Runner.xcarchive
flutter build ios --release

# Close out successfully
exit 0