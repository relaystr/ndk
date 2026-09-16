window.BENCHMARK_DATA = {
  "lastUpdate": 1789591760049,
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
      }
    ]
  }
}