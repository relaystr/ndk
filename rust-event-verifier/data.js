window.BENCHMARK_DATA = {
  "lastUpdate": 1790432175360,
  "repoUrl": "https://github.com/relaystr/ndk",
  "entries": {
    "Rust event verifier": [
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "5a620249c0e7c066bd73d759e1ec9099957c7dd0",
          "message": "Merge pull request #767 from relaystr/fix/rust-event-verifier-memory\n\nperf: improve rust verifier memory usage",
          "timestamp": "2026-09-13T11:34:36+02:00",
          "tree_id": "7ac48e2a8b61bb09305a141c42db67accd1dd9d2",
          "url": "https://github.com/relaystr/ndk/commit/5a620249c0e7c066bd73d759e1ec9099957c7dd0"
        },
        "date": 1789292246441,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 45412.8,
            "range": "45224-52072",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1568562,
            "range": "1554152-1581440",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "615c767b26efb704a9bb27ffccb3d390d2a0f252",
          "message": "Merge pull request #821 from relaystr/release-34749758580\n\nchore(prerelease): publish ndk 0.10.0-dev.3",
          "timestamp": "2026-09-13T12:06:44+02:00",
          "tree_id": "1c702bcc7b89cdd108235be539b72cd320ae6e00",
          "url": "https://github.com/relaystr/ndk/commit/615c767b26efb704a9bb27ffccb3d390d2a0f252"
        },
        "date": 1789294096565,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 28174,
            "range": "28123-30525",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 894126,
            "range": "892748-896068",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "bead35ac40b72e52293a0b286a90ac847046e3d1",
          "message": "Merge pull request #824 from relaystr/fix/ndk-flutter-file-picker-12\n\nfix(flutter): support file_picker 12",
          "timestamp": "2026-09-13T13:40:20+02:00",
          "tree_id": "3d5e0d092297aca13aeb4e7f3bffb25afef1e3b4",
          "url": "https://github.com/relaystr/ndk/commit/bead35ac40b72e52293a0b286a90ac847046e3d1"
        },
        "date": 1789299743362,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 39637.6,
            "range": "38807-44892",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1489924,
            "range": "1461398-1552876",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "committer": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "distinct": true,
          "id": "887105635d03a86e5b7f1f50a1f00f0364b75bcc",
          "message": "fix release version in PR title",
          "timestamp": "2026-09-13T16:11:35+02:00",
          "tree_id": "2871e7578fdae3caab42f8e3f2550fc5d3446048",
          "url": "https://github.com/relaystr/ndk/commit/887105635d03a86e5b7f1f50a1f00f0364b75bcc"
        },
        "date": 1789308808934,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 51350.4,
            "range": "51176-57293",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1704700,
            "range": "1702514-1709348",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "119a3d2ceb1405b3c16f0cee6ed536355042e00e",
          "message": "Merge pull request #813 from relaystr/chore/remove-brb-io-connect-guard\n\nchore: stop refusing connections to brb.io",
          "timestamp": "2026-09-13T16:19:12+02:00",
          "tree_id": "4feade5645ac98d8e993b8ec9d2c398324148395",
          "url": "https://github.com/relaystr/ndk/commit/119a3d2ceb1405b3c16f0cee6ed536355042e00e"
        },
        "date": 1789309255460,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 52254,
            "range": "51554-66394",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1686910,
            "range": "1659220-1737796",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "775e3ed2e0e699ed802945a60e22ae33660724f0",
          "message": "Merge pull request #826 from relaystr/release-34762315873\n\nchore(prerelease): publish ndk_flutter 0.10.0-dev.4",
          "timestamp": "2026-09-13T16:34:00+02:00",
          "tree_id": "0cb4ccb2417945a942d1d0f62ac79a38b4e113c5",
          "url": "https://github.com/relaystr/ndk/commit/775e3ed2e0e699ed802945a60e22ae33660724f0"
        },
        "date": 1789310171797,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 44921.8,
            "range": "44584-47209",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1546486,
            "range": "1535668-1594200",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "2359d1c844aa3738271f9457ac983ee0ee386675",
          "message": "Merge pull request #823 from relaystr/frnandu/feat-add-websocket-compression-opt-out-for-lower\n\nfeat: add websocket compression opt out",
          "timestamp": "2026-09-14T11:57:10+02:00",
          "tree_id": "4bbe53a453d1d09eddcb73e0d0cea76d83c38fa8",
          "url": "https://github.com/relaystr/ndk/commit/2359d1c844aa3738271f9457ac983ee0ee386675"
        },
        "date": 1789379950279,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 34738.4,
            "range": "34442-38632",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1283954,
            "range": "1242574-1311640",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "committer": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "distinct": true,
          "id": "4ca6ec551645f5689ee52946041710bb67b89049",
          "message": "Merge branch fix/wallet-i18n",
          "timestamp": "2026-09-14T14:01:08+02:00",
          "tree_id": "d563351307452f1e3a8efcf789cdcff15d52c1bf",
          "url": "https://github.com/relaystr/ndk/commit/4ca6ec551645f5689ee52946041710bb67b89049"
        },
        "date": 1789387481101,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 34282.4,
            "range": "33848-37067",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1322138,
            "range": "1288400-1366070",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "committer": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "distinct": true,
          "id": "fa02d19a7d361f06f00cf542f9f2f9fd85cb09df",
          "message": "add bip321 to nwc pay example",
          "timestamp": "2026-09-14T23:29:51+02:00",
          "tree_id": "e191de05c5d014d9a472ff57f101cf046198f976",
          "url": "https://github.com/relaystr/ndk/commit/fa02d19a7d361f06f00cf542f9f2f9fd85cb09df"
        },
        "date": 1789421513228,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 52175.6,
            "range": "51951-57451",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1702416,
            "range": "1693098-1728728",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "committer": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "distinct": true,
          "id": "bf8eca5f022d279bf02f9e1559a8ef18248d9ad1",
          "message": "exclude pre-releases to publish docs and sample-app",
          "timestamp": "2026-09-15T16:39:37+02:00",
          "tree_id": "97f302cfc372407a2f374f6d81f3647aae6e9994",
          "url": "https://github.com/relaystr/ndk/commit/bf8eca5f022d279bf02f9e1559a8ef18248d9ad1"
        },
        "date": 1789483299974,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 46892,
            "range": "46803-53247",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1531906,
            "range": "1520272-1581958",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "83db992571af5a97cb4a15040fe93c1eae719478",
          "message": "Merge pull request #803 from relaystr/feat/nip-82-applications-releases-zapstore-support\n\nfeat: nip-82 applications releases zapstore support",
          "timestamp": "2026-09-16T22:47:24+02:00",
          "tree_id": "778552d4fa27e27bba0566964e29b659681a6ac4",
          "url": "https://github.com/relaystr/ndk/commit/83db992571af5a97cb4a15040fe93c1eae719478"
        },
        "date": 1789591756594,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 50413,
            "range": "50324-56229",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1740934,
            "range": "1725232-1764168",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "daa5b3caaaa9f8a8b743f40ac1d8e0d45b55f91c",
          "message": "Merge pull request #830 from relaystr/release-35148662800\n\nchore(prerelease): publish ndk_drift 0.1.1-dev.16, ndk 0.10.0-dev.4, ndk_flutter 0.10.0-dev.5, ndk_objectbox 0.2.12-dev.13",
          "timestamp": "2026-09-16T23:28:50+02:00",
          "tree_id": "933d9dd1825c59b07a5b798133b1cf143c6c8b5a",
          "url": "https://github.com/relaystr/ndk/commit/daa5b3caaaa9f8a8b743f40ac1d8e0d45b55f91c"
        },
        "date": 1789594239945,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 45007,
            "range": "44837-48085",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1640220,
            "range": "1629170-1670352",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "58687994+1-leo@users.noreply.github.com",
            "name": "Leo",
            "username": "1-leo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "2325f3f0105fcf8142adb9cd536ea1b1f73d5811",
          "message": "Merge pull request #818 from relaystr/1-leo/cashu-mint-quote-lock-key-is-random-and-unrecove\n\nfeat: deterministic cashu quote key",
          "timestamp": "2026-09-17T15:33:58+02:00",
          "tree_id": "5f454c45aed7ed1cd12ff97cfd8c46ec09744845",
          "url": "https://github.com/relaystr/ndk/commit/2325f3f0105fcf8142adb9cd536ea1b1f73d5811"
        },
        "date": 1789652149816,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 43159.2,
            "range": "42988-45931",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1646216,
            "range": "1634268-1661170",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "3fb319dae79ba90712c2abd9a4192974ab309297",
          "message": "Merge pull request #805 from relaystr/feat/relay-auth-broadcast\n\nfeat: let a broadcast say which identity it may be attributed to",
          "timestamp": "2026-09-19T13:36:28+02:00",
          "tree_id": "1aa592944be4d6fb4d7c8df11b13d232c6e82b76",
          "url": "https://github.com/relaystr/ndk/commit/3fb319dae79ba90712c2abd9a4192974ab309297"
        },
        "date": 1789817890839,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 39828.4,
            "range": "39655-42169",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1317984,
            "range": "1316192-1320282",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "8f748b225bef7a2054f7c8fbe8ccdb8c57ceb727",
          "message": "Merge pull request #835 from relaystr/release-35440576688\n\nchore(prerelease): publish ndk_drift 0.1.1-dev.17, ndk 0.10.0-dev.5, ndk_flutter 0.10.0-dev.6, ndk_objectbox 0.2.12-dev.14",
          "timestamp": "2026-09-19T13:42:05+02:00",
          "tree_id": "47ca7aca4fdda838ded9a7d65824426dc2d28e88",
          "url": "https://github.com/relaystr/ndk/commit/8f748b225bef7a2054f7c8fbe8ccdb8c57ceb727"
        },
        "date": 1789818222082,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 28539.6,
            "range": "28506-30929",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 909362,
            "range": "905568-913178",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "6f5491953d349f224dfeb98f8982bce1712fe10e",
          "message": "Merge pull request #836 from relaystr/refactor/rename-relay-auth-to-auth-policy\n\nrefactor: rename RelayAuth to AuthPolicy",
          "timestamp": "2026-09-21T15:09:41+02:00",
          "tree_id": "3e364b67b4fea913cdc105f73868d65e5acc8de3",
          "url": "https://github.com/relaystr/ndk/commit/6f5491953d349f224dfeb98f8982bce1712fe10e"
        },
        "date": 1789996292583,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 28189.6,
            "range": "27578-30310",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 826692,
            "range": "808376-845168",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "committer": {
            "email": "frnandu@atomicmail.io",
            "name": "fmar",
            "username": "frnandu"
          },
          "distinct": true,
          "id": "0c09fbb84f44909b80839147d51d1b5520226e36",
          "message": "cleanup",
          "timestamp": "2026-09-21T20:26:26+02:00",
          "tree_id": "a5c62200a19945bdbd97b961a0e671fa09986127",
          "url": "https://github.com/relaystr/ndk/commit/0c09fbb84f44909b80839147d51d1b5520226e36"
        },
        "date": 1790015297456,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 45406.6,
            "range": "45262-48318",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1624556,
            "range": "1614206-1699672",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "907b8f14fa71f8b081b3fe879fed38d4664a6be0",
          "message": "Merge pull request #841 from relaystr/feat/broadcast-retry-delivery-opt-out\n\nfeat: add retryDelivery opt-out to broadcast",
          "timestamp": "2026-09-23T11:08:58+02:00",
          "tree_id": "66e47bf92ce5b28ab785bde2d0c291ee9ecf1c94",
          "url": "https://github.com/relaystr/ndk/commit/907b8f14fa71f8b081b3fe879fed38d4664a6be0"
        },
        "date": 1790154630399,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 26484.6,
            "range": "26349-28974",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 780456,
            "range": "770872-840222",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "8a218c6403957c6c0bd7266aca5dcfde450a1ae9",
          "message": "Merge pull request #839 from relaystr/chore/hooks-version-range\n\nchore(ndk): allow hooks 2.x",
          "timestamp": "2026-09-23T11:13:01+02:00",
          "tree_id": "60c3373f94b5e2e2d628256b26a417fe60715cef",
          "url": "https://github.com/relaystr/ndk/commit/8a218c6403957c6c0bd7266aca5dcfde450a1ae9"
        },
        "date": 1790154899632,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 45261,
            "range": "45178-48238",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1603806,
            "range": "1592292-1635992",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "b0a02b4197ec12d5395656ee408c8f85fec3abe6",
          "message": "Merge pull request #848 from relaystr/release-35841620020\n\nchore(prerelease): publish ndk_drift 0.1.1-dev.18, ndk 0.10.0-dev.6, ndk_flutter 0.10.0-dev.7, ndk_objectbox 0.2.12-dev.15",
          "timestamp": "2026-09-23T11:23:57+02:00",
          "tree_id": "07ed67f8c3d65d77e6f453946d1e6849f00f1985",
          "url": "https://github.com/relaystr/ndk/commit/b0a02b4197ec12d5395656ee408c8f85fec3abe6"
        },
        "date": 1790155526168,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 27888,
            "range": "26838-28476",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 850986,
            "range": "811668-860076",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "9e5ae6d5c7f8c840689ed4e7740f9af5cbe50ea9",
          "message": "Merge pull request #840 from relaystr/chore/ndk-sdk-3.9\n\nchore: require Dart SDK 3.9",
          "timestamp": "2026-09-23T13:56:37+02:00",
          "tree_id": "46cb17b6b4facb6354aae5252e89e9d313363fcb",
          "url": "https://github.com/relaystr/ndk/commit/9e5ae6d5c7f8c840689ed4e7740f9af5cbe50ea9"
        },
        "date": 1790164703366,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 51232.2,
            "range": "50963-54522",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1709478,
            "range": "1704672-1743466",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "23c50c25ff5c3da09db10b22cb61ace63f1cff60",
          "message": "Merge pull request #845 from relaystr/feat/auth-policy-blossom\n\nfeat: auth policy blossom",
          "timestamp": "2026-09-25T12:11:04+02:00",
          "tree_id": "3c880685fe94d6472c38c5d0921643dca7b65fa5",
          "url": "https://github.com/relaystr/ndk/commit/23c50c25ff5c3da09db10b22cb61ace63f1cff60"
        },
        "date": 1790331162595,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 46970.4,
            "range": "46808-49745",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1591590,
            "range": "1586820-1611198",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "68782063+nogringo@users.noreply.github.com",
            "name": "Nogringo",
            "username": "nogringo"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "035e51092604d5f428be29910d4709a528b5e85e",
          "message": "Merge pull request #854 from relaystr/release-36122587749\n\nchore(prerelease): publish ndk_drift 0.1.1-dev.19, ndk 0.10.0-dev.7, ndk_flutter 0.10.0-dev.8, ndk_objectbox 0.2.12-dev.16",
          "timestamp": "2026-09-25T14:21:32+02:00",
          "tree_id": "32d23572d7ded014a2ad0965105e474306bc855e",
          "url": "https://github.com/relaystr/ndk/commit/035e51092604d5f428be29910d4709a528b5e85e"
        },
        "date": 1790338995532,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 45020.8,
            "range": "44630-50937",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1526416,
            "range": "1509950-1570604",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "frnandu@atomicmail.io",
            "name": "frnandu",
            "username": "frnandu"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "c5b20b38edcfe7ca2f6394571f52cff272453b83",
          "message": "Merge pull request #844 from relaystr/fix/nwc-settle-deadline-lookup\n\nfix(nwc): expose hold settle deadline",
          "timestamp": "2026-09-26T14:14:13Z",
          "tree_id": "8982635890a85687f3eba7e50866c563c4027d67",
          "url": "https://github.com/relaystr/ndk/commit/c5b20b38edcfe7ca2f6394571f52cff272453b83"
        },
        "date": 1790432172851,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "RustEventVerifier.verify",
            "value": 39732,
            "range": "39560-41662",
            "unit": "ns/op",
            "extra": "9 samples x 5000 operations after 1000 warmup operations"
          },
          {
            "name": "RustEventVerifier.verify.large_event",
            "value": 1314686,
            "range": "1312168-1338120",
            "unit": "ns/op",
            "extra": "9 samples x 500 operations after 100 warmup operations; 200 tags with 1 KiB values, 64 KiB content"
          }
        ]
      }
    ]
  }
}