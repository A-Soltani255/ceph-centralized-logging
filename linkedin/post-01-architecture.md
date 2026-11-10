# Post 1 draft — From physical Ceph nodes to a shared logging platform

**Review status:** Draft only. Confirm first-person attribution and publication rights before posting.

## Post

Port 443 did not make this logging pipeline an HTTP service.

When I worked on centralizing logs from physical Ceph nodes, the destination was an existing Kubernetes logging platform. The challenge was to connect those environments without handing Elasticsearch credentials to storage hosts or disrupting the Kubernetes logs already using the collectors.

The path was:

Ceph files → Fluent Bit → HAProxy/Keepalived → ingress-nginx TLS passthrough → shared Fluentd → Elasticsearch → Kibana.

Fluent Bit handled local collection, parsing and buffering. The transport carried Fluent Forward inside TLS. HAProxy forwarded TCP, and ingress selected the backend using SNI. Fluentd terminated mTLS on a separate Ceph listener behind a ClusterIP Service.

That distinction mattered during debugging. An ordinary HTTP Ingress route could not interpret the Forward payload. A healthy Service endpoint also did not prove that Fluentd was actually listening on the expected port.

I kept Ceph events in one data stream and used fields such as host, daemon and dataset to make them searchable. Kubernetes retained its existing output path, although both pipelines still shared collector resources.

My main lesson: draw the protocol and trust boundaries before tuning the pipeline. Then validate each boundary with the right test: socket, TLS, application canary and destination search.

One maintenance caveat for anyone reusing the design today: community ingress-nginx has retired. I would review a maintained transport implementation before a new deployment.

How do you document protocol boundaries when storage, networking and platform teams own different parts of the same path?

\#Ceph #Kubernetes #DevOps #Observability

## Editorial notes

- **Suggested headline:** From physical Ceph nodes to a shared logging platform
- **Alternative hook:** The hardest part of centralizing Ceph logs was defining where each protocol ended.
- **Visual:** A simplified architecture diagram labeling Forward/TLS, SNI passthrough, Fluentd termination and the separate ES connection. Use [architecture.mmd](../diagrams/architecture.mmd); no infrastructure addresses.
- **GitHub reference, only after public approval:** Link the approved public repository's README and `docs/architecture.md`. Do not add a private URL to the published post.
- **Source support:** Runbook §§1–3, 13–17 describe the physical-node path, shared collectors, separate port/ClusterIP, passthrough, one data stream and listener troubleshooting. No new capacity or availability claim is made.
- **Current-context support:** [Kubernetes retirement notice](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). Migration is a recommendation, not a completed project result.
