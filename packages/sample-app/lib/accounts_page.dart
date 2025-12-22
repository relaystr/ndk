import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/usecases/bunkers/models/nostr_connect.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart' as bip340_utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart' as nip19_decoder;
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class AccountsPage extends StatefulWidget {
  final VoidCallback? onAccountChanged;

  const AccountsPage({super.key, this.onAccountChanged});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _privateKeyController = TextEditingController();
  final _publicKeyController = TextEditingController();
  final _bunkerUrlController = TextEditingController();
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

  Future<void> _loginWithRandomKey() async {
    try {
      final KeyPair keyPair = bip340_utils.Bip340.generatePrivateKey();

      ndk.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );
      _loadCurrentUser();
      _loadAccounts();
      widget.onAccountChanged?.call();

      // Show dialog with the generated keys so user can save them
      if (mounted) {
        _showGeneratedKeysDialog(keyPair);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate random key: $e')),
      );
    }
  }

  void _showGeneratedKeysDialog(KeyPair keyPair) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Account Created'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ IMPORTANT: Save your private key (nsec) securely! '
                  'You will need it to recover your account.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 16),
                Text('Private Key (nsec):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.red[50],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          keyPair.privateKeyBech32 ?? '',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: keyPair.privateKeyBech32 ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Private key copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Public Key (npub):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          keyPair.publicKeyBech32 ?? '',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: keyPair.publicKeyBech32 ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Public key copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('I have saved my keys'),
            ),
          ],
        );
      },
    );
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
        widget.onAccountChanged?.call(); // Notify listener
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
        widget.onAccountChanged?.call(); // Notify listener
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

      if (amberResult is Map && amberResult.containsKey('signature')) {
        pubkeyFromAmberNpub = amberResult['signature'] as String?;
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
        widget.onAccountChanged?.call(); // Notify listener
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

  Future<void> _loginWithBunkerUrl() async {
    final bunkerUrl = _bunkerUrlController.text;
    if (bunkerUrl.isNotEmpty) {
      // Show loading dialog while waiting for bunker confirmation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Bunker Login'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Connecting to bunker...',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Please confirm the connection in your bunker app if prompted.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      try {
        await ndk.accounts.loginWithBunkerUrl(
          bunkerUrl: bunkerUrl,
          bunkers: ndk.bunkers,
          authCallback: (authUrl) {
            // Handle auth URL - show it in a proper dialog
            _showAuthUrlDialog(authUrl);
          },
        );

        // Close the loading dialog on success
        if (mounted) {
          Navigator.of(context).pop();
          _loadCurrentUser();
          _loadAccounts();
          widget.onAccountChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged in with bunker URL!')),
          );
        }
      } catch (e) {
        // Close dialog on error
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bunker URL login failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _loginWithNostrConnect() async {
    try {
      // Create NostrConnect with nsec.app relay
      final nostrConnect = NostrConnect(
        relays: ['wss://relay.nsec.app'],
        appName: 'NDK Sample App',
      );

      // Show the nostr connect URL in a dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Nostr Connect'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Paste this URL in your nsecbunker to authorize the connection:'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    nostrConnect.nostrConnectURL,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: nostrConnect.nostrConnectURL));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('URL copied to clipboard!')),
                          );
                        },
                        child: Text('Copy URL'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Waiting for authorization...',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      // Try to connect with NostrConnect
      await ndk.accounts.loginWithNostrConnect(
        nostrConnect: nostrConnect,
        bunkers: ndk.bunkers,
        authCallback: (authUrl) {
          // Handle auth URL - show it in a proper dialog
          _showAuthUrlDialog(authUrl);
        },
      );

      // Close the dialog on success
      if (mounted) {
        Navigator.of(context).pop();
        _loadCurrentUser();
        _loadAccounts();
        widget.onAccountChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in with Nostr Connect!')),
        );
      }
    } catch (e) {
      // Close dialog on error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nostr Connect login failed: $e')),
        );
      }
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
      // _loadAccounts(); // _loadCurrentUser already fetches metadata for the new user, and _loadAccounts might be redundant here unless specifically needed for the accounts list UI immediately.
      widget.onAccountChanged?.call(); // Notify listener
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
    widget.onAccountChanged?.call(); // Notify listener
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out')),
    );
  }

  void _showAuthUrlDialog(String authUrl) {
    if (!mounted) return;

    final isHttpsUrl = authUrl.startsWith('https://');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Authorization Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please complete the authorization process using the URL below:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: SelectableText(
                  authUrl,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isHttpsUrl ? Colors.blue : Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: authUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('URL copied to clipboard!')),
                        );
                      },
                      icon: Icon(Icons.copy),
                      label: Text('Copy URL'),
                    ),
                  ),
                  if (isHttpsUrl) ...[
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(authUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open URL')),
                            );
                          }
                        },
                        icon: Icon(Icons.open_in_browser),
                        label: Text('Open URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
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
              ElevatedButton.icon(
                onPressed: () async {
                  await _loginWithRandomKey();
                  if (mounted && _currentAccount != null) {
                    setState(() {
                      _isAddingAccount = false;
                    });
                  }
                },
                icon: const Icon(Icons.casino),
                label: const Text('Generate Random Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
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
                child: const Text('Login with Private Key'),
              ),
              const SizedBox(height: 20),
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
                child: const Text('Login with Public Key'),
              ),
              if (_amberIsAvailable) ...[
                const SizedBox(height: 20),
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
                  child: const Text('Login with Amber'),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _bunkerUrlController,
                decoration: const InputDecoration(
                    hintText:
                        'Enter bunker URL (bunker://pubkey@relay?secret=...)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _loginWithBunkerUrl();
                  if (mounted && _currentAccount != null) {
                    // If login was successful
                    setState(() {
                      _isAddingAccount =
                          false; // Exit adding mode after successful login
                    });
                  }
                },
                child: const Text('Login with Bunker URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _loginWithNostrConnect();
                  if (mounted && _currentAccount != null) {
                    // If login was successful
                    setState(() {
                      _isAddingAccount =
                          false; // Exit adding mode after successful login
                    });
                  }
                },
                child: const Text('Login with Nostr Connect'),
              ),
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
                  final accountPubkeyHex = _accounts[index];
                  final metadata = _userMetadataCache[accountPubkeyHex];
                  final npub =
                      nip19_decoder.Nip19.encodePubKey(accountPubkeyHex);
                  final displayName =
                      metadata?.name ?? metadata?.displayName ?? npub;

                  ImageProvider? avatarImage;
                  if (metadata?.picture != null &&
                      metadata!.picture!.isNotEmpty) {
                    avatarImage = NetworkImage(metadata.picture!);
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatarImage,
                      onBackgroundImageError: avatarImage != null
                          ? (exception, stackTrace) {
                              print(
                                  'Error loading avatar for $npub: $exception');
                              // Optionally update UI to show placeholder if error occurs after initial load attempt
                              // For simplicity, this example relies on initial null check for placeholder
                            }
                          : null,
                      child:
                          avatarImage == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(npub), // Show npub as subtitle
                    trailing: _currentAccount == accountPubkeyHex
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _switchAccount(accountPubkeyHex),
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
