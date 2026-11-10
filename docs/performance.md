# Reliability, capacity and shared-collector performance

[Home](../README.md) · [Operations](operations.md) · [Troubleshooting](troubleshooting.md)

## Delivery contract

The snapshot requests Forward acknowledgments and retries. A receiver can accept a chunk while its ACK is lost, causing a resend and duplicates. A Forward ACK does not establish successful Elasticsearch indexing or the durability of the receiver's exact buffer policy. No exactly-once, zero-loss, guaranteed recovery time or demonstrated failover claim is made.

Tail SQLite DBs record file positions; filesystem chunks hold pending records. Both are needed for continuity. `storage.sync normal` and normal DB sync trade sync overhead against crash durability. Checksums help identify corruption, not recover lost bytes. A clean restart is not equivalent to an abrupt power-loss test.

The historical 4G logical output queue is finite: when full, the oldest queued chunks for that output may be discarded. It is not a filesystem quota covering DB/WAL, other outputs, logs and all metadata. `Retry_Limit no_limits` does not remove that cap. The Fluent Bit storage documentation describes this output eviction behavior. [Fluent Bit 2.2 buffering](https://docs.fluentbit.io/manual/2.2/administration/buffering-and-storage)

Other loss paths include lines above the 2M limit with `Skip_Long_Lines On`, unreadable sources, no-offset historical skipping, aggressive rotation/compression, buffer/PVC deletion, disk corruption and destination rejection. Source archives and independent retention may be needed for audited recovery. No complete backfill/reconciliation implementation is supplied.

## Protect Ceph first

Run the collector with narrow permissions and measured CPU/memory/IO limits. The unit's 200% CPU and 256M memory values are a historical pattern, not a validated envelope for every OSD/RGW workload. In-memory chunks, per-file buffers, parser allocations and backlog recovery all contribute to RSS. A memory cap that is too low can induce restart loops and replay pressure.

Do not change OSD/MON/MGR units, CRUSH, pools or daemon verbosity to debug ordinary collection. Raising debug verbosity can increase Ceph's own work and log IO, beyond the agent's resource limits. Every temporary debug change needs a rate estimate, stop condition and reversal.

## Shared Fluentd bottleneck

The source reports three Kubernetes-oriented Ruby filters originally matching all tags. Ceph records paid for that processing before routing. Scoping each filter to `/^(?!ceph\.).*/` removed unnecessary Ceph processing while retaining existing expressions for other tags. Confirm generated syntax and route order in every pod; a catchall match before the Ceph match consumes the events first.

This optimization does not isolate CPU, memory, output errors or storage between pipelines. A dedicated collector can reduce that shared failure domain, but was not the implemented design. More replicas need compute and storage, and long-lived TCP sessions may not rebalance immediately. More CPU quota may not proportionally accelerate one Ruby worker. A proposed `workers: 2` change requires plugin and file-buffer-path compatibility testing and is not evidenced as deployed.

## What the historical samples establish

The following source-reported samples are retained as investigation context. They are not independently measured or comparable benchmark runs:

| Sample | Cautious interpretation |
|---|---|
| Approximately 2.58 million Ceph and 1.58 million Kubernetes documents in selected 15-minute views | View counts may include backlog and timestamp-window effects; not steady-state capacity |
| Roughly 6.1k output records/s at one moment | A transient aggregate, not an SLO or sustainable rate |
| Ceph slow-flush warnings around 20–24 seconds | Latency symptom requiring correlation with output work and ES health |
| Ceph queue often near zero; Kubernetes queue sometimes around 12 chunks | In-flight work and transient sampling can hide pressure; no proof the Ceph buffer filled |
| Reported availability near 99–100%, with tens of MiB to about 114MiB buffered | Does not demonstrate overflow blocking; verify exporter units |
| Pod CPU about 867–958m and RAM about 476–532Mi, under a reported one-core limit | Little CPU headroom at those times, even when sampled throttling was zero |

The evidence does not quantify improvement after the filter change, prove `overflow_action block` fired, or locate every bottleneck in Elasticsearch. A backlog burst after ACL repair can be much larger than steady source production.

## Sizing and recovery

```text
buffer bytes ≈ source bytes/second × outage seconds × safety factor
drain time ≈ backlog bytes / (sustainable output bytes/second − new input bytes/second)
```

The second estimate only makes sense when output exceeds ongoing input. Include actual chunk expansion/compression, DB and filesystem overhead, per-output policy, disk reserve and rotation retention. Example arithmetic only: 5 MiB/s for 15 minutes produces about 4.4 GiB before margin, beyond the snapshot's 4G output budget. This is not a measured host rate.

Source throttling/dropping may protect Kubernetes but compromise audit completeness. Agree priorities and loss policy explicitly. Pausing an agent protects shared collectors while allowing Ceph logs to continue rotating, so the pause also consumes source-retention time. Recover in stages and reconcile known loss windows instead of promising eventual delivery of every record.

## Monitoring contract

| Layer | Required observations |
|---|---|
| Ceph host | Agent active/restarts, CPU/IO/RSS, Ceph health/latency, file growth, source ACLs, free disk, DB/chunk size |
| Fluent Bit | Inputs/outputs, retries/errors/drops, chunk state, oversized lines, parse outcomes; actual exported names vary by build |
| Fluentd | Per-output and per-pod queues/bytes, flush duration, retries, CPU/RSS/OOMs, listener and mount health |
| Elasticsearch | Write rejection deltas, queues, indexing pressure, shard distribution, CPU/disk, auth and mapping failures |
| End to end | Fresh Ceph **and** Kubernetes records, unique canaries, source/ingest timestamps where explicitly implemented |
| PKI | Issuance failure and installed client/server expiry; deployment drift from Secret version |

Loopback metrics: `/api/v1/metrics` and `/api/v1/metrics/prometheus` on 127.0.0.1:2020. Fluentd plugin IDs reported were `out_ceph_elasticsearch` and `out_elasticsearch_datastream_v2`.

```promql
sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="fluentd",container="fluentd"}[2m]))

sum by (pod) (rate(container_cpu_cfs_throttled_periods_total{namespace="fluentd",container="fluentd"}[5m]))
/
clamp_min(sum by (pod) (rate(container_cpu_cfs_periods_total{namespace="fluentd",container="fluentd"}[5m])), 1e-9)

fluentd_output_status_buffer_queue_length{namespace="fluentd",plugin_id=~"out_ceph_elasticsearch|out_elasticsearch_datastream_v2"}
fluentd_output_status_buffer_total_bytes{namespace="fluentd",plugin_id=~"out_ceph_elasticsearch|out_elasticsearch_datastream_v2"}
fluentd_output_status_buffer_available_space_ratio{namespace="fluentd"}
```

Inspect metric type and unit before applying `rate` or multiplying by 100. A queried `num_records_total` series was absent in the source; another exporter exposed `emit_records`. A retry-count gauge is not automatically a monotonic counter. Use metric discovery plus logs. Missing data does not mean zero errors; scrape health does not prove delivery.

Alert on sustained queue growth, diminishing disk margin, disappearing freshness, repeated TLS errors, OOMs, rising parse failures and write-rejection deltas. Define thresholds locally and exercise them in a lab. No fabricated dashboard or tested alert rules are included.
