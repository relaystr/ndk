window.BENCHMARK_DATA = {
  "lastUpdate": 1789299746570,
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
      }
    ]
  }
}