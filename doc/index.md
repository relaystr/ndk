---
label: Home
order: 101
icon: home
---

# Dart Nostr Development Kit (NDK)

[![Build Status](https://github.com/relaystr/ndk/actions/workflows/tests.yaml/badge.svg?branch=master)](https://github.com/relaystr/ndk/actions?query=workflow%3A"tests"+branch%3Amaster) [![Coverage](https://img.shields.io/codecov/c/github/relaystr/ndk?color=green)](https://codecov.io/github/relaystr/ndk) [![Pub](https://img.shields.io/pub/v/ndk.svg)](https://pub.dev/packages/ndk) [![License](https://img.shields.io/github/license/relaystr/ndk.svg)](LICENSE.txt)

NDK (Nostr Development Kit) is a Dart library that enhances the Nostr development experience.\
NDK supplies you with high-level usecases like lists or metadata while still allowing you to use low-level queries enhanced with inbox/outbox (gossip) by default.\
Our Target is to make it easy to build constrained Nostr clients, particularly for mobile devices.

## Apps using NDK

- [sample app](https://github.com/relaystr/ndk/releases)
- [yana](https://github.com/frnandu/yana)
- [camelus](https://github.com/leo-lox/camelus)
- [zap.stream](https://github.com/nostrlabs-io/zap-stream-flutter)
- [zapstore](https://github.com/zapstore/zapstore)
- [freeflow](https://github.com/nostrlabs-io/freeflow)
- [hostr](https://github.com/sudonym-btc/hostr)
- [bitblik](https://github.com/bitblik-user)
- [donow](https://github.com/nogringo/donow)
- [submarine](https://github.com/nogringo/submarine)

# ➡️ [Getting Started 🔗](https://dart-nostr.com/guides/getting-started/)

# [Changelog 🔗](./CHANGELOG.md)

---

## Core Features

### Network & Data Management

- **Automatic relay discovery** using inbox/outbox (gossip) model for optimal relay selection
- **Flexible data fetching** with query (one-time) and subscription (real-time) modes
- **Smart caching** to reduce network bandwidth and improve performance
- **Concurrent event streaming** from both cache and network
- **Request coverage control** to specify desired relay coverage per request

### Account & Authentication

- **Multiple signer support**: Built-in (BIP-340), Amber, NIP-07 (web), and NIP-46 (remote signing/bunkers)
- **Account management** with state tracking and multiple account support
- **Relay authentication** (NIP-42) for private relay access

### High-Level Use Cases

- **Metadata management**: Query and update user profiles with automatic caching
- **Contact lists**: Follow/unfollow users and manage contact lists
- **NIP-51 lists**: Public and private relay sets, mute lists, and custom lists
- **Gift wrap** (NIP-59): Encrypted, metadata-obscured messaging
- **Zaps** (NIP-57): Lightning payments on Nostr
- **Nostr Wallet Connect** (NIP-47): Integrate Lightning wallets
- **Domain verification** (NIP-05): Verify and cache Nostr addresses
- **File management**: Upload, download, and delete files using Blossom servers
- **Connectivity**: Get notified about connection issues
- **Proof of Work** (NIP-13): Create and verify PoW events

### Developer Experience

- **Pluggable architecture**: Bring your own cache, verifier, or signer, replace any component
- **Multiple database options**: In-memory, ObjectBox, Sembast
- **Event verification**: BIP-340 or Rust-based (recommended for performance)
- **Comprehensive logging** with configurable log levels and outputs
- **Clean architecture** for maintainability and extensibility

## not Included

- ready to use feeds, you have to build them on your own (🚫 not planned)
- create && manage keypairs. You have to provide them (🚫 not planned)
- threading, you can do this on your own if you move ndk or only the event_verifier into its own thread (🔜 planned)
- support for request overrides (you have to close and reopen requests) (🚫 not planned)
