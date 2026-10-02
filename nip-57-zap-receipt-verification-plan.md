# NIP-57 Zap Receipt Verification Plan

Estimated effort: **3–5 engineering days** for production-quality verification.

Existing receipt parsing provides partial checks, but BOLT11 and LNURL-provider verification need strengthening.

> NIP-57 verification confirms that a receipt came from the recipient's declared LNURL provider. It cannot independently prove that payment happened. See [NIP-57 Appendix E](https://github.com/nostr-protocol/nips/blob/master/57.md#appendix-e-zap-receipt-event).

## 1. Add a structured verification result

- Represent `valid`, `invalid`, and `unverifiable` outcomes.
- Include machine-readable failure reasons for diagnostics.
- Keep event parsing separate from verification.

## 2. Strictly validate the receipt

- Require event kind `9735`.
- Validate the Nostr event ID and signature.
- Require exactly one `bolt11`, `description`, and recipient `p` tag.
- Parse the embedded kind `9734` zap request.
- Validate the zap request ID, signature, and required tags.

## 3. Add proper BOLT11 decoding

- Decode the exact millisatoshi amount.
- Decode the description hash.
- Decode the payment hash.
- Compare an optional preimage with the payment hash.
- Replace the current string-based amount extraction.

## 4. Verify invoice binding

- Require `SHA256(description)` to equal the BOLT11 description hash.
- Require the invoice amount to equal the zap request `amount`.
- Ensure receipt and request `p`, `e`, `a`, and `P` targets agree.
- Ensure the target matches the requested software release.

## 5. Verify the LNURL provider

- Resolve the publisher's `lud16`/`lud06` or a release `zap` tag.
- Fetch LNURL-pay metadata.
- Require `allowsNostr: true`.
- Require the receipt signer to equal the returned `nostrPubkey`.
- Compare the zap request `lnurl` when present.
- Cache LNURL metadata with a bounded expiry.

## 6. Prevent double-counting

- Deduplicate receipt event IDs.
- Deduplicate identical invoice or payment hashes.
- Aggregate only verified receipts.
- Optionally display unverifiable receipts separately.

## 7. Harden failure behavior

- Treat network failures as `unverifiable`, not invalid.
- Treat malformed receipts as invalid.
- Treat missing LNURL metadata as unverifiable.
- Never count unknown receipts as verified sats.

## 8. Add tests

- Official NIP-57 fixture.
- Forged provider signer.
- Invalid zap-request signature.
- Invoice/request amount mismatch.
- Description-hash mismatch.
- Wrong software-release target.
- Duplicate receipt or invoice.
- LNURL timeout and malformed response.

