# Post 3 draft — Why Ceph ingestion affected Kubernetes logs

**Review status:** Draft only. Confirm first-person attribution and publication rights before posting.

## Post

Ceph logs started arriving, but Kubernetes log delivery slowed. That was not a successful rollout.

I was adding storage-node traffic to a Fluentd deployment that already served Kubernetes. The streams had separate destination routing, but they shared collector processes and resources.

The investigation had two important threads.

First, the Ceph Elasticsearch output encountered a 403 on a data-stream metadata operation. A writer could be too restricted for the plugin's startup or inspection behavior even when the intended task sounded like “just write logs.” Fixing the required privileges needed a test with the actual writer identity, not an administrator's successful search.

Second, broad Kubernetes-oriented Ruby filters were also processing Ceph records. Those filters ran before the output split, so separate outputs did not avoid that work.

The corrective filter design excluded tags beginning with `ceph.` while preserving the existing Kubernetes expressions. I checked the generated configuration across the collector pods and kept the Ceph match ahead of the catchall.

The evidence also needed restraint. Slow flushes did not automatically prove Elasticsearch saturation. A near-empty queue did not prove spare capacity. And no measured before-and-after benchmark was available to turn the filter change into a percentage improvement.

The lesson I took away was practical: debug the shared processing path as well as the destination. Pause new source traffic when needed, preserve buffers, and verify freshness for both services before expanding rollout.

How do you test for impact on existing pipelines when introducing a new high-volume source?

\#Fluentd #SRE #Observability #Troubleshooting

## Editorial notes

- **Suggested headline:** Why Ceph ingestion affected Kubernetes logs
- **Alternative hook:** Separate output routes did not give our shared collectors resource isolation.
- **Visual:** Before/after processing diagram: broad Kubernetes filters seeing both streams versus scoped filters excluding Ceph. Label both as still sharing resources.
- **GitHub reference, only after public approval:** Link `docs/troubleshooting.md` and `docs/performance.md` in the approved public repository.
- **Source support:** §§13.8–13.10, 15.5, 19 and 20.10–20.11 support the 403 incident, broad-filter overhead, generated negative-lookahead configuration and sampled CPU/flush observations. The two failure modes are not presented as a single proven root cause for every delay.
