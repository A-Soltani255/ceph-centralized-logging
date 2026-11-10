# Troubleshooting and historical incidents

[Home](../README.md) · [Diagnostics scripts](validation.md) · [Rollback](rollback.md)

Preserve buffers and protect existing Kubernetes delivery first. The incidents below are source-reported history, with sanitized identities. They are not newly reproduced defects or evidence that the present live system has the same state.

## Failure isolation order

Confirm the FSID and service-user access; check configuration and credential readability; establish the receiver's pod-local listener; verify selector/endpoints; test direct TLS to a forwarded pod port; then test ingress/VIP SNI; finally check tags, output errors and a unique indexed canary. Always observe Kubernetes freshness alongside Ceph. This order prevents treating every EOF as a certificate issue.

| Symptom | Evidence / explanation | Corrective action and verification |
|---|---|---|
| FSID directory missing | Source described a mistyped UUID, separate from ACL problems | Copy exact target FSID; check directory and environment hidden characters; do not chmod a nonexistent path |
| File opens by name but glob scan fails | Named reader ACL was `--x`; supplementary Ceph group did not override it | Grant effective directory `r-x` and file read; enumerate as service user; inspect parents/mask and post-rotation inheritance |
| Cannot open config | File or parent permissions prevented non-root read | Root ownership, reader group and 0640; verify actual service identity; do not run permanently as root |
| Unknown `tls.verify_hostname` | Recorded 2.2.2 binary rejected setting | Preserve known syntax, keep chain verification enabled; resolve runtime name enforcement through target-version testing |
| Vault CN not allowed | Issuer policy returned a 400 | Correct requested identity and narrowly allowed PKI role; verify CertificateRequest and Ready state |
| Unable to get local issuer | Intermediate unavailable during chain construction | Verify leaf with approved root and untrusted intermediate; check actual transmitted chain |
| Peer sends `unknown ca` | Receiving peer rejected presented chain | Inspect peer's trust bundle and direction of failure; never mount client private keys in Fluentd as a trust workaround |
| TLS unexpected EOF | SNI, route, absent listener or TLS failure can cause this | Test local listener and direct port-forward before reissuing certificates |
| CR exists but 24225 refuses | Generated source/mount propagation was not effective on all pods | Reconcile owner CR/selectors/mounts; inspect `app.conf` privately and socket on every pod |
| EndpointSlice lists pods but no delivery | Selector success is not application readiness | Verify actual 24225 listener and TLS on each target |
| Duplicate ingress host/path | Admission rejected a second object with same host and `/` | Edit the existing GitOps-owned route; review ownership/pruning before removing a duplicate |
| 403 `indices:admin/data_stream/get` | Writer lacked plugin metadata access; Ceph output activation coincided with Kubernetes disruption | Pause new sources, repair scoped writer permissions, verify with same identity and both streams |
| Kubernetes logs lag after full Tail activation | Broad Kubernetes Ruby filters processed Ceph; high load and slow flush were observed | Scope all relevant filters, preserve route order, measure shared capacity; avoid claiming quantified improvement |
| Canary absent with successful TLS | Tag/Match mismatch or output rejection can occur after transport succeeds | Ensure `ceph.ops`, receiver match and writer success; search exact new marker |
| Client object names and CN differ | Copy/paste identity error did not necessarily block same-CA authentication | Audit and reissue per-host identities; establish explicit authorization if required |
| Slow flush, no apparent full queue | In-flight work, CPU cost or ES delay can exist without full buffers | Correlate per-output flush, CPU, writes and queue deltas; do not hide warning by raising threshold |
| PromQL has no data or zero retry rate | Wrong metric name or gauge interpreted as counter | Inspect exporter metadata and logs; absent series is not success |
| Duplicates after reconnect | Ambiguous ACK or replay | Preserve source/time/sequence evidence; do not delete offsets to deduplicate |
| New files stop after rotation | Creation mode, mask or logrotate changed access | Test as reader, compare ACL snapshot and durable rotation policy with Storage |
| Journal tag arrives in wrong destination | Proposed tag not present in Ceph receiver match | Stop extension; fix explicit routing/mapping before sending journal traffic |

## Read-only diagnostic commands

```bash
sudo journalctl -u fluent-bit-ceph --since '10 minutes ago' --no-pager
systemctl show fluent-bit-ceph -p MainPID -p MemoryCurrent -p CPUUsageNSec
df -h /var
sudo du -sh /var/lib/fluent-bit-ceph
kubectl -n fluentd top pods --containers
kubectl -n fluentd get endpointslice -l kubernetes.io/service-name=fluentd-ceph
kubectl -n fluentd logs fluentd-0 --since=10m
kubectl -n ingress-nginx get deploy ingress-nginx-controller -o yaml
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
```

Treat diagnostic output as confidential: it can contain real hostnames, identities, queries and payloads. Do not paste raw logs or generated output configuration into public issues.

## Direct receiver isolation

On an authorized admin workstation, terminal A:

```bash
kubectl -n fluentd port-forward --address 127.0.0.1 pod/fluentd-0 12425:24225
```

Terminal B can run the TLS probe with `logs.example.com` as the verified identity and `127.0.0.1:12425` as the connect override. Retain SNI and hostname checking. A port-forward failure reporting connection refused inside the pod locates the issue before ingress. Stop port-forward after diagnosis.

If direct TLS works while VIP access fails, inspect controller passthrough flag, route uniqueness, Service port, NodePort and HAProxy mode. A temporary port-forward to the ingress controller's 443 can isolate that hop too. TCP checks only prove reachability; test application delivery afterward.

## Elasticsearch correlation

```http
GET _cluster/health
GET _cat/thread_pool/write?v&h=node_name,active,queue,rejected,completed
GET _nodes/stats/indices/indexing,thread_pool
GET _cat/shards/.ds-logs-ceph-default*?v&expand_wildcards=all
```

Compare rejection counters over time. One primary write shard is not multiplied by the number of ES nodes. Prove a shard-level bottleneck before changing shard geometry via template and rollover. A Fluentd informational filter-chain-optimization message is not itself a crash.

## Evidence to retain internally

Record UTC incident bounds, impact to both streams, source growth, queue/disk/resource time series, exact auth or mapping errors, canary IDs, GitOps revision, software/plugin versions, effective routing and certificate public metadata. Keep original snapshots in restricted incident storage and sanitize any shared extract. Do not collect key bytes. Identify the last known delivered event and possible rotation/eviction loss window before asserting recovery completeness.
