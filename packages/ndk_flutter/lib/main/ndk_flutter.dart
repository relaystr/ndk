import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk_amber/ndk_amber.dart';
import 'package:ndk_flutter/main/config.dart';
import 'package:ndk_flutter/models/accounts.dart';
import 'package:ndk_flutter/models/nip_05_result.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class NdkFlutter {
  final Ndk ndk;
  final String npubSeparator;
  final int npubPrefixLength;
  final int npubSuffixLength;

  NdkFlutter({
    required this.ndk,
    this.npubSeparator = '…',
    this.npubPrefixLength = 10,
    this.npubSuffixLength = 4,
  });

  String formatNpub(String pubkey) {
    final npub = Nip19.encodePubKey(pubkey);
    final prefix = npub.substring(0, npubPrefixLength);
    final suffix = npub.substring(npub.length - npubSuffixLength);
    return '$prefix$npubSeparator$suffix';
  }

  static Color getColorFromPubkey(String pubkey) {
    // Hash the pubkey using SHA-256 for better distribution
    final bytes = utf8.encode(pubkey);
    final digest = sha256.convert(bytes);

    // Use first 3 bytes of hash for RGB values
    final hashBytes = digest.bytes;
    final r = hashBytes[0];
    final g = hashBytes[1];
    final b = hashBytes[2];

    // Create color from RGB values
    final color = Color.fromARGB(255, r, g, b);

    // Convert to HSL to ensure good visibility
    final hslColor = HSLColor.fromColor(color);

    // Adjust saturation and lightness for better visibility
    // Keep hue from hash but ensure readable colors
    final adjustedHslColor = hslColor.withSaturation(0.6).withLightness(0.45);

    return adjustedHslColor.toColor();
  }

  static Future<Nip05Result> fetchNip05(String nip05) async {
    try {
      final parts = nip05.split('@');
      if (parts.length != 2) {
        return Nip05Result(
          error: 'Invalid NIP-05 format. Expected format: name@domain.com',
        );
      }

      final name = parts[0];
      final domain = parts[1];

      final uri = Uri.https(domain, '/.well-known/nostr.json', {"name": name});
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return Nip05Result(
          error: 'Failed to fetch NIP-05 data: ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final names = json['names'] as Map<String, dynamic>?;
      final relays = json['relays'] as Map<String, dynamic>?;

      if (names == null || !names.containsKey(name)) {
        return Nip05Result(error: 'Name not found in NIP-05 data');
      }

      final pubkey = names[name] as String;
      final userRelays = relays?[pubkey] as List<dynamic>?;

      return Nip05Result(pubkey: pubkey, relays: userRelays?.cast<String>());
    } catch (e) {
      return Nip05Result(error: 'Error fetching NIP-05: $e');
    }
  }

  Future<void> saveAccountsState() async {
    final accounts = NostrWidgetsAccounts(accounts: []);

    for (var account in ndk.accounts.accounts.values) {
      if (account.signer is Nip07EventSigner) {
        accounts.accounts.add(
          NostrAccount(kind: AccountKinds.nip07, pubkey: account.pubkey),
        );
        continue;
      }

      if (account.signer is AmberEventSigner) {
        accounts.accounts.add(
          NostrAccount(kind: AccountKinds.amber, pubkey: account.pubkey),
        );
        continue;
      }

      if (account.signer is Nip46EventSigner) {
        final signer = account.signer as Nip46EventSigner;
        accounts.accounts.add(
          NostrAccount(
            kind: AccountKinds.bunker,
            pubkey: account.pubkey,
            signerSeed: jsonEncode(signer.connection),
          ),
        );
        continue;
      }

      if (account.type == AccountType.privateKey) {
        final signer = account.signer as Bip340EventSigner;
        if (signer.privateKey == null) continue;
        accounts.accounts.add(
          NostrAccount(
            kind: AccountKinds.privkey,
            pubkey: account.pubkey,
            signerSeed: signer.privateKey!,
          ),
        );
        continue;
      }

      if (account.type == AccountType.publicKey) {
        accounts.accounts.add(
          NostrAccount(kind: AccountKinds.pubkey, pubkey: account.pubkey),
        );
        continue;
      }
    }

    accounts.loggedAccount = ndk.accounts.getPublicKey();

    final storage = FlutterSecureStorage();
    await storage.write(key: accountsKey, value: jsonEncode(accounts));
  }

  Future<void> restoreAccountsState() async {
    final storage = FlutterSecureStorage();

    final storedAccounts = await storage.read(key: accountsKey);

    if (storedAccounts == null) return;

    final accounts = NostrWidgetsAccounts.fromJson(jsonDecode(storedAccounts));

    for (var account in accounts.accounts) {
      if (account.kind == AccountKinds.nip07) {
        final signer = Nip07EventSigner();
        ndk.accounts.addAccount(
          pubkey: account.pubkey,
          type: AccountType.externalSigner,
          signer: signer,
        );
        continue;
      }

      if (account.kind == AccountKinds.amber) {
        final amber = Amberflutter();
        final amberFlutterDS = AmberFlutterDS(amber);

        ndk.accounts.addAccount(
          pubkey: account.pubkey,
          type: AccountType.externalSigner,
          signer: AmberEventSigner(
            publicKey: account.pubkey,
            amberFlutterDS: amberFlutterDS,
          ),
        );
        continue;
      }

      if (account.kind == AccountKinds.bunker) {
        final signer = Nip46EventSigner(
          connection: BunkerConnection.fromJson(
            jsonDecode(account.signerSeed!),
          ),
          requests: ndk.requests,
          broadcast: ndk.broadcast,
        );
        ndk.accounts.addAccount(
          pubkey: account.pubkey,
          type: AccountType.externalSigner,
          signer: signer,
        );
        continue;
      }

      if (account.kind == AccountKinds.pubkey) {
        ndk.accounts.addAccount(
          pubkey: account.pubkey,
          type: AccountType.publicKey,
          signer: Bip340EventSigner(
            privateKey: null,
            publicKey: account.pubkey,
          ),
        );
        continue;
      }

      if (account.kind == AccountKinds.privkey) {
        final pubkey = Bip340.getPublicKey(account.signerSeed!);
        ndk.accounts.addAccount(
          pubkey: pubkey,
          type: AccountType.privateKey,
          signer: Bip340EventSigner(
            privateKey: account.signerSeed!,
            publicKey: pubkey,
          ),
        );
        continue;
      }
    }

    if (accounts.loggedAccount == null) return;
    if (!ndk.accounts.hasAccount(accounts.loggedAccount!)) return;
    ndk.accounts.switchAccount(pubkey: accounts.loggedAccount!);
  }
}
