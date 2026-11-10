# Architecture and protocol boundaries

[Home](../README.md) · [Security](security.md) · [Configuration](configuration.md)

## End-to-end flow

1. Cephadm-managed daemons write local files under `/var/log/ceph/<CEPH_FSID>/`; `/var/log/ceph/cephadm.log` is separate.
2. A dedicated `ceph-logreader` process tails four non-overlapping source families. SQLite stores offsets; filesystem chunks hold queued events.
3. Parsers preserve raw text and add daemon, audit, RGW, host and dataset metadata. `ceph.ops` and `ceph.audit` identify the two supported routes.
4. Fluent Bit sends Forward frames through TLS to `logs.example.com:443`. HAProxy forwards TCP through the existing ingress exposure.
5. ingress-nginx reads SNI and passes TLS to the `fluentd-ceph` ClusterIP. Fluentd terminates TLS and authenticates the client chain on 24225.
6. The shared Fluentd process routes Ceph to its Elasticsearch data-stream output, ahead of the Kubernetes catchall. Kubernetes-only filters exclude Ceph tags.
7. Elasticsearch stores all Ceph datasets in `logs-ceph-default`. Kibana searches that stream; Prometheus/Grafana help observe the transport and shared collectors.

## Network map

| From → to | Port | Protocol and boundary |
|---|---|---|
| Ceph host → VIP | 443/TCP | Fluent Forward inside TLS; client and server certificates |
| HAProxy → ingress worker | 30081/TCP | Historical example NodePort; encrypted bytes unchanged |
| ingress → Fluentd ClusterIP/pods | 24225/TCP | Same TLS session; Fluentd is server endpoint |
| Kubernetes log agents → shared collector | 24224/TCP | Existing path; its authentication/TLS details were not supplied |
| Fluentd → Elasticsearch | Target-specific | Separate authenticated connection; inspect actual scheme, CA and hostname verification |
| Local operator → Fluent Bit metrics | 127.0.0.1:2020 | HTTP confined to host loopback |
| Prometheus → Fluentd metrics | 24231/TCP reported | Scraper-only access; exposure and exporter configuration require inventory |

Port and object names here are reusable examples; they are not an inventory of an identifiable environment. No infrastructure addresses are published.

## Why HTTP ingress is the wrong abstraction for the payload

An Ingress still contains an `http.paths` structure, but the legacy SSL-passthrough handler selects by TLS SNI and sends the encrypted stream to the backing Service. It does not interpret a Forward request URI. Ordinary HTTP proxying, HTTP rewrite rules, TLS termination and an HTTP health probe against the Forward socket cannot be substituted without redesign. The ingress backend is the Service ClusterIP in this mode. [Legacy controller documentation](https://kubernetes.github.io/ingress-nginx/user-guide/tls/)

HAProxy must preserve that behavior. An example `default_backend` is not a safe replacement for an existing shared 443 frontend. Inspect current SNI routing, bind ownership, health checks and timeouts. Keepalived provides VIP ownership; the source did not supply its full configuration or a failover exercise.

## Shared state and failure domains

Three Fluentd replicas do not by themselves prove high availability. Each has its own persistent buffer, connections can remain pinned to a pod, and recovery depends on volume availability, controller reconciliation, capacity, routing and destination health. The source mentioned an earlier 50Gi RBD-backed volume claim; current sizes, storage class and replica placement were not provided.

If Fluentd buffer PVCs rely on the same Ceph cluster being observed, storage failure can also impair the logging destination. That is an architectural dependency to verify, not an independently demonstrated outage. Consider an independent diagnostic path and tested recovery for this correlated failure mode.

The historical GitOps ownership chain was Git repository → Argo CD/Helm → Fluent Operator CRs → StatefulSet/generated `app.conf`. Change the owning source, then inspect the generated result on every pod. A manual edit inside a pod will not survive reconciliation.
