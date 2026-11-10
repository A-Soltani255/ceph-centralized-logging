# Evidence, versions and unresolved questions

[Home](../README.md) · [Source coverage](source-coverage.md) · [Configuration catalog](configuration.md)

The reference is a confidential internal runbook, edition 1.0 dated 9 November 2026. Its underlying screenshots, live clusters and separately uploaded files were not available for independent inspection. “Observed” below means **reported as observed by that source**, not re-tested here. The entire runbook, including appendices A–D, was reviewed. Its operational commands are reference material, not instructions to execute against production.

## Evidence vocabulary

| Label | Meaning |
|---|---|
| SANITIZED SNAPSHOT | Fenced configuration extracted from appendix A or B; endpoint sanitized and line endings normalized; no behavioral tuning |
| SOURCE-REPORTED OBSERVATION | Source describes a command result, incident, configuration state or user report |
| EXAMPLE | Source example, reconstructed shape, or explicitly new proposed implementation; requires target validation |
| RECOMMENDATION | Future hardening or operational practice; no deployment claim |
| UNVERIFIED | Missing live configuration, tests or evidence prevents a conclusion |

## Version record

| Item | Recorded state | Reuse decision |
|---|---|---|
| Ceph daemons | 19.2.7, Squid | Do not substitute the earlier 20.2.2 plan |
| cephadm utility | 19.2.3 | Utility version need not equal daemon container version |
| Separate lab | 19.2.3 | Lab identities excluded; never use its FSID for deployment |
| Fluent Bit | 2.2.2 RPM; `/usr/bin/fluent-bit` | Historical compatibility target, not a current security recommendation |
| Fluent Operator chart | 4.3.0 discussed | Verify chart, image, CRDs and selectors independently |
| Fluentd | 1.19.0 reported in logs | Elasticsearch plugin version and worker mode still needed |
| Kubernetes, ingress-nginx, HAProxy, Keepalived | Exact versions absent | Inventory before schema/runtime validation |
| Elasticsearch, Kibana, Vault, cert-manager | Exact versions absent | No universal compatible manifest or privilege claim |

The source reported five collectors after the pilot, while an earlier inventory contained more storage hosts. This establishes rollout scope only; it does not prove complete cluster coverage. Exact host inventory is deliberately omitted.

## Corrections and open issues

| Issue | Treatment in this project |
|---|---|
| “No NodePort” versus ingress NodePort | Fluentd is ClusterIP; the pre-existing ingress exposure used NodePort 30081. This is not a new Fluentd NodePort. |
| TLS hostname option rejected in 2.2.2 | Preserve the snapshot; flag in-agent server-name enforcement as unresolved. OpenSSL is an independent probe, not a compensating runtime control. |
| CA from one client's Secret accepted other clients | Expected chain trust, not a per-host allowlist. Dedicated trust bundle recommended, not claimed deployed. |
| Client object named for one host with another host's CN | Historical copy error documented; examples use consistent placeholder identities. All real identities need auditing. |
| Source generated TLS fragment includes `protocol tls` inside transport | No standalone generated listener snapshot is represented as production truth. Use CR example; verify actual generated Fluentd syntax with installed runtime. |
| `ceph_rgw_http_status` versus `ceph_rgw_status_code` | Both are real snapshot field names: renamed JSON field versus parsed textual status. Template only explicitly maps the latter; do not silently merge them. |
| Parser marker “parsed” | Means a recognized time field exists, not that every detail field parsed or all numeric types are normalized. |
| Historical metrics | Contextual investigation samples, not a throughput benchmark or before/after performance proof |
| Journal/kernel collection | Proposed only; the new tag is absent from the dedicated Fluentd match |
| Complete output, Vault role, HAProxy, Helm and ES role/template | Not supplied; fragments cannot substitute for live exports |

## Current maintenance review

As of this review on 10 November 2026, community ingress-nginx is retired. Its historical configuration remains useful for understanding this implementation but should not be selected for a new deployment without an explicit maintained support strategy. The Kubernetes retirement announcement says maintenance ended in March 2026 and subsequent fixes will not be provided. [Official notice](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)

A replacement needs verified TCP/TLS passthrough, SNI routing where used, long-lived connection behavior, client certificate preservation, health checks and rollback. No Gateway API or alternative-controller migration has been validated here. A replacement that terminates TLS changes the client-authentication boundary.

Other recorded versions are historical facts, not assertions of current support or vulnerability-free status. Inventory exact builds and perform a dependency advisory review before deployment. A CVE assessment of the live installation was outside the available evidence.
