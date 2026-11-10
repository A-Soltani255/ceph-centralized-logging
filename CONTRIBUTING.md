# Contributing

This repository is publicly visible with owner-authorized publication of the sanitized material. Licensing remains undecided; no open-source license is granted. Do not treat availability as permission to redistribute or contribute third-party/company-owned material. Establish contribution rights first.

Keep changes small and evidence-based. Label a configuration as a sanitized snapshot, an example, a recommendation or unverified. Do not overwrite historical snapshots with tuning changes; add a reviewed version and update provenance. Explain the operational trigger, new behavior, security implications and rollback in each pull request.

Before review, run the documented checks, inspect the staged diff, scan working files and Git history for secrets, and validate links. Record checks actually run and those skipped. A YAML parse is not a successful deployment. Never run fault injection against real shared infrastructure as a documentation test.

Use synthetic logs and example domains. Keep raw runbooks, live exports, credentials, certs, keys, customer payloads and incident screenshots out of Git. Even diagnostic output can identify infrastructure. Follow [SECURITY](SECURITY.md) for confidential reports and [publication review](docs/publication-review.md) before external sharing.

Suggested commits: `docs: explain Forward TLS boundaries`, `fix: clarify receiver acceptance gate`, `test: validate configuration references`. Do not claim performance improvement without comparable measurements and permission to publish them.
