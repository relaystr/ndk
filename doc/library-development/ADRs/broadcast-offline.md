# Architecture Decision Record: Offline Broadcast

Title: Record: Offline Broadcast

## status

In progress

Updated on 15-06-2025

## contributors

- Main contributor(s): fmar

- Reviewer(s): fmar, leo, nogringo

- Final decision made by: fmar, leo, nogringo

## Context and Problem Statement

NDK does not remember events broadcasted when offline. 
As a user, I want to be able to draft something in a remote location (e.g. plane) without thinking about Nostr relay constraints.


## Main Proposal

#### Requirements:
- relay specific
- gossip
- Consider done %
- different modes, 
specific: relay broadcast must succeed
- eviction policy (keep in cache, delete old ones)
- Streamlined reject handling (retry, dismiss, paymentRequired, POW, blocked, etc.)

- Gossip: % of relays is ok




#### Refactor the Broadcast use case into several concerns.

- cache with state information
```
    PriorityBroadcast: 0
    PolicyBroadcast: all ok
    PolicyEviction: replace
    event1: broadcast: {
       relay 1 ok
       relay 2 failed, timeout
    }
```
- cache of deleted events
- Broadcast monitor (checks for broadcast state, delegates work, runs periodically)
- broadcast (stateless, broadcasts and returns results with comprehensive err handeling)

To model the constraints on each event, we are implementing a BroadcastPolicy, EvictionPolicy and priority broadcast.
Depending on the use case, an event must be accepted by one or multiple relays or just be accepted by a few. \
These policies are checked and executed by the broadcast monitor depending on the current conditions.\
\
Broadcast just executes a given policy/strategy given by the broadcast monitor and reports back.

#### BroadcastPolicys
 - consider done %
 - all ok
 - todo

#### EvictionPolicys
- todo


## Consequences

The main difficulty is the remote signer setup.
As a workaround, we store unsigned events in cache (so they are queriable) and check with the broadcast monitor whether we can sign them before broadcasting.


#### Impact Radius

Accounts:
edit, set up acc

Blossom/Files:
publish blossom servers

Cashu:
Not impacted rn

Connectivity:
Not impacted

Domain verification:
Not impacted

Follows:
edit, setup

Gift Wrap
publish 

Lists:
publish, edit

Metadata:
publish, edit

Nwc:
rpc method, offline zaps?

Relay sets
publish, edit

Requests:
Not impacted

User relay lists
publish, edit

Wallets
not impacted

Zaps
offline zap? (how to get invoice)



## Alternative proposals

Monolithc archetecture with a broadcast manager that encapsulates most of the retry logic attached to a state/cache class.

## Final Notes



