## Engines

NDK ships with two network Engines. An Engine is part of the code that resolves nostr requests over the network and handles the WebSocket connections.\
Its used to handle the inbox/outbox (gossip) model efficiently.

**Lists Engine:**\
Precalculates the best possible relays based on nip65 data. During calculation relay connectivity is taken into account. This works by connecting and checking the health status of a relay before its added to the ranking pool.\
This method gets close to the optimal connections given a certain pubkey coverage.

**Just in Time (JIT) Engine:**\
JIT Engine does the ranking on the fly only for the missing coverage/pubkey. Healthy relays are assumed during ranking and replaced later on if a relay fails to connect.\
To Avoid rarely used relays and spawning a bunch of unessecary connections, already connected relays get a boost, and a usefulness score is considered for the ranking.\
For more information [look here](./jit_engine/README.md)

### Choosing between them

`NdkEngine` selects which of them runs:

| value | a request that names a `relaySet` | every other request | broadcasts |
| --- | --- | --- | --- |
| `COMBINED` *(default)* | Lists Engine | JIT Engine | JIT Engine |
| `RELAY_SETS` | Lists Engine | Lists Engine | Lists Engine |
| `JIT` | JIT Engine, the set is ignored | JIT Engine | JIT Engine |

`COMBINED` is the default because a relay set is an explicit statement of where a
request should go, which the JIT engine has no way to honour. A request without
one has nothing to pin relays down and is exactly what the JIT engine is for.
Broadcasts carry no relay set, so they always go to the JIT engine: it does the
nip65 outbox and pTag inbox gossip.

**One pool.** All three modes run on a single `RelayManager` and therefore a
single connection pool. The pool is keyed by relay url and identity
(`RelayConnectionKey`), never by engine, so a socket one engine opened is handed
to the other whenever it needs that relay too. Two sockets to one relay is only
ever an identity split: an authenticated socket may only ever assume the identity
it authenticated as, so it cannot travel on the anonymous one.

**Custom Engine**\
If you want to implement your own engine with custom behavior you need to touch the following things:

1. implement `NetworkEngine` interface
2. write your response stream to `networkController` in the `RequestState`
3. if your engine needs per-connection bookkeeping, add a named slot to
   `EngineRelayConnectivityData` and read it off `RelayConnectivity.specificEngineData`
4. add a case to the engine switch in `init.dart` and to `NdkEngine`

A new engine is a plain object passed to the switch: it gets the shared
`RelayManager` and `GlobalState` like the built-in ones, so it joins the existing
pool instead of opening its own.

The current state solution is not ideal because it requires coordination between the engine authors and not enforceable by code. If you have ideas how to improve this system, please reach out.

> The network engine is only concerned about network requests! Caching and avoiding concurrency is handled by separate usecases. Take a look at `requests.dart` usecase to learn more.