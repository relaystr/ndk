import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk/ndk.dart';

import 'main.dart';

class ZapsPage extends StatefulWidget {
  const ZapsPage({super.key});

  @override
  State<ZapsPage> createState() => _ZapsPageState();
}

class _ZapsPageState extends State<ZapsPage> {
  TextEditingController uri = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController invoice = TextEditingController();
  NwcConnection? connection;
  GetBalanceResponse? balance;
  MakeInvoiceResponse? makeInvoice;
  PayInvoiceResponse? payInvoice;

  @override
  void initState() {
    super.initState();
    uri.addListener(() {
      setState(() {
        if (uri.text == '') {
          connection = null;
        }
      });
    });
    amount.addListener(() {
      setState(() {});
    });
    invoice.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
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
                connection =
                    await ndk.nwc.connect(uri.text, doGetInfoMethod: true);
                setState(() {
                  balance = null;
                });
              }
            : null,
        child: const Text('Connect and get info'),
      ),
    );
    widgets.add(connection != null && connection!.info != null
        ? Text("Methods ${connection!.info!.methods}")
        : Container());

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

    bool canMakeInvoice = connection != null &&
        connection!.info!.methods.contains(NwcMethod.MAKE_INVOICE.name) &&
        amount.text != '' &&
        (int.tryParse(amount.text) ?? 0) > 0;
    widgets.add(Row(
      children: [
        const SizedBox(width: 30),
        SizedBox(
          width: 200,
          child: TextField(
            controller: amount,
            decoration: const InputDecoration(
              hintText: "amount in sats",
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        FilledButton(
          onPressed: canMakeInvoice
              ? () async {
                  final invoice = await ndk.nwc.makeInvoice(connection!,
                      amountSats: int.tryParse(amount.text) ?? 0);
                  setState(() {
                    makeInvoice = invoice;
                  });
                }
              : null,
          child: const Text('Make invoice'),
        ),
      ],
    ));
    widgets.add(makeInvoice != null
        ? SelectableText("bolt11 invoice: ${makeInvoice!.invoice}")
        : Container());

    bool canPayInvoice = connection != null &&
        connection!.info!.methods.contains(NwcMethod.PAY_INVOICE.name) &&
        invoice.text != '';
    widgets.add(Row(
      children: [
        const SizedBox(width: 30),
        SizedBox(
          width: 200,
          child: TextField(
            controller: invoice,
            decoration: const InputDecoration(
              hintText: "invoice to pay",
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
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
          child: const Text('Pay invoice'),
        ),
      ],
    ));
    widgets.add(payInvoice != null
        ? SelectableText("preimage: ${payInvoice!.preimage}")
        : Container());

    widgets.add(
      FilledButton(
        onPressed: connection != null
            ? () async {
                await ndk.nwc.disconnect(connection!);
                setState(() {
                  connection = null;
                  balance = null;
                  makeInvoice = null;
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
}
