## Engines

NDK ships with two network Engines. An Engine is part of the code that resolves nostr requests over the network and handles the WebSocket connections.\
Its used to handle the inbox/outbox (gossip) model efficiently.

**Lists Engine:**\
Precalculates the best possible relays based on nip65 data. During calculation relay connectivity is taken into account. This works by connecting and checking the health status of a relay before its added to the ranking pool.\
This method gets close to the optimal connections given a certain pubkey coverage.

**Just in Time (JIT) Engine:**\
JIT Engine does the ranking on the fly only for the missing coverage/pubkey. Healthy relays are assumed during ranking and replaced later on if a relay fails to connect.\
To Avoid rarely used relays and spawning a bunch of unessecary connections, already connected relays get a boost, and a usefulness score is considered for the ranking.\
For more information [look here](./doc/jit_engine/README.md)

**Custom Engine**\
If you want to implement your own engine with custom behavior you need to touch the following things:

1. implement `NetworkEngine` interface
2. write your response stream to `networkController` in the `RequestState`
3. if you need global state you can register your own data type in `global_state.dart`
4. initialize your engine in `init.dart`

The current state solution is not ideal because it requires coordination between the engine authors and not enforceable by code. If you have ideas how to improve this system, please reach out.

> The network engine is only concerned about network requests! Caching and avoiding concurrency is handled by separate usecases. Take a look at `requests.dart` usecase to learn more.
