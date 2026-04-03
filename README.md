# Dart Nostr Development Kit (NDK)

[![Build Status](https://github.com/relaystr/ndk/actions/workflows/tests.yaml/badge.svg?branch=master)](https://github.com/relaystr/ndk/actions?query=workflow%3A"tests"+branch%3Amaster)
[![Coverage](https://img.shields.io/codecov/c/github/relaystr/ndk?color=green)](https://codecov.io/github/relaystr/ndk)
[![Pub](https://img.shields.io/pub/v/ndk.svg)](https://pub.dev/packages/ndk)
[![License](https://img.shields.io/github/license/relaystr/ndk.svg)](LICENSE.txt)

NDK (Nostr Development Kit) is a Dart library that enhances the Nostr development experience.\
NDK supplies you with high-level usecases like lists or metadata while still allowing you to use low-level queries enhanced with inbox/outbox (gossip) by default.\
Our Target is to make it easy to build constrained Nostr clients, particularly for mobile devices.

# Get started here ➡️ [Documentation](https://dart-nostr.com/)

## [🔗 Contributing](https://dart-nostr.com/library-development/contributing/)

## Monorepo Packages

NDK ships in small packages to allow granular control of dependencies in your dart/flutter projects.

### [🔗 Dart Nostr Development Kit (NDK)](./packages/ndk/#readme)

Core package of the NDK. Go here for instructions on how to use the NDK. 📜

### [🔗 nip07 event signer](./packages/nip07_event_signer/)

NIP-07 signer compatible with the NDK.

### [🔗 ObjectBox](./packages/objectbox/)

ObjectBox database implementation.

### [🔗 Ndk Flutter](./packages/ndk_flutter/)

Flutter widgets and utilities that require Flutter as a dependency.

### [🔗 sample app](./packages/sample-app/)

example app using the NDK.
