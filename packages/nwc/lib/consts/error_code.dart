enum ErrorCode {
  rateLimited(
    'RATE_LIMITED',
    'The client is sending commands too fast. It should retry in a few seconds.',
  ),
  notImplemented(
    'NOT_IMPLEMENTED',
    'The command is not known or is intentionally not implemented.',
  ),
  insufficientBalance(
    'INSUFFICIENT_BALANCE',
    'The wallet does not have enough funds to cover a fee reserve or the payment amount.',
  ),
  paymentFailed(
    'PAYMENT_FAILED',
    'The payment failed. This may be due to a timeout, exhausting all routes, insufficient capacity or similar.',
  ),
  notFound(
    'NOT_FOUND',
    'The invoice could not be found by the given parameters.',
  ),
  quotaExceeded(
    'QUOTA_EXCEEDED',
    'The wallet has exceeded its spending quota.',
  ),
  restricted(
    'RESTRICTED',
    'This public key is not allowed to do this operation.',
  ),
  unauthorized(
    'UNAUTHORIZED',
    'This public key has no wallet connected.',
  ),
  internal(
    'INTERNAL',
    'An internal error.',
  ),
  other(
    'OTHER',
    'Other error.',
  );

  final String value;
  final String message;

  const ErrorCode(this.value, this.message);

  factory ErrorCode.fromValue(String value) {
    return ErrorCode.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid error code value: $value'),
    );
  }
}
