# Source coverage and transformation record

[Home](../README.md) · [Evidence](evidence.md) · [Publication review](publication-review.md)

The entire 2,808-line reference (2,809 newline-split entries including terminal newline) was read before authoring. The original and its raw attachments are not repository assets. Documentation was reorganized and rewritten; selected configuration blocks were extracted under explicit provenance, sanitized and separated from recommendations.

| Source section | Destination and preserved detail |
|---|---|
| 1. Scope/evidence | [Evidence](evidence.md): pilot versus reported rollout, versions, missing live objects |
| 2. Architecture | [Architecture](architecture.md): protocol, ports, TLS boundary, ACK limits |
| 3. Inventory/ownership | [Prerequisites](prerequisites.md): discovery, CR scope, GitOps ownership; identities removed |
| 4. Design principles | [Performance](performance.md): protect Ceph, filter isolation, finite buffers |
| 5. Readiness | [Prerequisites](prerequisites.md), [installation](installation.md): checkpoints, consistent state backup |
| 6. Ceph discovery | [Installation](installation.md), [configuration](configuration.md): four source families, rotation, FSID mistakes |
| 7. Package install | [Installation](installation.md): RPM path/version, offline dependencies, competing agents |
| 8. Least privilege | [Installation](installation.md), [security](security.md): named ACL precedence, glob access, SELinux |
| 9. Host runtime | [Installation](installation.md), [configuration](configuration.md): paths, env, systemd, dry-run/start gates |
| 10. PKI | [Certificate lifecycle](certificate-lifecycle.md): trust, issuance, identity copy error, examples |
| 11. Credential install | [Certificate lifecycle](certificate-lifecycle.md), [validation](validation.md): export, key match, chain, positive/negative tests |
| 12. Parsing | [Configuration](configuration.md): parameter values, field model, raw preservation, limits |
| 13. Operator/Fluentd | [Installation](installation.md), [configuration](configuration.md): selectors, mounts, socket, route/filter ordering, incomplete output |
| 14. Ingress/HAProxy | [Architecture](architecture.md), [troubleshooting](troubleshooting.md): passthrough, duplicate route, TCP-only checks |
| 15. ES | [Elasticsearch](elasticsearch.md): template/stream examples, role uncertainty, 403, mappings |
| 16. Search | [Elasticsearch](elasticsearch.md): REST versus KQL, aggregations, timestamps, fresh-event proof |
| 17. Canary | [Installation](installation.md), [validation](validation.md): unique dummy marker, tag match, timeout semantics, hop isolation |
| 18. Staged rollout | [Installation](installation.md): worksheet and one-host gates; no invented proven thresholds |
| 19. Monitoring | [Performance](performance.md): historical samples, exporter caveats, PromQL, capacity formula and alerts |
| 20. Incidents | [Troubleshooting](troubleshooting.md): all 13 incident families and corrective boundaries |
| 21. Renewal | [Certificate lifecycle](certificate-lifecycle.md): remote deployment, overlap, revocation gaps, process reload |
| 22. Day 2 | [Operations](operations.md): daily/weekly, upgrades, retention, host/pod/ES recovery |
| 23. Rollback | [Rollback](rollback.md): stop inputs, config/ACL/PKI/GitOps recovery, corrupt state, lab fault boundaries |
| 24. Acceptance/handover | [Validation](validation.md): security/functional gates and private handover record |
| 25. Journal extension | [Optional journal](optional-journal.md): proposal-only status, cursor, permissions, duplicate/routing risks |
| Appendix A | [Main snapshot](../configs/fluent-bit/ceph.conf): endpoint replaced, semantics retained |
| Appendix B | [Parser snapshot](../configs/fluent-bit/ceph-parsers.conf): preserved parser content |
| Appendix C | Diagnostic/validation scripts, [troubleshooting](troubleshooting.md), [Elasticsearch](elasticsearch.md); scripts hardened and labeled adapted |
| Appendix D | [References](references.md), [evidence](evidence.md), [validation](validation.md): references, milestones and handover boundaries |

## Deliberate publication changes

Internal names, FQDNs, organization/CA labels, FSID, writer username and storage-class identity are replaced or omitted. No host inventory or raw diagnostic transcript is published. Historic topology counts retained in narrative explain the shared runtime, without addresses or server inventory.

The source's instruction to include its original runbook in an internal handover package was **not** followed for this repository: the user's publication restriction takes precedence. No dashboard export, missing production manifest, measurement or successful test was invented.

## Explicit technical improvements outside snapshots

The new scripts do not source an untrusted environment file as root, validate FSID syntax, fail on missing required access, and distinguish optional metrics reachability from pre-start checks. The TLS probe uses separate chain material with OpenSSL's explicit chain flag. ACL backup guidance fixes privileged redirection and captures modified file ACLs. These are adapted tooling/documentation improvements, not silent edits to the historical production snapshots.
