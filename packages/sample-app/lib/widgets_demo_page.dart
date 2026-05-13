import 'package:flutter/material.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'main.dart';

class WidgetsDemoPage extends StatefulWidget {
  const WidgetsDemoPage({super.key});

  @override
  State<WidgetsDemoPage> createState() => _WidgetsDemoPageState();
}

class _WidgetsDemoPageState extends State<WidgetsDemoPage> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loggedPubkey = ndk.accounts.getPublicKey();
    final isLoggedIn = loggedPubkey != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.widgetsPageTitle),
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
                          l10n.widgetsLoginHint,
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
              description: l10n.widgetsSectionNNameDescription,
              child: isLoggedIn
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(l10n.widgetsCurrentUser),
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
              description: l10n.widgetsSectionNPictureDescription,
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
                                Text(l10n.widgetsSizeDefault),
                              ],
                            ),
                            Column(
                              children: [
                                NPicture(
                                  ndkFlutter: ndkFlutter,
                                  circleAvatarRadius: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.widgetsSizeLarger),
                              ],
                            ),
                            Column(
                              children: [
                                NPicture(
                                  ndkFlutter: ndkFlutter,
                                  circleAvatarRadius: 50,
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.widgetsSizeLarge),
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
              description: l10n.widgetsSectionNBannerDescription,
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
              description: l10n.widgetsSectionNUserProfileDescription,
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
              description: l10n.widgetsSectionNSwitchAccountDescription,
              child: isLoggedIn
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: NSwitchAccount(
                          ndkFlutter: ndkFlutter,
                          onAccountSwitch: (pubkey) {
                            setState(() {});
                          },
                          onAccountRemove: (pubkey) {
                            setState(() {});
                          },
                        ),
                      ),
                    )
                  : _buildPlaceholder('NSwitchAccount widget'),
            ),

            // NLogin Widget Section
            _buildSection(
              title: 'NLogin',
              description: l10n.widgetsSectionNLoginDescription,
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
                          label: Text(l10n.widgetsShowLoginWidget),
                        ),
                      if (_showLogin) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.widgetsLoginWidgetTitle,
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
              description: l10n.widgetsSectionGetColorDescription,
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
    final l10n = context.l10n;
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            l10n.widgetsRequiresLogin(widgetName),
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
