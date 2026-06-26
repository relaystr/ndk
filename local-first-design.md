# NDK Local-First Architecture — Design Doc

Status: draft for discussion
Scope: make `ndk` usable for apps that work fully offline and converge with relays on
reconnect, without forcing that model on apps that don't want it.

This doc is grounded in the current code, not a greenfield proposal. Where the right
approach is genuinely unclear, it lists options with trade-offs and a recommendation
rather than asserting one answer.

---

## 0. Principles (corrected)

The naive framing "local storage is the source of truth" is wrong for Nostr and should
not be the stated principle. Precise version:

- **Own unpublished events**: local is authoritative until delivered. Never lose them.
- **Foreign events**: relays are canonical. Local cache is a *materialized view* that can
  go stale (replaceable updates, NIP-09 deletions, NIP-40 expiration). Resolve on write.
- **Money (Cashu proofs, NWC)**: the *mint* is authoritative, not relays and not the
  local cache. Must not flow through the generic event retry path. See §8.

So the principle is: **local cache serves every read with zero latency; the sync engine
keeps it convergent with the canonical source for each data class.** Different data
classes have different canonical sources.

---

## 1. What already exists (build on, don't reinvent)

| Capability | Where | Use it for |
|---|---|---|
| Cache-first read pipeline | `requests.dart:293` `resolveUnresolvedFilters` then network | Already local-first; extend, don't flip |
| Flexible local query | `CacheManager.loadEvents(...)` | Read path; needs streaming + replaceable resolution |
| Time-range sync ledger | `FilterFetchedRangeRecord` / `FetchedRanges` / `TimeRange` | "what have I synced" per filter per relay |
| Negentropy set-reconciliation | `Nip77.reconcile(relayUrl, filter)` | The real reconnect-sync primitive |
| Per-relay publish responses | `RelayBroadcastResponse` (`broadcast_state.dart:9`) | Outbox per-relay tracking (currently RAM-only) |
| Connectivity signal | `Connectivy.relayConnectivityChanges` | Online/offline gating |
| Dedup | `StreamResponseCleaner` + `returnedIds` + `shared/bloom_filter` | Don't reimplement dedup |
| Cache conformance suite | `packages/ndk_cache_manager_test_suite` | Lock invariants across backends |

Two of these — `FetchedRanges` and `Nip77` — are the assets the earlier design summary
completely ignored. They should be the spine of the sync engine, not a new `EventSyncStatus`
enum invented from scratch.

Confirmed gaps in current code:
- `MemCacheManager.saveEvent` is `events[event.id] = event` — **no replaceable dedup**
  (`mem_cache_manager.dart:399`). Same naive write across backends presumably.
- `BroadcastState` is RAM-only — outbox does not survive restart.
- No incoming-deletion / expiration enforcement on the read path.

---

## 2. Architecture overview

```
        app
         │  watch(filter) / publish(event)
         ▼
┌─────────────────────────────────────────────┐
│ Local-First Facade (new, opt-in)            │
│  - unified reactive read  (§3)              │
│  - write + outbox         (§5)              │
└───────┬───────────────────────┬─────────────┘
        │ reads/writes          │ sync triggers
        ▼                       ▼
┌───────────────┐      ┌──────────────────────┐
│ CacheManager  │◄────►│ Sync Engine (new)    │
│ + resolution  │      │  - gap fill (ranges) │
│   (§4)        │      │  - negentropy (NIP77)│
│               │      │  - sub resume (§6)   │
└───────────────┘      │  - outbox flush (§5) │
                       └──────────┬───────────┘
                                  ▼
                          existing Requests /
                          Broadcast / engines
```

Everything new sits **above** the existing usecases as an opt-in layer. `MemCacheManager`
+ pure-relay usage keeps working unchanged. This is a hard requirement — the lib must not
force offline-first on apps that don't want the storage cost.

---

## 3. Unified reactive read API

Goal: app calls one thing and gets a stream that updates on local writes AND relay sync,
never branching on online/offline.

```dart
Stream<List<Nip01Event>> watch(Filter filter, {SyncPolicy policy});
```

Open question: how live results merge with cache.

### Decision 3.1 — Read API shape

**Option A — Stream of full result lists (`watchQuery`).**
Emits the whole current result set on every change.
- + Dead simple for UI (bind list to stream).
- + Natural for sorted/limited views.
- − Re-emitting large lists is costly; diffing left to app.

**Option B — Stream of deltas (added/updated/removed events).**
- + Efficient for large sets; app maintains its own view.
- + Maps cleanly to replaceable-update and deletion events.
- − More work for simple apps; ordering/limit harder.

**Option C — Both: delta stream as core, list-materializing helper on top.**
- + Flexibility; power users get deltas, simple users get lists.
- − Two code paths to maintain.

**Recommendation: C.** Deltas are required anyway to express deletions/replacements
correctly (a replaceable update is a remove+add). Ship the list helper for the 80% case.

### Decision 3.2 — Offline "empty vs unsynced"

A cache read returning `[]` is ambiguous: nothing exists, or never synced? `FetchedRanges`
already answers this. Surface it in the read result so apps render the right empty state.

```dart
class QueryView {
  final List<Nip01Event> events;
  final SyncState sync; // neverSynced | syncing | syncedAt(ts) | offlineStale
}
```
No real alternative here — this is just exposing data already tracked. Recommend doing it.

---

## 4. Cache resolution: replaceable / deletion / expiration

This is the correctness floor. Without it, offline reads show stale profiles, resurrected
deleted notes, expired events. Currently **none** of this is enforced in cache.

### 4.1 Replaceable + addressable (kinds 0, 3, 10000–19999, 30000–39999)

Rule (NIP-01/NIP-09): for replaceable, keep only newest `created_at` per `(kind, pubkey)`;
for addressable, per `(kind, pubkey, dTag)`. Tie on `created_at` → keep lower event id.

### Decision 4.1 — Where resolution happens

**Option A — Resolve on write (cache enforces invariant).**
`saveEvent` of a replaceable deletes older same-coordinate rows.
- + Cache always coherent; reads are trivial and fast.
- + One implementation, all backends inherit via the test suite.
- − Write cost; must be transactional to avoid races.
- − Backend-specific (objectbox/drift/sembast each need the delete-old query).

**Option B — Resolve on read (cache keeps all versions, query picks newest).**
- + Writes stay dumb; full history retained (useful for some apps).
- + Backend-agnostic if done in shared logic above cache.
- − Every read pays resolution cost; easy to get wrong per-usecase (today's bug).
- − Unbounded growth of superseded versions until eviction.

**Option C — Hybrid: resolve on write for the canonical row, optionally retain history
behind a flag.**
- + Fast reads + opt-in history.
- − Most complex; two storage shapes.

**Recommendation: A**, with the resolution rule implemented once as a shared helper that
each backend calls inside its write transaction, and locked by the conformance suite.
History retention (C) only if a concrete app needs it — don't pre-build.

### 4.2 Deletions (NIP-09, kind 5)

Outgoing deletions already purge cache (`broadcast.dart:225`). **Incoming** deletions from
relays during sync do not. Needed: on ingest of a kind-5 from the author, remove/tombstone
referenced `e`/`a` targets.

Open question: hard-delete vs tombstone.

**Option A — Hard delete target rows.**
- + Simple, smallest storage.
- − If the deletion arrives before the target, can't match; if target re-syncs later from
  another relay, it resurrects (no record that it was deleted).

**Option B — Tombstone (persist deletion record, suppress on read).**
- + Survives out-of-order arrival; prevents resurrection; auditable.
- + Matches how relays themselves behave.
- − Extra storage; read path must check tombstones.

**Recommendation: B.** Out-of-order arrival is the norm in multi-relay sync; hard-delete
resurrects events. Store kind-5 events themselves (they're just events) and filter targets
at read/resolution time. Honor only deletions whose pubkey matches the target's author.

### 4.3 Expiration (NIP-40)

`expiration` tag → treat as expired past that time. Cheap: filter on read + sweep on evict.
No real alternatives. Recommend doing it alongside eviction (§7).

---

## 5. Write path + persistent outbox

The genuine gap: `BroadcastState` is RAM-only. The `broadcast-queue-shim-for-ndk` package
proves the persisted-outbox approach and its `QueuedBroadcast` model is good. Question is
whether to vendor that pattern into core or keep it external.

### Decision 5.1 — Outbox location

**Option A — External shim package (status quo, app wires it).**
- + Zero core change; ships today; isolated.
- − No gossip integration (caller must compute relay targets by hand).
- − Separate store from `CacheManager` → eviction not outbox-aware (§7), event stored twice.
- − No permanent-reject handling (retries pow/blocked forever).

**Option B — First-class outbox in `ndk` core, sharing `CacheManager`.**
- + Reuses NDK gossip (NIP-65) to compute targets at enqueue.
- + One store → eviction can be made outbox-aware; no double storage.
- + Can parse OK reason → permanent vs transient (the shim's miss).
- − Real surface-area addition; migrations; interface changes ripple to all backends.

**Option C — Core defines the outbox *interface* + state machine; backends + the existing
shim provide storage.**
- + Keeps storage pluggable (matches existing CacheManager pattern).
- + Apps that want the shim keep it; core users get integrated path.
- − Most up-front design; risk of over-abstraction.

**Recommendation: B for the long term, with the shim as the reference implementation to
port from.** The two things that *must* be in core (not a shim) are gossip target
computation and cache/eviction coherence — both are impossible from outside the lib.
Borrow verbatim from the shim: monotonic acks, remaining-relays-only retargeting,
persist-before-return.

### 5.2 Outbox model (port of `QueuedBroadcast`, corrected)

One persisted record per event; per-relay ack set inside it (the shim already does this —
don't go to one-row-per-relay unless a backend needs it for indexing).

Add what the shim lacks:

- **Permanent vs transient classification.** Parse `RelayBroadcastResponse.msg`:
  - `blocked:`, `invalid:`, `error:`, `pow:` (if difficulty unattainable), `auth-required:`
    handled separately → permanent / needs-action, stop blind retry.
  - `rate-limited:`, transient network/timeout → backoff retry.
- **`maxAttempts` / dead-letter.** Surface "undelivered" to the app instead of retrying
  forever (messaging-app red exclamation). Doc §6 of the old summary had this right.

### Decision 5.2 — Target relay computation

Snapshot at enqueue (the old summary's §4 was correct — gossip data drifts). But:

**Option A — Compute targets at enqueue, freeze them.**
- + Deterministic; matches what user intended at publish time.
- − If NIP-65 was stale/empty when offline, you froze a bad/empty set.

**Option B — Compute at enqueue, but allow re-resolution if the set was empty/degraded.**
- + Recovers from "composed before we ever learned the user's relays."
- − More complex; "degraded" needs definition.

**Recommendation: B.** Freeze a *good* set; if at enqueue time gossip data was missing
(common on a fresh offline start), mark the entry "targets-unresolved" and resolve on first
online flush before sending. Otherwise freeze.

### 5.3 Signing offline

Local (NIP-07-ish) signers sign offline; remote signers (NIP-46 bunker, `bunkers/`) need
network.

**Option A — Require signed events into the outbox.**
- + Outbox stays dumb; event id stable.
- − Can't compose offline with a bunker signer at all.

**Option B — Allow unsigned events; sign at flush.**
- + True offline compose with remote signers.

---

## 9. First end-to-end test plan

Before building the full local-first sync loop, lock down a small number of end-to-end
scenarios that prove the model is safe under offline use, restart, and reconnect.

These tests should use the existing integration harness:

- real `Ndk`
- real `MockRelay`
- real `SembastCacheManager` in a temp dir
- destroy and recreate `Ndk` against the same db path to simulate restart

Do **not** start with a giant matrix. The first 3 scenarios below are the correctness
core. If these work, the storage model and retry loop are probably sound.

### 9.1 Scenario A — offline create -> restart -> reconnect -> delivered

This is the primary local-first guarantee.

**Setup**
- Create a persistent cache (`SembastCacheManager`) in a temp dir.
- Start with no reachable relays, or use explicit offline relay URLs.
- Log in with a local signer.
- Pre-seed enough relay-list data in cache to resolve expected targets.

**Flow**
1. Compose and publish a normal text note while offline.
2. Verify the note is readable immediately from local cache/read APIs.
3. Verify one parent `EventDeliveryRecord` exists.
4. Verify separate `RelayDeliveryTargetRecord`s exist for the expected relays.
5. Destroy `Ndk`.
6. Recreate `Ndk` using the same cache path.
7. Start the relay servers and reconnect.
8. Trigger outbox flush / reconnect sync.

**Assertions**
- The event survives restart unchanged.
- Delivery state survives restart unchanged.
- The event is sent after reconnect.
- Each relay target moves independently to `acked` or failure state.
- Parent delivery state becomes `delivered` only when target completion rules are met.
- No duplicate target records are created during restart/reconnect.

### 9.2 Scenario B — partial success -> restart -> retry remaining only

This proves why relay targets must be stored separately.

**Setup**
- Persistent cache.
- Two or three target relays.
- At least one relay online, at least one offline/unreachable.

**Flow**
1. Publish an event.
2. Let relay A succeed.
3. Let relay B fail or timeout.
4. Persist state and destroy `Ndk`.
5. Recreate `Ndk` with the same cache.
6. Bring relay B online.
7. Run retry/flush again.

**Assertions**
- Relay A is not retried once already acked.
- Relay B is retried from stored target state.
- Attempt counters / retry timestamps evolve only for relay B.
- Final state becomes `delivered` when the remaining target succeeds.
- No previously acked target regresses.

### 9.3 Scenario C — offline reply/reaction -> local thread visibility -> inbox/outbox delivery later

This is the most important gossip case after plain posting.

**Setup**
- Cache a remote root event locally.
- Cache enough relay-list data for:
  - the local author's write relays
  - the target author's read/inbox relays

**Flow**
1. Go offline.
2. Create a reply or reaction to the cached remote event.
3. Read the thread/reaction view locally before any network access.
4. Restart the app while still offline.
5. Reconnect and flush delivery.

**Assertions**
- The reply/reaction is visible locally immediately.
- The event remains visible after restart before reconnect.
- Delivery targets include both:
  - local author write relays
  - recipient/read-side relays required by gossip routing
- Partial delivery does not remove or hide the local thread item.
- Final delivery state converges once relays respond.

### 9.4 Scenario D — concurrent per-relay updates do not overwrite

This is the first race-safety scenario to prove storage shape, even if true parallelism is
simulated by fast async interleaving.

**Setup**
- Persistent cache.
- One event with at least two target relays.

**Flow**
1. Create parent delivery record.
2. Create two relay target records.
3. Apply near-simultaneous updates:
   - relay A -> `acked`
   - relay B -> `transientFailure`
4. Reload from cache.

**Assertions**
- Both target updates survive.
- No write drops the other relay's state.
- Parent record remains intact.

### 9.5 Scenario E — delete pending local event before flush

This is the most important cleanup case.

**Setup**
- Offline-created unpublished event with delivery state and relay targets.

**Flow**
1. Create event offline.
2. Confirm local cache + delivery records exist.
3. Delete/cancel the local event before any successful send.
4. Reconnect.

**Assertions**
- Event is removed or tombstoned according to final product rule.
- Parent delivery record is removed.
- All relay target records are removed.
- Reconnect does not send the deleted event.

### 9.6 Scenario F — replaceable event superseded offline

This is essential for kinds `0`, `3`, `10000-19999`, `30000-39999`.

**Setup**
- Persistent cache.
- Offline mode.

**Flow**
1. Create replaceable event version 1 offline.
2. Before reconnect, create version 2 for the same coordinate.
3. Restart.
4. Reconnect and flush.

**Assertions**
- Local reads show only the current winner.
- Older pending delivery state is removed, cancelled, or marked superseded.
- Only the current event continues through delivery.
- No obsolete version is re-sent after restart.

### 9.7 Recommended implementation order

Build the first end-to-end tests in this order:

1. Scenario A — offline create -> restart -> reconnect -> delivered
2. Scenario B — partial success -> restart -> retry remaining only
3. Scenario C — offline reply/reaction -> local visibility -> delayed delivery
4. Scenario E — delete pending local event before flush
5. Scenario F — replaceable supersession offline
6. Scenario D — concurrent per-relay update preservation

Reason:
- A/B/C prove the product promise.
- E/F prove local correctness under mutation.
- D proves the storage shape under async update pressure.

### 9.8 First implementation note

The first concrete test file should probably be something like:

`packages/ndk/test/usecases/local_first/local_first_outbox_test.dart`

and should start with Scenario A using:

- `SembastCacheManager.create(databasePath: tempDir.path)`
- `MockRelay`
- two `Ndk` lifecycles against the same db

That gives the highest signal with the lowest amount of new harness code.
- − Event id only stable if `pubkey`+`created_at` set pre-sign; outbox key handling trickier;
  bunker-unreachable means stuck-unsigned state to surface.

**Recommendation: B**, but require `pubkey` + `created_at` at enqueue so the id is stable
and dedup/ordering work. Expose a distinct "awaiting-signer" state.

---

## 6. Sync engine (the reconnect story)

On reconnect, three jobs, in order:

1. **Refresh gossip first** (NIP-65, relay lists). Else you flush to dead relays. Hard
   ordering dependency.
2. **Flush outbox** (§5) — writes before reads, so the user's own actions land fast.
3. **Backfill + resume reads** — close the gap since last sync, then resume live tail.

### Decision 6.1 — Backfill mechanism

**Option A — Re-REQ using `FetchedRanges` gap (time-window).**
Request `since = last_synced_until, until = now` per filter per relay.
- + Already have the ledger; simple; works on every relay.
- − Misses events back-dated into an already-"covered" window (offline edits with old
  `created_at`, slow-propagating events). Time-coverage ≠ set-completeness.

**Option B — Negentropy reconciliation (NIP-77, `Nip77.reconcile`).**
- + True set-level convergence; catches back-dated/missed events; bandwidth-efficient.
- + Already implemented in the repo.
- − Only relays that support NIP-77; must fall back to A elsewhere.

**Option C — Negentropy where supported, time-window fallback, `FetchedRanges` as the
shared ledger for both.**
- + Best correctness where possible, universal floor everywhere.
- − Two code paths; need per-relay capability detection.

**Recommendation: C.** Negentropy is the differentiator and it's already in the repo; but
relay support is uneven, so time-window backfill remains the floor. `FetchedRanges` records
progress for both.

### Decision 6.2 — Subscription resumption

Live subs are ephemeral today (`cacheRead: false` default, dropped on disconnect). For
offline-first, persist a per-subscription, per-relay watermark (`last seen created_at`) and
resume from it on reconnect rather than refetching.

**Option A — Persist watermarks, resume from them.**
- + Cheap reconnect; no refetch storm.
- − Watermark + clock-skew edge cases; relay may have dropped events below watermark.

**Option B — On reconnect, negentropy the sub's filter, then go live from now.**
- + Correct (set-level), no watermark bookkeeping.
- − Needs NIP-77; heavier per reconnect.

**Recommendation: A as the default, B as an upgrade where NIP-77 is available** — same
capability split as 6.1. Keep a small overlap window on resume (re-request a few seconds
before the watermark) to tolerate skew; dedup handles the rest.

---

## 7. Storage lifecycle: eviction, coherence, encryption, migration

### 7.1 Eviction (must be structurally safe)

Earlier design's instinct was right: eviction must be *incapable* of dropping non-durable
data, not merely discouraged. Gate eviction on:
- no pending/awaiting outbox entry for the event (§5),
- covered by `FetchedRanges` (re-fetchable),
- not protected (own events, bookmarked, list members),
- and apply expiration/tombstone sweeps here too.

This requires outbox and cache to share a store or be cross-aware — the strongest argument
for outbox-in-core (Decision 5.1 B). With the external shim, eviction cannot see the
outbox and the guarantee breaks.

### Decision 7.1 — Eviction policy

**Option A — TTL / age-based.** Simple, predictable; may evict still-useful data.
**Option B — LRU by access.** Keeps hot data; needs access tracking (write amplification).
**Option C — Size-capped per kind + keep-own-forever + protected set.** Most controllable;
most config.

**Recommendation: C** as the model, exposed via the old summary's `evict(EvictionPolicy)`
with sensible defaults; let apps tune caps. Whatever the policy, the durability gate above
is non-negotiable and sits underneath it.

### 7.2 Encryption at rest

Offline-first means sensitive data (DMs, gift wraps, **Cashu proofs = bearer money**,
possibly keys) sits on device longer. Plaintext sembast/objectbox is a theft risk.

**Option A — Out of scope; document that the app must encrypt the DB file.**
- + No core work. − Footgun; most apps will get it wrong, esp. with wallet data.
**Option B — Optional encrypted cache backend (e.g. SQLCipher via drift / encrypted sembast codec).**
- + Real protection; opt-in. − Backend-specific; key management burden.
**Option C — Encrypt only sensitive value classes (proofs, DM plaintext) inside an otherwise
plain store.**
- + Targeted; smaller surface. − App must know what's sensitive; partial.

**Recommendation: B for wallet-bearing apps, A acceptable for pure social apps**, decided
per deployment. Given the active `feat/cashu-improvements` work, at minimum the wallet
proof store should not be plaintext — call this out loudly.

### 7.3 Schema migration

Local-first data is long-lived → migrations matter, and each backend (objectbox, drift,
sembast) migrates differently. Encode storage invariants in
`ndk_cache_manager_test_suite` so all backends stay equivalent across versions. No real
alternative; recommend treating the suite as the contract.

---

## 8. Wallet / money — do NOT reuse the event outbox

Biggest correctness landmine, and directly relevant to the current branch.

- A re-broadcast Nostr **event** is idempotent (relays dedup). A retried Cashu **spend** or
  NWC payment after an ambiguous network failure can double-spend or burn proofs. Same
  "retry forever with backoff" semantics that are *safe* for events are *dangerous* for money.
- Canonical source for proof state is the **mint**, not relays and not the cache.
  Reconnect reconciliation for the wallet talks to the mint (check proof state) before any
  retry — different trust model, different code path.

### Decision 8.1 — Wallet sync handling

**Option A — Separate, mint-aware reconciliation path; wallet ops never enter the event
outbox.**
- + Correct; isolates money risk. − More code; duplicate-ish queue infrastructure.
**Option B — Shared queue with a per-entry "idempotency / exactly-once" mode.**
- + Less duplication. − One bug in the shared path can lose money; high blast radius.

**Recommendation: A, firmly.** Keep money out of the generic retry machinery. Model proof
state (unspent → pending → spent) with mint reconciliation, not relay reconciliation.

---

## 9. Cross-cutting hazards (call out, mostly not "options")

- **`created_at` is compose-time, not send-time.** Offline-composed events keep their old
  timestamp; on flush they may (a) be rejected by relays enforcing time bounds, (b) *lose*
  a replaceable LWW race against a newer edit from another device. Offer an optional
  "rewrite `created_at` at flush" for non-replaceable events; document the replaceable race.
- **Multi-device convergence is LWW, no CRDT.** Two offline devices editing kind 3 (contacts)
  → one clobbers the other = silent follow loss. Consider an additive-merge heuristic for
  list kinds, or at least surface the conflict. Be honest that Nostr can't fully solve this.
- **Causal ordering on flush.** Replies/reactions/deletes referencing not-yet-delivered
  events create transient orphans. Either order the flush by dependency or accept transient
  inconsistency (relays tolerate it).
- **NIP-42 AUTH on flush.** Auth-required relays need live challenge-response at send time;
  an offline-composed event can't pre-auth. Flush must handle AUTH, may fail → retry.
  Interacts with bunker-offline (§5.3).
- **Clock skew** between device and relays affects watermarks (§6.2) and time-window
  backfill (§6.1). Use overlap windows + dedup; never trust local clock for exact bounds.

---

## 10. Sequencing recommendation

Highest leverage first, each independently shippable:

1. **Cache resolution (§4)** — replaceable-on-write, deletion tombstones, expiration.
   Correctness floor; everything else shows wrong data without it. Lock with the conformance
   suite.
2. **`FetchedRanges`-backed read view (§3.2)** — expose synced/unsynced; small, high UX value.
3. **Persistent outbox in core (§5)** — port the shim, add permanent-reject + dead-letter +
   gossip targets.
4. **Sync engine (§6)** — gossip-refresh → flush → negentropy/time-window backfill → sub resume.
5. **Eviction durability gate (§7.1)** — once outbox shares the store.
6. **Unified reactive read (§3.1)** — the DX payoff, built on 1–2.
7. **Wallet path kept separate (§8)** — ongoing constraint, not a step; enforce from day one.

Open decisions needing your call before building: 3.1 (read shape), 4.1 (resolve on
write/read), 5.1 (outbox in core vs shim vs interface), 6.1/6.2 (negentropy vs window),
7.2 (encryption scope). The recommendations above are defaults, not conclusions.

================
Description
a) gossip-driven targets,
(b) cache-coherent eviction,
(c) permanent-reject handling.

- What "no result" means offline. Empty cache read = "nothing exists" or "not synced yet"? App needs to distinguish. FetchedRanges is your signal — surface it: "have I ever synced this filter?" vs "synced, genuinely empty." Critical for offline UX (don't show empty-state when really just unsynced).

If permanently rejected by ALL relays (pow/blocked), what does app show? Need a "failed/undelivered" surface (doc §6 hinted, shim ignored).

Local-only events. Drafts, private bookmarks — may never publish. Cache must hold events with zero relay targets without outbox treating them as pending-forever. Distinct state.

If key is in a remote bunker, offline compose can't sign → queue must persist unsigned and sign at flush. Shim forwards unsigned + lets NDK sign at attempt — but bunker-unreachable = stuck. Event id is unstable until signed only if pubkey/created_at missing; otherwise stable. Decide: sign-now-or-queue-unsigned policy.


Negentropy + fetchedRanges = ???

- Subscription resumption. Live subs (subscription()) drop on disconnect. On reconnect, resume from last-seen created_at per relay, not from scratch. Need per-sub watermark persisted. Currently subs are ephemeral (cacheRead=false default).

Per-relay auth (NIP-42 — repo has nip42/). Outbox flush to auth-required relays needs live signer (challenge-response). Offline-composed event to an auth relay can't pre-auth. Flush must handle AUTH challenge at send time, may fail → retry. Interacts with bunker-offline problem.

Cache size unbounded otherwise. Need policy: LRU, per-kind caps, keep-own-forever. evict(policy) from doc is right idea; gate on outbox + fetched-ranges + protection.

Encrypted-at-rest. Local-first stores DMs/keys/cashu proofs on device. Cashu proofs = bearer money (repo has wallets). Plaintext sembast = theft risk. Offline-first amplifies this — more sensitive data sits local longer.