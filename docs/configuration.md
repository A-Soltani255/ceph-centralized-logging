# Configuration catalog and integration contract

[Home](../README.md) · [Installation](installation.md) · [Evidence](evidence.md)

All paths below are repository-relative. The [provenance manifest](../configs/provenance.json) records source sections and SHA-256 hashes of extracted sanitized content. Source section numbers refer to the confidential reference; it is not distributed. LF normalization means these files are not byte-identical to an independently supplied original upload. Behavioral fidelity is assessed against the fenced source content.

## Artifact register

| File | Provenance and purpose | Prerequisites / compatibility | Deployment / verification / rollback |
|---|---|---|---|
| `configs/fluent-bit/ceph.conf` | SANITIZED SNAPSHOT, appendix A; service, four Tail inputs, parsing, metadata and Forward output | Historical Fluent Bit 2.2.2; exact parser sibling, environment, ACLs, certificates, persistent state | Install at `/etc/fluent-bit/ceph.conf`; dry run as reader, canary and sample records; restore matching prior config without deleting state |
| `configs/fluent-bit/ceph-parsers.conf` | SANITIZED SNAPSHOT, appendix B; 14 parsers | Same binary and source formats; Ruby-style named captures are not a JavaScript parser contract | Install at declared `Parsers_File`; test representative synthetic records then controlled real samples; revert together with main config |
| `configs/fluent-bit/fluent-bit-ceph.service` | EXAMPLE from observed unit pattern, §9.4 | systemd directives/kernel support; account, environment, config and writable state exist | Review resource limits, install unit, daemon-reload; inspect `systemctl show`; stop agent and restore old unit/config |
| `examples/environment/ceph.env.example` | EXAMPLE host identity template | Valid cluster UUID and this host name; no secrets | Render outside Git to `ceph.env`; validate directory, no CR; restore only this host's previous values |
| `configs/fluent-bit/ceph-canary.conf.example` | EXAMPLE, §17.2; single dummy event | TLS assets, routable `ceph.ops`, unique marker; same binary | Run isolated, bounded test as reader; search exact marker; stop only test process, no DB to reset |
| `configs/fluent-bit/journal.proposed.fragment.example.conf` | PROPOSED EXAMPLE, §25.4; journal input | Journal permissions, plugin availability, new routing and mappings | Do not append to baseline; isolated cursor/test first; remove input and preserve cursor on rollback |
| `configs/fluentd/cluster-input.example.yaml` | EXAMPLE observed shape, §13.4; mTLS listener | Installed `fluentd.fluent.io/v1alpha1` schema, global selector, TLS mounts | Integrate via GitOps; inspect generated source and socket on every pod; revert CR with source agents paused |
| `configs/fluentd/selector.fragment.example.yaml` | EXAMPLE, §13.3; selection contract | Existing ClusterFluentdConfig; labels must match intended resources | Merge into owner resource, never apply standalone; inspect generation; revert owning revision |
| `configs/fluentd/mounts.historical.fragment.example.yaml` | HISTORICAL EXAMPLE, §13.5; server key and client CA mounts | Existing Fluentd CR mount fields, Secret names, UID/GID mode 0440 | Merge after schema review; test readability; restore old references, keep valid trust overlap |
| `configs/fluentd/service.example.yaml` | EXAMPLE, §13.6; ClusterIP 24225 | Match real pod labels and listener; no new Fluentd NodePort | GitOps apply; EndpointSlices plus per-pod socket test; revert selector/port revision |
| `configs/fluentd/routing-order.fragment.example.conf` | EXAMPLE commentary contract from §13.8 | Existing three Kubernetes Ruby filters and Ceph output | Modify each owning filter tag, preserve expressions; inspect all pods and both streams; revert isolated filter change |
| `configs/fluentd/elasticsearch-output.fragment.example.conf` | INCOMPLETE EXAMPLE, §13.9; observed plugin/tag/stream identifiers | Full live ClusterOutput, plugin version, credentials, TLS and file buffer missing | Never apply as complete output; obtain/export owner CR privately; test writer and canary; revert while preserving queued data |
| `configs/ingress/ingress.example.yaml` | LEGACY EXAMPLE observed shape, §14.2 | Retired ingress-nginx; enabled passthrough, class, unique host, ClusterIP | Reproduction/migration reference only; SNI/TLS/canary tests; restore owning route without duplicate host/path |
| `configs/haproxy/haproxy.example.cfg` | EXAMPLE, §14.4; TCP route sketch | Site frontend ownership, real VIP/workers, timeouts/defaults from full config | Fill placeholders in private staging; `haproxy -c` on full candidate; site-approved reload/rollback |
| `configs/cert-manager/client.example.yaml` | EXAMPLE, §10.4; client for `ceph-node-02` | cert-manager v1 API, ClusterIssuer, constrained Vault role | Correct name/SAN/CN/Secret per node; Ready, identity, EKU and key match; restore valid pair only |
| `configs/cert-manager/server.example.yaml` | EXAMPLE, §10.4; Fluentd server identity | Same issuer requirements; actual existing Certificate name must be discovered | Integrate existing resource; verify SAN/chain and served certificate; controlled valid-pair/trust rollback |
| `configs/elasticsearch/create-template.example.http` | EXAMPLE, §15.3; fresh-environment template | Target ES version, template precedence, mapping/retention review | Dev Tools only after review; simulate template, inspect resulting mapping; revert template for future indices, not existing data |
| `configs/elasticsearch/create-stream.example.http` | EXAMPLE, §15.3; create then inspect stream | Approved matching template and provisioning identity | Fresh target only; metadata and canary test; preserve stream/data rather than deleting for rollback |

No Keepalived, complete ClusterOutput, Vault role, dashboard, NetworkPolicy or working migration manifest was supplied. None is fabricated here. The historical client-CA mount is retained to explain the deployed trust model, not endorsed as the long-term trust-distribution mechanism.

## Fluent Bit input contract

| Input | Paths | Tag / DB |
|---|---|---|
| General | FSID `*.log` plus top-level `cephadm.log`, excluding audit/RGW families | `ceph.ops` / `ops.db` |
| Audit | FSID `ceph.audit.log` | `ceph.audit` / `audit.db` |
| RGW debug | FSID `ceph-client.rgw.*.log` | `ceph.ops` / `rgw-debug.db` |
| RGW operations | FSID `ops-log-ceph-client.rgw.*.log` | `ceph.ops` / `rgw-ops.db` |

All DBs live under `/var/lib/fluent-bit-ceph`. Each input uses `Key log`, `Path_Key source_file`, normal DB sync, WAL journal mode, `Read_from_Head Off`, 10-second refresh, 30-second rotate wait, 32k initial line buffer, 2M maximum line buffer, `Skip_Long_Lines On`, 1M static batch size and filesystem storage. These are snapshot settings, not universally safe capacity defaults. Compressed historical archives are outside these patterns.

Offsets and chunks are different state. A persisted DB resumes known files; `Read_from_Head Off` governs newly discovered files without saved offsets. Replacing DB paths may skip or replay data. Never share a DB between two processes or two hosts. Rotation can outpace collection even with persistent state.

## Processing and record shape

The first parser filter tries cluster-channel, daemon-line and RGW JSON formats. Another parses `source_file` into daemon/file-kind metadata. Detail parsers recognize audit commands, RocksDB source location, MON state, MGR actions and RGW request start/completion/Beast lines. `Reserve_Data On` and `Preserve_Key On` retain evidence when parsing fails.

RGW JSON keys are renamed to `ceph_rgw_*` to reduce collisions. Renaming preserves incoming types, so numeric-looking strings still need mapping review. `ceph_rgw_http_status` from JSON and `ceph_rgw_status_code` from textual parsers are distinct fields. Neither should be silently renamed during publication.

`record_modifier` adds `ceph_host`, `ceph_fsid` and `environment production`. Modify rules default `ceph_parse_status=unparsed` and `ceph_dataset=ceph.other`; a recognized time field changes the marker to `parsed`. Daemon/file-kind rules select `ceph.mon`, `ceph.mgr`, `ceph.osd`, `ceph.mds`, `ceph.rgw`, `ceph.cluster` or `ceph.audit`. These are values in **one** data stream, not separate streams.

`Copy log message` is intended as a fallback when `message` is absent; verify modify-plugin behavior and actual indexed fields on the target release. Preserve the scalar `log` mapping: introducing `log.file.path` collides with a text `log` field. Ceph debug numbers are verbosity, not severity levels. Audit command strings and RGW URIs may contain sensitive data; namespacing does not redact them.

## Service and output controls

`Flush 5`, foreground mode and info diagnostics support systemd supervision. Metrics bind only to loopback port 2020. `storage.sync normal`, checksums, `storage.max_chunks_up 16` and `storage.backlog.mem_limit 16M` balance memory and recovery work, without promising power-loss durability. They do not constitute a complete RSS limit.

The single Forward output matches `ceph.*`, sets one worker, unlimited retry attempts, client certificate/key paths, CA verification, SNI and ACKs. Its 4G logical output limit can evict old chunks; unlimited retries do not mean unlimited retention. The literal `ceph.*` agent match and dedicated `ceph.ops ceph.audit` receiver match must be considered together before introducing another tag.

## Fragment safety

YAML parsing is not CRD schema validation. Fragment files lack a complete resource envelope and are excluded from whole-resource Kubernetes schema checks. HAProxy lacks the full site's defaults, timeouts and bind/routing policy. The Elasticsearch output fragment deliberately omits unknown credentials/TLS/buffer fields; it is not runnable. There is no batch deployment script.
