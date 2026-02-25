import 'package:flutter/material.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'main.dart';

class WidgetsDemoPage extends StatefulWidget {
  final VoidCallback? onAccountChanged;

  const WidgetsDemoPage({super.key, this.onAccountChanged});

  @override
  State<WidgetsDemoPage> createState() => _WidgetsDemoPageState();
}

class _WidgetsDemoPageState extends State<WidgetsDemoPage> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    final loggedPubkey = ndk.accounts.getPublicKey();
    final isLoggedIn = loggedPubkey != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NDK Flutter Widgets Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info message
            if (!isLoggedIn)
              Card(
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log in via the "Accounts" tab to see personalized widgets.',
                          style: TextStyle(color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isLoggedIn) const SizedBox(height: 24),

            // NName Widget Section
            _buildSection(
              title: 'NName',
              description:
                  'Displays user name from metadata, falls back to formatted npub.',
              child: isLoggedIn
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Text('Current user: '),
                            NName(ndkFlutter: ndkFlutter),
                          ],
                        ),
                      ),
                    )
                  : _buildPlaceholder('NName widget'),
            ),

            // NPicture Widget Section
            _buildSection(
              title: 'NPicture',
              description:
                  'Displays user profile picture with fallback to initials.',
              child: isLoggedIn
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                NPicture(
                                  ndkFlutter: ndkFlutter,
                                  circleAvatarRadius: 30,
                                ),
                                const SizedBox(height: 8),
                                const Text('Default'),
                              ],
                            ),
                            Column(
                              children: [
                                NPicture(
                                  ndkFlutter: ndkFlutter,
                                  circleAvatarRadius: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text('Larger'),
                              ],
                            ),
                            Column(
                              children: [
                                NPicture(
                                  ndkFlutter: ndkFlutter,
                                  circleAvatarRadius: 50,
                                ),
                                const SizedBox(height: 8),
                                const Text('Large'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildPlaceholder('NPicture widget'),
            ),

            // NBanner Widget Section
            _buildSection(
              title: 'NBanner',
              description:
                  'Displays user banner image with fallback to colored container.',
              child: isLoggedIn
                  ? Card(
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: NBanner(ndkFlutter: ndkFlutter),
                        ),
                      ),
                    )
                  : _buildPlaceholder('NBanner widget'),
            ),

            // NUserProfile Widget Section
            _buildSection(
              title: 'NUserProfile',
              description:
                  'Complete user profile with banner, picture, name, and NIP-05.',
              child: isLoggedIn
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: NUserProfile(
                          ndkFlutter: ndkFlutter,
                          showLogoutButton: false,
                        ),
                      ),
                    )
                  : _buildPlaceholder('NUserProfile widget'),
            ),

            // NSwitchAccount Widget Section
            _buildSection(
              title: 'NSwitchAccount',
              description:
                  'Account management widget with switching and logout.',
              child: isLoggedIn
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: NSwitchAccount(
                          ndkFlutter: ndkFlutter,
                          onAccountSwitch: (pubkey) {
                            setState(() {});
                            widget.onAccountChanged?.call();
                          },
                          onAccountRemove: (pubkey) {
                            setState(() {});
                            widget.onAccountChanged?.call();
                          },
                        ),
                      ),
                    )
                  : _buildPlaceholder('NSwitchAccount widget'),
            ),

            // NLogin Widget Section
            _buildSection(
              title: 'NLogin',
              description:
                  'Login widget with multiple auth methods (NIP-05, npub, nsec, bunker, etc.).',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_showLogin)
                        FilledButton.icon(
                          onPressed: () => setState(() => _showLogin = true),
                          icon: const Icon(Icons.login),
                          label: const Text('Show NLogin Widget'),
                        ),
                      if (_showLogin) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NLogin Widget',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _showLogin = false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(),
                        NLogin(
                          ndkFlutter: ndkFlutter,
                          onLoggedIn: () {
                            setState(() => _showLogin = false);
                            widget.onAccountChanged?.call();
                          },
                          enableNip07Login: false,
                          enableAmberLogin: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Color from pubkey demo
            _buildSection(
              title: 'getColorFromPubkey',
              description:
                  'Static method that generates deterministic colors from pubkeys.',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildColorDemo('npub1abc...'),
                      _buildColorDemo('npub1xyz...'),
                      _buildColorDemo('npub1def...'),
                      _buildColorDemo('npub1ghi...'),
                      _buildColorDemo('npub1jkl...'),
                      _buildColorDemo('npub1mno...'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPlaceholder(String widgetName) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            '$widgetName\n(requires login)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildColorDemo(String fakePubkey) {
    final color = NdkFlutter.getColorFromPubkey(fakePubkey);
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fakePubkey.substring(0, 10),
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
