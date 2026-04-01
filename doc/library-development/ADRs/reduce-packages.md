# Architecture Decision Record: Package Structure dart, flutter

Title: Package Structure dart, flutter

## status

In progress

Updated on 01-04-2026

## contributors

- Main contributor(s): 1leo

- Reviewer(s): frnandu, nogringo

- final decision made by: frnandu, 1leo, nogringo

## Context and Problem Statement

The 0.8.0 release was not streamlined. The goal of this ADR is to find out a suitable solution for the future.
We decided that we want to make it easier for developers to use ndk in their environment, reducing the decision down to dart required, flutter required.

## Main Proposal

The big changes are two main packages, ndk and ndk_flutter. The ndk package supports dart/flutter the ndk_flutter package only flutter.
This makes it easier for the developer to decide.
e.g.

`running on server? => ndk`
`running in a app?  => ndk + ndk_flutter`



## Consequences

There are several ways this could be implemented. Right now we embedded other packages into ndk, ndk_flutter.


| previous package | operation | new structure |
|:--------|:--------:|--------:|
| ndk_amber | embedded => | ndk_flutter |
| drift_cache_manager  | renamed  | ndk_drift |
| isar  | removed  | discontinued |
| ndk  | -- | ndk |
| ndk_cache_manager_test_suite  | -- | ndk_cache_manager_test_suite |
| ndk_flutter  | -- | ndk_flutter |
| nip07_event_signer  | -- | nip07_event_signer |
| ndk_objectbox  | -- | ndk_objectbox |
| ndk_rust_verifier  |  embedded => |  ndk (native assets) |
| ndk_demo  | -- | ndk_demo |
| sembast_cache_manager  | embedded => | ndk |
| --  | new package | ndk_bip32_keys |


However the embeddings could lead to blurry lines in terms of seperation.
Breaking change for developers (changing the import structure).

Pro:
Ideally there is no further setup required from the developer. Assuming we choose good defaults.

## Alternative proposals

A alternative could be leaving the package structure, enforcing clear seperation.
This would also allow the flexibility reusing and switching out storage dependencies separately for `ndk` `ndk_flutter`.
To make the storage decision explicit for the developers the cache manager argument on the `NDKConfig` could be required with explanations on what to do like: use `MemCacheManger()` to get started long term options are `ObjectboxCacheManger` import via ... etc.

Another benefit is that we can prescreen db packages for their web compatibility and other potential changes in an isolated way.

| previous package | operation | new structure |
|:--------|:--------:|--------:|
| ndk_amber | dependency of | ndk_flutter |
| drift_cache_manager  | renamed  | ndk_drift |
| isar  | removed  | discontinued |
| ndk  | -- | ndk |
| ndk_cache_manager_test_suite  | -- | ndk_cache_manager_test_suite |
| ndk_flutter  | -- | ndk_flutter |
| nip07_event_signer  | -- | nip07_event_signer |
| ndk_objectbox  | -- | ndk_objectbox |
| ndk_rust_verifier  |  embedded => |  ndk (native assets) |
| ndk_demo  | -- | ndk_demo |
| sembast_cache_manager  | dependency of | ndk, ndk_flutter |
| bip32_keys | embedded => | ndk |



## Final Notes

