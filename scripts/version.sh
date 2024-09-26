#!/bin/bash

CURR_VERSION=ndk-v`awk '/^version: /{print $2}' packages/ndk/pubspec.yaml`

# iOS & macOS
APPLE_HEADER="release_tag_name = '$CURR_VERSION' # generated; do not edit"
sed -i.bak "1 s/.*/$APPLE_HEADER/" packages/flutter_ndk/ios/flutter_ndk.podspec
sed -i.bak "1 s/.*/$APPLE_HEADER/" packages/flutter_ndk/macos/flutter_ndk.podspec
rm packages/flutter_ndk/macos/*.bak packages/flutter_ndk/ios/*.bak

# CMake platforms (Linux, Windows, and Android)
CMAKE_HEADER="set(LibraryVersion \"$CURR_VERSION\") # generated; do not edit"
for CMAKE_PLATFORM in android linux windows
do
    sed -i.bak "1 s/.*/$CMAKE_HEADER/" packages/flutter_ndk/$CMAKE_PLATFORM/CMakeLists.txt
    rm packages/flutter_ndk/$CMAKE_PLATFORM/*.bak
done

git add packages/flutter_ndk/