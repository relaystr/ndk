---
label: Contributing
icon: repo-forked
order: 100
---

# Contributing to NDK

We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github

We use github to host code, track issues and feature requests, and accept pull requests.

## We Use [Github Flow](https://docs.github.com/de/get-started/using-github/github-flow), So All Code Changes Happen Through Pull Requests

Pull requests are the best way to propose changes to the codebase (we use [Github Flow](https://docs.github.com/de/get-started/using-github/github-flow)). We actively welcome your pull requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code, add tests a minimum of 85% coverage is required. Add tests that make sense instead of just targeting the 85%
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Submit that pull request!

## Report bugs using Github's [issues](https://github.com/relaystr/ndk/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/relaystr/ndk/issues); it's that easy!

## New Features and Feature Requests

If you want to propose a new feature, please [open an issue](https://github.com/relaystr/ndk/issues) first to discuss it. We use user stories to describe new features. We provide a template with examples to help you get started; if you are unsure how to write a user story, read [this](https://www.mountaingoatsoftware.com/agile/user-stories).

After we triage your issue, it will either be accepted or rejected. If accepted, you can track the progress in [this board](https://github.com/orgs/relaystr/projects/1).
If you want to work on it yourself, assign it to yourself and start working on it. Preferably let us know that you are working on it (especially for larger features) to increase the chances of merging your PR.

## Communication Channels

Feel free to reach out to us via the following channels:

- [GitHub Issues](https://github.com/relaystr/ndk/issues)
- weekly dev calls (every Wednesday at 14:00 CEST) [link](https://call.element.io/room/#/ndk-47014?password=ywCMPkavHoMfbtwWdzknXg&roomId=%21ntFcnshzkrZDCYXOEF%3Acall.ems.host). Let us know beforehand if you want to discuss something specific so we can add it to the agenda.
- Nostr: [fmar](https://njump.me/fmar.dev) [leo](https://njump.me/leo@camelus.app)
- Email: leo: contact(a t)camelus.app [pgp](https://camelus.app/pgp-key.txt)

## Project Structure

The project is structured in a layered architecture.

- `lib/`
  - `config/`
    - `# contains configuration files`
  - `shared/`
    - `nipX # folders for nip specific code`
    - `# only internal code, no external dependencies!`
  - `data_layer/`
    - `data_sources/`
      - `# external apis, websocket impl etc.`
    - `models/`
      - `# type conversion e.g. json to entity`
    - `repositories/`
      - `# repository implementations (implementing domain_layer repos)`
  - `domain_layer/`
    - `entities/`
      - `# our entities e.g. data types`
    - `repositories/`
      - `# contracts`
    - `usecases/`
      - `# our main code / business logic`
  - `presentation_layer/`
    - `# contains our api design (makes usecases accessible to outside world)`
  - `lib.dart # entrypoint, points to presentation_layer`
- `tests/`
  - `usecases/`
    - `# integration_tests`
  - `unit/`
    - `# unit tests`

The decision for this architecture can be viewed [here](/library-development/adrs/layerd-architecture/).
If you are unsure where to put your code, please ask us. We are happy to help you.

## Documentation Guidelines

Every public-facing API should be documented. <br>
Types of documentation we use are inline docs and retype deployed on [dart-nostr.com](https://dart-nostr.com/).
When you add a new use case or edit a feature, make sure to create/edit a corresponding markdown file in `/doc`.
Generally we use examples in our docs if you do, please add them to `/packages/ndk/example` as a test so we can ensure everything continues to work.



## License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.
