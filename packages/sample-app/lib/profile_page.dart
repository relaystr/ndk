import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_demo/login_popup.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class ProfilePage extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String? Function() getLoggedPubkey;
  final VoidCallback? onAccountChanged;

  const ProfilePage({
    super.key,
    required this.ndkFlutter,
    required this.getLoggedPubkey,
    this.onAccountChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _openLoginPopup() {
    showNLoginPopup(
      context: context,
      ndkFlutter: widget.ndkFlutter,
      onLoggedIn: () {
        if (!mounted) return;
        setState(() {});
        widget.onAccountChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedPubkey = widget.getLoggedPubkey();

    if (loggedPubkey == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 32,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.5,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No account logged in.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _openLoginPopup,
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NUserProfile(
            key: ValueKey(loggedPubkey),
            ndkFlutter: widget.ndkFlutter,
            onLogout: () {
              setState(() {});
              widget.onAccountChanged?.call();
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<Metadata?>(
            future: widget.ndkFlutter.ndk.metadata.loadMetadata(loggedPubkey),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error fetching metadata: ${snapshot.error}'),
                  ),
                );
              }

              final about = snapshot.data?.about?.trim();
              if (about == null || about.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(about),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
