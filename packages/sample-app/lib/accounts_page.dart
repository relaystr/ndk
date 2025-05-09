import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart' as bip340_utils;
// Direct imports for NIP-19 and BIP-340 utilities as they are not exported by ndk_library
import 'package:ndk/shared/nips/nip19/nip19.dart' as nip19_decoder;

import 'main.dart'; // Import main.dart to access ndk and amberAvailable

// Assuming you have an NdkProvider or similar to access NDK instance
// and an AmberService for external signer.
// import 'package:sample_app/providers/ndk_provider.dart';
// import 'package:sample_app/services/amber_service.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _privateKeyController = TextEditingController();
  final _publicKeyController = TextEditingController();
  String? _currentAccount; // Stores hex pubkey of the current user
  List<String> _accounts = // Stores list of known hex pubkeys
      []; // This would ideally be managed by NDK's account manager
  bool _isAddingAccount =
      false; // To toggle account addition form when logged in
  Map<String, Metadata> _userMetadataCache = {}; // Cache for user metadata

  late Amberflutter _amberService; // Amberflutter instance
  bool _amberIsAvailable = false;

  @override
  void initState() {
    super.initState();
    // _ndkInstance = ndk; // Use global 'ndk' directly
    _amberService = Amberflutter(); // Initialize Amberflutter
    _amberIsAvailable = amberAvailable; // Use amberAvailable from main.dart
    _loadCurrentUser();
    _loadAccounts();
  }

  Future<void> _fetchAndCacheMetadata(String pubkeyHex) async {
    if (_userMetadataCache.containsKey(pubkeyHex) &&
        _userMetadataCache[pubkeyHex]!.name != null) {
      // Already fetched and has a name, or a fetch attempt was made.
      // To avoid refetching constantly for users with no set name, we might need a more nuanced check
      // or rely on NDK's internal caching for fetch, but for UI, once attempted, we use what we have.
      return;
    }
    try {
      // Corrected: use loadMetadata instead of fetch
      final metadata = await ndk.metadata.loadMetadata(pubkeyHex);
      if (mounted && metadata != null) {
        setState(() {
          _userMetadataCache[pubkeyHex] = metadata;
        });
      } else if (mounted && !_userMetadataCache.containsKey(pubkeyHex)) {
        // If fetch returned null and we don't have any old cache,
        // store a placeholder or an empty Metadata to prevent refetch loops for non-existent metadata.
        // For simplicity, we can just ensure the key exists to prevent re-fetch,
        // or handle it by checking metadata.name presence.
        // Let's assume NDK handles not finding metadata gracefully and won't spam relays.
        // If metadata is null, we'll just display the pubkey.
      }
    } catch (e) {
      if (mounted) {
        // Optionally, show a snackbar or log error
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to fetch metadata for $pubkeyHex: $e')),
        // );
        print('Failed to fetch metadata for $pubkeyHex: $e');
      }
    }
  }

  Future<void> _loginWithPrivateKey() async {
    final privateKey = _privateKeyController.text;
    if (privateKey.isNotEmpty) {
      try {
        // NDK loginPrivateKey expects pubkey and privkey.
        // We need to derive pubkey from privkey or ask the user for it.
        // For simplicity, let's assume privkey is nsec and derive pubkey.
        // This is a simplification; robust key handling is more complex.

        // Validate that the input is an nsec key.
        if (!nip19_decoder.Nip19.isPrivateKey(privateKey)) {
          // Use isPrivateKey for validation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Invalid private key format, expected nsec.')),
          );
          return;
        }
        final String hexPrivkey =
            nip19_decoder.Nip19.decode(privateKey); // Returns hex string
        if (hexPrivkey.isEmpty) {
          // Check if decoding failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to decode private key.')),
          );
          return;
        }

        // Use NDK's Bip340 utility to get the public key from the private key.
        final String pubkeyHex = bip340_utils.Bip340.getPublicKey(hexPrivkey);

        // Now call NDK's login method which will create its own signer internally.
        ndk.accounts.loginPrivateKey(
            pubkey: pubkeyHex, privkey: hexPrivkey); // Pass hex private key
        _loadCurrentUser();
        _loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in with private key!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Private key login failed: $e')),
        );
      }
    }
  }

  Future<void> _loginWithPublicKey() async {
    final publicKey = _publicKeyController.text;
    if (publicKey.isNotEmpty) {
      try {
        // NDK loginPublicKey expects a hex pubkey.
        // If user enters npub, we need to decode it.
        String hexPubkey = publicKey;
        if (nip19_decoder.Nip19.isPubkey(publicKey)) {
          // Use isPubkey for validation
          hexPubkey =
              nip19_decoder.Nip19.decode(publicKey); // Returns hex string
          if (hexPubkey.isEmpty) {
            // Check if decoding failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to decode public key.')),
            );
            return;
          }
        } else if (publicKey.startsWith("npub")) {
          // This case handles strings that start with "npub" but might not be valid
          // according to the more specific nip19_decoder.Nip19.isPubkey check.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid npub public key format.')),
          );
          return;
        }
        // If not an npub (or if it was already hex), assume hexPubkey is now the hex public key.
        // Further validation for hex format could be added here if necessary.

        ndk.accounts.loginPublicKey(pubkey: hexPubkey); // Use global ndk
        _loadCurrentUser();
        _loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in with public key (read-only)!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Public key login failed: $e')),
        );
      }
    }
  }

  Future<void> _loginWithAmber() async {
    if (!_amberIsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amber is not available on this device.')),
      );
      return;
    }
    try {
      // Request only the public key, no extra permissions needed for read-only login
      final dynamic amberResult = await _amberService.getPublicKey();
      String? pubkeyFromAmberNpub;

      if (amberResult is Map && amberResult.containsKey('publicKey')) {
        pubkeyFromAmberNpub = amberResult['publicKey'] as String?;
      } else if (amberResult is String) {
        // Older versions might return string directly
        pubkeyFromAmberNpub = amberResult;
      }

      if (pubkeyFromAmberNpub != null && pubkeyFromAmberNpub.isNotEmpty) {
        String hexPubkey = pubkeyFromAmberNpub;
        if (nip19_decoder.Nip19.isPubkey(pubkeyFromAmberNpub)) {
          // Use isPubkey for validation
          hexPubkey = nip19_decoder.Nip19.decode(
              pubkeyFromAmberNpub); // Returns hex string
          if (hexPubkey.isEmpty) {
            // Check if decoding failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to decode public key from Amber.')),
            );
            return;
          }
        } else if (pubkeyFromAmberNpub.startsWith("npub")) {
          // This case handles strings that start with "npub" but might not be valid
          // according to the more specific nip19_decoder.Nip19.isPubkey check.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Invalid npub public key format from Amber.')),
          );
          return;
        }
        // If not an npub (or if it was already hex), assume hexPubkey is now the hex public key.
        // Further validation for hex format could be added here if necessary.

        ndk.accounts.loginPublicKey(pubkey: hexPubkey); // Use global ndk
        _loadCurrentUser();
        _loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Logged in with Amber (read-only): $pubkeyFromAmberNpub')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to get public key from Amber or key is empty.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amber login failed: $e')),
      );
    }
  }

  void _loadCurrentUser() {
    final currentAccountPubkey = ndk.accounts.getLoggedAccount()?.pubkey;
    setState(() {
      _currentAccount = currentAccountPubkey;
      if (currentAccountPubkey != null) {
        if (!_accounts.contains(currentAccountPubkey)) {
          _accounts.add(currentAccountPubkey);
        }
        _fetchAndCacheMetadata(currentAccountPubkey);
      }
    });
  }

  void _loadAccounts() {
    final allKnownAccounts = ndk.accounts.accounts.values.toList();
    final allKnownPubkeys =
        allKnownAccounts.map((account) => account.pubkey).toSet().toList();

    setState(() {
      _accounts = allKnownPubkeys;
      if (_currentAccount != null && !_accounts.contains(_currentAccount!)) {
        // This case should ideally not happen if _loadCurrentUser runs after login
        _accounts.add(_currentAccount!);
      }
    });
    // Fetch metadata for all known accounts
    for (var pubkey in _accounts) {
      _fetchAndCacheMetadata(pubkey);
    }
  }

  Future<void> _switchAccount(String pubkey) async {
    try {
      // NDK switchAccount expects a hex pubkey.
      // The list might store npub or hex. Ensure it's hex.
      String hexPubkey = pubkey;
      if (nip19_decoder.Nip19.isPubkey(pubkey)) {
        // Use isPubkey for validation
        hexPubkey = nip19_decoder.Nip19.decode(pubkey); // Returns hex string
        if (hexPubkey.isEmpty) {
          // Check if decoding failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to decode public key for switching.')),
          );
          return;
        }
      } else if (pubkey.startsWith("npub")) {
        // This case handles strings that start with "npub" but might not be valid
        // according to the more specific nip19_decoder.Nip19.isPubkey check.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invalid npub public key format for switching.')),
        );
        return;
      }
      // If not an npub (or if it was already hex), assume hexPubkey is now the hex public key.
      // Further validation for hex format could be added here if necessary.
      ndk.accounts.switchAccount(pubkey: hexPubkey); // Corrected
      _loadCurrentUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to $pubkey')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to switch account: $e')),
      );
    }
  }

  Future<void> _logout() async {
    ndk.accounts.logout(); // Corrected, it's not async
    _loadCurrentUser();
    _loadAccounts(); // This will now reflect that no user is active
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
                'Current Account: ${(_currentAccount != null ? _userMetadataCache[_currentAccount]?.name ?? _userMetadataCache[_currentAccount]?.displayName ?? nip19_decoder.Nip19.encodePubKey(_currentAccount!) : null) ?? "Not logged in"}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            if (_currentAccount == null || _isAddingAccount) ...[
              // Show login/add account forms if not logged in OR if in "adding account" mode
              if (_isAddingAccount && _currentAccount != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingAccount = false;
                      });
                    },
                    child: const Text('Cancel Adding Account'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                  ),
                ),
              Text('Login or Add Private Key (nsec):',
                  style: Theme.of(context).textTheme.titleMedium),
              TextField(
                controller: _privateKeyController,
                decoration:
                    const InputDecoration(hintText: 'Enter your nsec...'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _loginWithPrivateKey();
                  if (mounted && _currentAccount != null) {
                    // If login was successful
                    setState(() {
                      _isAddingAccount =
                          false; // Exit adding mode after successful login
                    });
                  }
                },
                child: const Text('Login/Add with Private Key'),
              ),
              const SizedBox(height: 20),
              Text('Login or Add Public Key (npub, read-only):',
                  style: Theme.of(context).textTheme.titleMedium),
              TextField(
                controller: _publicKeyController,
                decoration:
                    const InputDecoration(hintText: 'Enter your npub...'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _loginWithPublicKey();
                  if (mounted && _currentAccount != null) {
                    // If login was successful
                    setState(() {
                      _isAddingAccount =
                          false; // Exit adding mode after successful login
                    });
                  }
                },
                child: const Text('Login/Add with Public Key'),
              ),
              if (_amberIsAvailable) ...[
                const SizedBox(height: 20),
                Text('Login or Add with External Signer:',
                    style: Theme.of(context).textTheme.titleMedium),
                ElevatedButton(
                  onPressed: () async {
                    await _loginWithAmber();
                    if (mounted && _currentAccount != null) {
                      // If login was successful
                      setState(() {
                        _isAddingAccount =
                            false; // Exit adding mode after successful login
                      });
                    }
                  },
                  child: const Text('Login/Add with Amber'),
                ),
              ],
            ] else ...[
              // Logged in view (not adding account)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingAccount = true;
                      });
                    },
                    child: const Text('Add Another Account'),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Added space
              Text('Available Accounts:',
                  style: Theme.of(context).textTheme.titleMedium),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  return ListTile(
                    title: Text(_userMetadataCache[account]?.name ??
                        _userMetadataCache[account]?.displayName ??
                        nip19_decoder.Nip19.encodePubKey(account)),
                    subtitle: Text(nip19_decoder.Nip19.encodePubKey(
                        account)), // Show npub as subtitle
                    trailing: _currentAccount == account
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _switchAccount(account),
                            child: const Text('Switch'),
                          ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
