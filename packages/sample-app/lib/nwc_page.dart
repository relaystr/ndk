import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_kind.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc_notification.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/nwc_response.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class NwcPage extends StatefulWidget {
  const NwcPage({super.key});

  @override
  State<NwcPage> createState() => _NwcPageState();
}

class _NwcPageState extends State<NwcPage> with ProtocolListener {
  TextEditingController uri = TextEditingController();
  TextEditingController amount =
      TextEditingController(); // For normal and hold invoice
  // TextEditingController holdAmount = TextEditingController(); // Removed
  TextEditingController description =
      TextEditingController(); // Used if isHoldInvoice is true
  TextEditingController invoice =
      TextEditingController(); // For paying invoices
  NwcConnection? connection;
  KeyPair?
      nwcAppKey; // Our app's NWC keypair, should be generated once and reused.
  GetBalanceResponse? balance;

  // State variables to hold context from the NIP-47 auth initiation
  String?
      _pendingDiscoveryRelayUrl; // The relay specified in the nostr+walletauth URI's 'relay=' param,
  // where we expect the kind 13194 event to be.
  String?
      _pendingAppPubkeyForAuth; // Our app's pubkey that was sent in the nostr+walletauth URI's 'pubkey=' param
  // and expected in the 'p' tag of the kind 13194 event.
  MakeInvoiceResponse?
      makeInvoice; // Will store result of normal or hold invoice creation
  PayInvoiceResponse? payInvoice;

  // MakeInvoiceResponse? makeHoldInvoiceResponse; // Removed, merged into makeInvoice
  String? holdInvoicePreimage;
  String?
      holdInvoicePaymentHash; // Still needed to identify the hold invoice for notifications/settle/cancel
  bool isHoldInvoice = false; // For the checkbox
  bool _currentInvoiceWasHold =
      false; // To track if the current 'makeInvoice' is a hold type
  bool isHoldInvoiceAccepted = false;
  String? holdInvoiceStatusMessage;
  StreamSubscription? holdInvoiceStateSubscription;
  NwcResponse? settleHoldInvoiceResponse;
  NwcResponse? cancelHoldInvoiceResponse;

  // For regular invoice payment notifications
  bool isRegularInvoicePaid = false;
  String? regularInvoiceStatusMessage;
  StreamSubscription? regularInvoicePaymentSubscription;

  @override
  void initState() {
    super.initState();
    protocolHandler.addListener(this);
    uri.addListener(() {
      setState(() {
        if (uri.text == '') {
          connection = null;
          _resetInvoiceStates(); // Reset invoice states if connection URI is cleared
        }
      });
    });
    amount.addListener(() {
      setState(() {});
    });
    // holdAmount.addListener(() { // Removed
    //   setState(() {});
    // });
    description.addListener(() {
      setState(() {});
    });
    invoice.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    uri.dispose();
    amount.dispose();
    // holdAmount.dispose(); // Removed
    description.dispose();
    invoice.dispose();
    holdInvoiceStateSubscription?.cancel();
    regularInvoicePaymentSubscription?.cancel();
    protocolHandler.removeListener(this);
    super.dispose();
  }

  void _resetInvoiceStates() {
    setState(() {
      makeInvoice = null;
      // makeHoldInvoiceResponse = null; // Removed
      holdInvoicePreimage = null;
      holdInvoicePaymentHash = null;
      isHoldInvoiceAccepted = false;
      _currentInvoiceWasHold = false;
      holdInvoiceStatusMessage = null;
      holdInvoiceStateSubscription?.cancel();
      holdInvoiceStateSubscription = null;
      settleHoldInvoiceResponse = null;
      cancelHoldInvoiceResponse = null;

      isRegularInvoicePaid = false;
      regularInvoiceStatusMessage = null;
      regularInvoicePaymentSubscription?.cancel();
      regularInvoicePaymentSubscription = null;
      // isHoldInvoice = false; // Optionally reset checkbox, or leave it as user set
    });
  }

  @override
  void onProtocolUrlReceived(String url) async {
    print('NWC Page: Protocol URL received: $url');

    if (url.startsWith("ndk://nwc") && // Check if it's our NIP-47 callback
        _pendingDiscoveryRelayUrl != null &&
        _pendingAppPubkeyForAuth != null) {
      print('NIP-47 callback received. Processing...');
      print('  Expected discovery relay: $_pendingDiscoveryRelayUrl');
      print('  Expected app pubkey for p tag: $_pendingAppPubkeyForAuth');

      final discoveryRelay = _pendingDiscoveryRelayUrl!;
      final appPubkey = _pendingAppPubkeyForAuth!;

      // Clear pending state now that we are processing it.
      // Important to do this early to prevent reprocessing if another callback comes for an old request.
      setState(() {
        _pendingDiscoveryRelayUrl = null;
        _pendingAppPubkeyForAuth = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'NIP-47 callback received. Fetching wallet connection info from $discoveryRelay...')),
      );

      try {

        // Retrieve the discoveryRelay and appPubkey that were set before launching nostr+walletauth
        // These are final and won't change during this try block.

        final String discoveryRelayForQuery = "wss://relay.getalby.com/v1";
        final String appPubkeyForTag = nwcAppKey!.publicKey;

        // Clear pending state now that we are processing it.
        // Important to do this early to prevent reprocessing if another callback comes for an old request.
        // setState(() {
        //   _pendingDiscoveryRelayUrl = null;
        //   _pendingAppPubkeyForAuth = null;
        // });

        if (nwcAppKey == null || nwcAppKey!.privateKey == null) {
          print(
              'NIP-47 Error: nwcAppKey or its private key is null. Cannot construct NWC URI.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: App NWC key not fully initialized.')),
          );
          return;
        }

        final stream = ndk.requests
            .query(
              filters: [
                Filter(
                  kinds: [NwcKind.INFO.value],
                  pTags: [appPubkeyForTag],
                  limit: 1,
                )
              ],
              explicitRelays: {
                discoveryRelayForQuery
              },
            )
            .stream
            .timeout(const Duration(seconds: 15));

        Nip01Event? foundWalletAuthEvent = await stream.first;
        if (foundWalletAuthEvent == null){
          print(
              'No NWC Info Event (kind ${NwcKind.INFO.value}) found on $discoveryRelayForQuery tagged for $appPubkeyForTag.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'No NWC Info Event found on $discoveryRelayForQuery.')),
          );
          return;
        }

        print(
            'Successfully fetched and validated NWC Info Event (Kind ${NwcKind.INFO.value}):');
        print(
            '  Author (Wallet NWC Service Pubkey): ${foundWalletAuthEvent.pubKey}');

        // Construct the NWC URI as per user's explicit instructions:
        // walletPubKey is the author of the 13194 event
        // relay is the relay passed to nostr+walletauth when connect button is pressed (_pendingDiscoveryRelayUrl)
        // secret is the nwcAppKey the private part

        final String walletNwcServicePubkey = foundWalletAuthEvent.pubKey;
        final String nwcRelayForConnectionUri =
            discoveryRelayForQuery; // This was _pendingDiscoveryRelayUrl
        final String appNwcPrivateKeyForSecret = nwcAppKey!.privateKey!;

        final constructedNwcUri =
            'nostr+walletconnect://$walletNwcServicePubkey?relay=${Uri.encodeComponent(nwcRelayForConnectionUri)}&secret=$appNwcPrivateKeyForSecret';

        print(
            'Constructed NWC connection URI (as per explicit instructions): $constructedNwcUri');

        setState(() {
          uri.text = constructedNwcUri;
        });

        // Now connect using the constructed URI
        // As per user feedback, clientKeyPair is not an argument to connect.
        // The nwcAppKey (specifically its private key) was used as the 'secret' in the constructedNwcUri.
        final NwcConnection? establishedConn = await ndk.nwc.connect(
          constructedNwcUri,
          // clientKeyPair: nwcAppKey, // Removed as per user feedback
          doGetInfoMethod: true,
        );

        if (establishedConn != null) {
          setState(() {
            connection = establishedConn;
            balance = null;
            _resetInvoiceStates();
            // If make_hold_invoice is not permitted, ensure isHoldInvoice is false.
            if (!(connection!.info?.methods
                    .contains(NwcMethod.MAKE_HOLD_INVOICE.name) ??
                false)) {
              isHoldInvoice = false;
            }
          });
          print(
              'Successfully connected to NWC wallet: $walletNwcServicePubkey via $nwcRelayForConnectionUri');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                // Try using 'alias' as per potential GetInfoResponse field, fallback to pubkey
                'NWC Connected to: ${connection?.info?.alias ?? walletNwcServicePubkey.substring(0, 10)}...')),
          );
        } else {
          print('Failed to connect to NWC wallet using the constructed URI.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to establish NWC connection.')),
          );
        }
      } catch (e) {
        print('Error during NIP-47 callback processing: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing NWC callback: $e')),
        );
      }
    } else {
      print(
          'Received unhandled protocol URL or missing pending NIP-47 auth state: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    if (Platform.isAndroid) {
      widgets.add(
        FilledButton(
          onPressed: () async {
            // Always generate a new nwcAppKey for NIP-47 auth when this button is pressed.
            nwcAppKey = Bip340.generatePrivateKey();
            print(
                "Generated new, fresh nwcAppKey for NIP-47 auth: ${nwcAppKey!.publicKey}");
            // No need to call setState here as nwcAppKey is used immediately for URI construction.

            // This is the URI the button currently attempts to launch.
            // As per NIP-47, the host of nostr+walletauth should be our app's pubkey.
            // The 'relay' param is where the auth service (e.g., Alby) is expected to publish the kind 13194 event.
            // The 'pubkey' param in the URI (if NIP-47 spec evolves to include it this way, or if it's part of 'name' or other metadata)
            // would be our app's pubkey. The current URI structure in the code is:
            // "nostr+walletauth://${nwcAppKey!.publicKey}?relay=...&name=Yana&...&return_to=ndk%3A%2F%2Fnwc"

            // Let's parse the URI string that the button *intends* to launch
            // to extract the necessary _pending values.
            // The existing code for the URI is:
            String appName = "Yana"; // Example from existing code
            String appIcon =
                "https%3A%2F%2Fyana.do%2Fimages%2Flogo-new.png"; // Example
            String methods =
                "get_info get_balance get_budget make_invoice pay_invoice lookup_invoice list_transactions sign_message make_hold_invoice cancel_hold_invoice settle_hold_invoice"; // Example
            String discoveryRelay =
                "wss://relay.getalby.com/v1"; // Example from existing code
            String returnTo = "ndk://nwc"; // Example

            // Construct the URI that will be launched.
            // The host is our app's pubkey.
            final Uri launchUri = Uri(
                scheme: 'nostr+walletauth',
                host: nwcAppKey!.publicKey, // Our app's pubkey
                queryParameters: {
                  'relay':
                      discoveryRelay, // Relay for discovering the kind 13194 event
                  'name': appName,
                  'request_methods': methods,
                  'icon': appIcon,
                  'return_to': returnTo,
                  // NIP-47 also suggests a 'pubkey' param for the app's pubkey, but host is also used.
                  // Let's ensure our _pendingAppPubkeyForAuth is nwcAppKey!.publicKey
                });

            // Store the context needed for when onProtocolUrlReceived is called.
            _pendingDiscoveryRelayUrl = discoveryRelay;
            _pendingAppPubkeyForAuth = nwcAppKey!
                .publicKey; // This is the pubkey our app uses for this auth flow.

            print(
                "Attempting to launch NIP-47 Auth URI: ${launchUri.toString()}");
            print(
                "  _pendingDiscoveryRelayUrl set to: $_pendingDiscoveryRelayUrl");
            print(
                "  _pendingAppPubkeyForAuth set to: $_pendingAppPubkeyForAuth");

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Redirecting to wallet for NWC authorization...')),
            );
            try {
              await launchUrl(launchUri, mode: LaunchMode.externalApplication);
            } catch (e) {
              print("Error launching NIP-47 Auth URI: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not launch wallet app: $e')),
              );
              // Clear pending state if launch fails
              _pendingDiscoveryRelayUrl = null;
              _pendingAppPubkeyForAuth = null;
            }
          },
          child: const Text('Connect with Alby Go'), // Updated button text
        ),
      );
    }
    widgets.add(Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: uri,
                onEditingComplete: () {
                  setState(() {});
                },
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                      onPressed: () {
                        Clipboard.getData(Clipboard.kTextPlain)
                            .then((clipboardData) {
                          if (clipboardData != null &&
                              clipboardData.text != null) {
                            setState(() {
                              uri.text = clipboardData.text!;
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.paste)),
                  hintText: "nostr+wallet://... url",
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            )
          ],
        )));
    widgets.add(
      FilledButton(
        onPressed: uri.text.isNotEmpty
            ? () async {
                _resetInvoiceStates(); // Reset states before new connection
                NwcConnection? newConnection =
                    await ndk.nwc.connect(uri.text, doGetInfoMethod: true);
                setState(() {
                  connection = newConnection;
                  balance = null;
                  // If make_hold_invoice is not permitted, ensure isHoldInvoice is false.
                  if (!(connection?.info?.methods
                          .contains(NwcMethod.MAKE_HOLD_INVOICE.name) ??
                      false)) {
                    isHoldInvoice = false;
                  }
                });
              }
            : null,
        child: const Text('Connect and get info'),
      ),
    );
    widgets.add(connection != null && connection!.info != null
        ? Text("Methods ${connection!.info!.methods}")
        : Container());

    widgets.add(const SizedBox(
      height: 20,
    ));
    widgets.add(
      FilledButton(
        onPressed: connection != null
            ? () async {
                final b = await ndk.nwc.getBalance(connection!);
                setState(() {
                  balance = b;
                });
              }
            : null,
        child: const Text('Get Balance'),
      ),
    );
    widgets.add(connection != null && balance != null
        ? Text("Balance ${balance!.balanceSats} sats")
        : Container());

    widgets.add(
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20));

    // Determine if the "Make Invoice" button should be enabled
    bool canSubmitMakeInvoice = connection != null &&
        amount.text.isNotEmpty &&
        (int.tryParse(amount.text) ?? 0) > 0 &&
        (isHoldInvoice
            ? connection!.info!.methods
                .contains(NwcMethod.MAKE_HOLD_INVOICE.name)
            : connection!.info!.methods.contains(NwcMethod.MAKE_INVOICE.name));

    // --- Make Invoice Section ---
    widgets.add(const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text("Make Invoice",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: amount,
                textAlign: TextAlign.center, // Center text within field
                decoration: const InputDecoration(
                  hintText: "Amount in sats",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 250, // Smaller width for description field
              child: TextField(
                controller: description,
                textAlign: TextAlign.center, // Center text
                decoration: InputDecoration(
                  hintText: isHoldInvoice
                      ? "Description (for hold)"
                      : "Description (optional)",
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200, // To help center the checkbox
              child: CheckboxListTile(
                title: const Text("Hold Invoice"),
                value: isHoldInvoice,
                // Disable checkbox if connection is null, info is null, or method is not permitted
                onChanged: (connection != null &&
                        connection!.info != null &&
                        connection!.info!.methods
                            .contains(NwcMethod.MAKE_HOLD_INVOICE.name))
                    ? (bool? value) {
                        setState(() {
                          isHoldInvoice = value ?? false;
                          // Resetting all invoice states might be too aggressive here,
                          // consider if only relevant parts should be reset or if user expects this.
                          // For now, keeping existing _resetInvoiceStates() call.
                          _resetInvoiceStates();
                        });
                      }
                    : null, // Setting onChanged to null disables the checkbox
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              // Keep the button centered
              child: FilledButton(
                onPressed: canSubmitMakeInvoice
                    ? () async {
                        _resetInvoiceStates(); // Clear previous invoice details first
                        final int sats = int.tryParse(amount.text) ?? 0;
                        if (isHoldInvoice) {
                          setState(() {
                            _currentInvoiceWasHold = true;
                            holdInvoiceStatusMessage =
                                "Generating preimage and payment hash...";
                          });

                          final random = Random.secure();
                          final preimageBytes = Uint8List.fromList(
                              List<int>.generate(
                                  32, (_) => random.nextInt(256)));
                          final preimageHex = convert.hex.encode(preimageBytes);

                          final paymentHashBytes =
                              crypto.sha256.convert(preimageBytes).bytes;
                          final paymentHashHex =
                              convert.hex.encode(paymentHashBytes);

                          setState(() {
                            holdInvoicePreimage = preimageHex;
                            holdInvoicePaymentHash = paymentHashHex;
                            holdInvoiceStatusMessage =
                                "Creating hold invoice...";
                          });

                          try {
                            final response = await ndk.nwc.makeHoldInvoice(
                                connection!,
                                amountSats: sats,
                                description: description.text.isNotEmpty
                                    ? description.text
                                    : null, // Pass null if empty
                                paymentHash: paymentHashHex);
                            setState(() {
                              makeInvoice =
                                  response; // Store in the unified makeInvoice
                              if (response.errorCode == null) {
                                holdInvoiceStatusMessage =
                                    "Hold invoice created. Waiting for acceptance...";
                                _listenForHoldInvoiceAcceptance(paymentHashHex);
                              } else {
                                holdInvoiceStatusMessage =
                                    "Error creating hold invoice: ${response.errorMessage}";
                              }
                            });
                          } catch (e) {
                            setState(() {
                              holdInvoiceStatusMessage =
                                  "Exception creating hold invoice: $e";
                            });
                          }
                        } else {
                          // Regular invoice
                          setState(() {
                            _currentInvoiceWasHold = false;
                          });
                          try {
                            final response = await ndk.nwc.makeInvoice(
                              connection!,
                              amountSats: sats,
                              description: description.text.isNotEmpty
                                  ? description.text
                                  : null, // Pass description for both types if not empty
                            );
                            setState(() {
                              makeInvoice = response;
                              if (response.errorCode == null &&
                                  response.paymentHash != null) {
                                regularInvoiceStatusMessage =
                                    "Regular invoice created. Waiting for payment...";
                                _listenForRegularInvoicePayment(
                                    response.paymentHash!);
                              } else if (response.errorCode != null) {
                                regularInvoiceStatusMessage =
                                    "Error creating regular invoice: ${response.errorMessage}";
                              }
                            });
                          } catch (e) {
                            setState(() {
                              regularInvoiceStatusMessage =
                                  "Exception creating regular invoice: $e";
                              print("Error making regular invoice: $e");
                            });
                          }
                        }
                      }
                    : null,
                child:
                    Text(isHoldInvoice ? 'Make Hold Invoice' : 'Make Invoice'),
              ),
            ),
          ],
        ),
      ),
    );

    // Display for the created invoice (normal or hold)
    if (makeInvoice != null && makeInvoice!.errorCode == null) {
      widgets.add(SelectableText("Invoice: ${makeInvoice!.invoice}"));
      if (_currentInvoiceWasHold) {
        widgets
            .add(SelectableText("Payment Hash: ${makeInvoice!.paymentHash}"));
      }
      if (makeInvoice!.invoice.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () async {
                final Uri launchUri =
                    Uri.parse('lightning:${makeInvoice!.invoice}');
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                } else {
                  // Optionally, show a message if no app can handle the URI
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Could not launch Lightning invoice. No app found to handle it.')),
                  );
                  print('Could not launch $launchUri');
                }
              },
              child: QrImageView(
                data: makeInvoice!.invoice.toUpperCase(),
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        );
      }
    } else if (makeInvoice != null && makeInvoice!.errorCode != null) {
      // If there was an error creating the invoice (and it's not a hold-specific status message already handled)
      if (!_currentInvoiceWasHold) {
        // Only show generic error if not a hold invoice with its own status
        widgets.add(Text("Error creating invoice: ${makeInvoice!.errorMessage}",
            style: const TextStyle(color: Colors.red)));
      }
    }

    // Display for regular invoice payment status
    if (!_currentInvoiceWasHold &&
        makeInvoice != null &&
        makeInvoice!.errorCode == null) {
      if (regularInvoiceStatusMessage != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(regularInvoiceStatusMessage!,
              style: isRegularInvoicePaid
                  ? const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)
                  : null),
        ));
      }
    }

    // Hold invoice specific status messages and buttons (Settle/Cancel)
    // are now part of the "Make Invoice" section's output, below the QR code.
    if (_currentInvoiceWasHold) {
      if (holdInvoiceStatusMessage != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(holdInvoiceStatusMessage!),
        ));
      }

      if (isHoldInvoiceAccepted) {
        widgets.add(const Text("Hold invoice accepted!",
            style:
                TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
        widgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: (connection != null &&
                      holdInvoicePreimage != null &&
                      !isSettlingOrCancelling())
                  ? () async {
                      setState(() {
                        holdInvoiceStatusMessage = "Settling hold invoice...";
                        settleHoldInvoiceResponse = null;
                        cancelHoldInvoiceResponse = null;
                      });
                      try {
                        final response = await ndk.nwc.settleHoldInvoice(
                            connection!,
                            preimage: holdInvoicePreimage!);
                        setState(() {
                          settleHoldInvoiceResponse = response;
                          if (response.errorCode == null) {
                            holdInvoiceStatusMessage =
                                "Hold invoice settled successfully. Preimage: $holdInvoicePreimage";
                          } else {
                            holdInvoiceStatusMessage =
                                "Error settling invoice: ${response.errorMessage}";
                          }
                        });
                      } catch (e) {
                        setState(() {
                          holdInvoiceStatusMessage =
                              "Exception settling invoice: $e";
                        });
                      }
                    }
                  : null,
              child: const Text("Settle Invoice"),
            ),
            const SizedBox(width: 20),
            FilledButton(
              onPressed: (connection != null &&
                      holdInvoicePaymentHash != null &&
                      !isSettlingOrCancelling())
                  ? () async {
                      setState(() {
                        holdInvoiceStatusMessage = "Cancelling hold invoice...";
                        settleHoldInvoiceResponse = null;
                        cancelHoldInvoiceResponse = null;
                      });
                      try {
                        final response = await ndk.nwc.cancelHoldInvoice(
                            connection!,
                            paymentHash: holdInvoicePaymentHash!);
                        setState(() {
                          cancelHoldInvoiceResponse = response;
                          if (response.errorCode == null) {
                            holdInvoiceStatusMessage =
                                "Hold invoice cancelled successfully.";
                          } else {
                            holdInvoiceStatusMessage =
                                "Error cancelling invoice: ${response.errorMessage}";
                          }
                        });
                      } catch (e) {
                        setState(() {
                          holdInvoiceStatusMessage =
                              "Exception cancelling invoice: $e";
                        });
                      }
                    }
                  : null,
              child: const Text("Cancel Invoice"),
            ),
          ],
        ));
      }

      if (settleHoldInvoiceResponse != null) {
        widgets.add(Text(settleHoldInvoiceResponse!.errorCode == null
            ? "Settle successful! Preimage: $holdInvoicePreimage"
            : "Settle failed: ${settleHoldInvoiceResponse!.errorMessage}"));
      }
      if (cancelHoldInvoiceResponse != null) {
        widgets.add(Text(cancelHoldInvoiceResponse!.errorCode == null
            ? "Cancel successful!"
            : "Cancel failed: ${cancelHoldInvoiceResponse!.errorMessage}"));
      }
    }

    widgets.add(
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20));

    // --- Pay Invoice Section ---
    widgets.add(const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0), // Reduced top padding
      child: Text("Pay Invoice",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));

    bool canPayInvoice = connection != null &&
        connection!.info!.methods.contains(NwcMethod.PAY_INVOICE.name) &&
        invoice.text != '';

    widgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            width: 300, // Centered invoice input field
            child: TextField(
              controller: invoice,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Invoice to pay (bolt11)",
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: canPayInvoice
                ? () async {
                    final p = await ndk.nwc
                        .payInvoice(connection!, invoice: invoice.text);
                    setState(() {
                      payInvoice = p;
                    });
                  }
                : null,
            child: const Text('Pay Invoice'),
          ),
        ],
      ),
    ));
    widgets.add(payInvoice != null
        ? SelectableText("Payment Preimage: ${payInvoice!.preimage}")
        : Container());

    widgets.add(const Divider(height: 40, thickness: 2));
    widgets.add(
      FilledButton(
        onPressed: connection != null
            ? () async {
                await ndk.nwc.disconnect(connection!);
                _resetInvoiceStates(); // Use the new reset function
                setState(() {
                  connection = null;
                  balance = null;
                  payInvoice = null;
                  nwcAppKey = null; // Reset the app's NWC key
                  uri.clear(); // Clear the URI input field
                  // Other NWC specific states are reset by _resetInvoiceStates
                });
              }
            : null,
        child: const Text('Disconnect'),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start, children: widgets),
      ),
    );
  }

  bool isSettlingOrCancelling() {
    return (holdInvoiceStatusMessage != null &&
            (holdInvoiceStatusMessage!.contains("Settling") ||
                holdInvoiceStatusMessage!.contains("Cancelling"))) ||
        settleHoldInvoiceResponse != null ||
        cancelHoldInvoiceResponse != null;
  }

  void _listenForHoldInvoiceAcceptance(String expectedPaymentHash) {
    holdInvoiceStateSubscription?.cancel();
    if (connection == null) {
      setState(() {
        holdInvoiceStatusMessage =
            "Connection is null, cannot listen for acceptance.";
      });
      return;
    }
    final stream = connection!.holdInvoiceStateStream;
    if (stream == null) {
      if (mounted) {
        setState(() {
          holdInvoiceStatusMessage = "Hold invoice state stream is null.";
        });
      }
      return;
    }

    // Use makeInvoice.expiresAt as it now holds the response for both normal and hold invoices
    final duration = makeInvoice?.expiresAt != null
        ? (makeInvoice!.expiresAt! -
            DateTime.now().millisecondsSinceEpoch ~/ 1000)
        : 300; // Default timeout if expiresAt is not available

    holdInvoiceStateSubscription = stream
        .timeout(
            Duration(seconds: duration.toInt() > 0 ? duration.toInt() : 300))
        .listen((notification) {
      if (notification.notificationType ==
              NwcNotification.kHoldInvoiceAccepted &&
          notification.paymentHash == expectedPaymentHash) {
        setState(() {
          isHoldInvoiceAccepted = true;
          holdInvoiceStatusMessage = "Hold invoice accepted by wallet!";
        });
        holdInvoiceStateSubscription?.cancel();
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          if (error is TimeoutException) {
            holdInvoiceStatusMessage =
                "Timed out waiting for hold invoice acceptance.";
          } else {
            holdInvoiceStatusMessage =
                "Error listening for hold invoice acceptance: $error";
          }
        });
      }
    }, onDone: () {
      if (mounted &&
          !isHoldInvoiceAccepted &&
          settleHoldInvoiceResponse == null &&
          cancelHoldInvoiceResponse == null) {
        // setState(() {
        //   holdInvoiceStatusMessage = "Notification stream closed without acceptance.";
        // });
      }
    });
  }

  void _listenForRegularInvoicePayment(String expectedPaymentHash) {
    regularInvoicePaymentSubscription?.cancel();
    if (connection == null) {
      if (mounted) {
        setState(() {
          regularInvoiceStatusMessage =
              "Connection is null, cannot listen for payment.";
        });
      }
      return;
    }
    // Use the general notificationsStream and filter for payment notifications
    final stream = connection!.paymentsReceivedStream;
    if (stream == null) {
      if (mounted) {
        setState(() {
          regularInvoiceStatusMessage = "Payment notification stream is null.";
        });
      }
      return;
    }

    final duration = makeInvoice?.expiresAt != null
        ? (makeInvoice!.expiresAt! -
            DateTime.now().millisecondsSinceEpoch ~/ 1000)
        : 300; // Default timeout

    regularInvoicePaymentSubscription = stream
        .timeout(
            Duration(seconds: duration.toInt() > 0 ? duration.toInt() : 300))
        .listen((notification) {
      if (notification.notificationType == NwcNotification.kPaymentReceived &&
          notification.paymentHash == expectedPaymentHash) {
        if (mounted) {
          setState(() {
            isRegularInvoicePaid = true;
            regularInvoiceStatusMessage =
                "Invoice PAID! Preimage: ${notification.preimage}";
          });
        }
        regularInvoicePaymentSubscription?.cancel();
      }
      // We might also want to listen for kPaymentFailed if the NWC provider sends such for incoming payments that fail.
      // Or, more commonly, the invoice just expires.
    }, onError: (error) {
      if (mounted) {
        setState(() {
          if (error is TimeoutException) {
            regularInvoiceStatusMessage =
                "Timed out waiting for invoice payment.";
          } else {
            regularInvoiceStatusMessage =
                "Error listening for invoice payment: $error";
          }
        });
      }
    }, onDone: () {
      if (mounted && !isRegularInvoicePaid) {
        // If stream closes and invoice not paid, could update status.
        // For now, timeout handles expiration.
      }
    });
  }
}
