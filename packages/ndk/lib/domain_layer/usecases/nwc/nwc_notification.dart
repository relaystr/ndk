import 'consts/transaction_type.dart';

class NwcNotification {
  static const kPaymentReceived = "payment_received";
  static const kPaymentSent = "payment_sent";
  static const kHoldInvoiceAccepted = "hold_invoice_accepted";

  String notificationType;
  String type;
  String invoice;
  String? description;
  String? descriptionHash;
  String? preimage;
  String paymentHash;
  int amount;
  int? feesPaid;
  int createdAt;
  int? expiresAt;
  int? settledAt;
  int? settleDeadline;
  Map<String, dynamic>? metadata;

  get isIncoming => type == TransactionType.incoming.value;
  get isPaymentReceived => notificationType == kPaymentReceived;
  get isPaymentSent => notificationType == kPaymentSent;
  get isHoldInvoiceAccepted => notificationType == kHoldInvoiceAccepted;

  NwcNotification({
    required this.notificationType,
    required this.type,
    required this.invoice,
    this.description,
    this.descriptionHash,
    this.preimage,
    required this.paymentHash,
    required this.amount,
    this.feesPaid,
    required this.createdAt,
    this.expiresAt,
    this.settledAt,
    this.settleDeadline,
    this.metadata,
  });

  factory NwcNotification.fromMap(String notificationType, Map<String, dynamic> map) {
    return NwcNotification(
      notificationType: notificationType,
      type: map['type'] as String,
      invoice: map['invoice'] as String,
      description: map['description'] as String?,
      descriptionHash: map['description_hash'] as String?,
      preimage: map['preimage'] as String,
      paymentHash: map['payment_hash'] as String,
      amount: map['amount'] as int,
      feesPaid: map['fees_paid'] as int,
      createdAt: map['created_at'] as int,
      expiresAt: map['expires_at'] as int?,
      settledAt: map['settled_at'] as int?,
      settleDeadline: map['settle_deadline'] as int?,
      metadata: map.containsKey('metadata') && map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  @override
  toString() {
    return 'NwcNotification{type: $type, invoice: $invoice, description: $description, descriptionHash: $descriptionHash, preimage: $preimage, paymentHash: $paymentHash, amount: $amount, feesPaid: $feesPaid, createdAt: $createdAt, expiresAt: $expiresAt, settledAt: $settledAt, metadata: $metadata}';
  }
}
