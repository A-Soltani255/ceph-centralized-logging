# Post 4 draft — Buffers buy time, not a delivery guarantee

**Review status:** Draft only. Confirm first-person attribution and publication rights before posting.

## Post

A persistent buffer is useful. An unmonitored persistent buffer is an outage waiting for a deadline.

In the Ceph logging work, I used filesystem-backed Fluent Bit chunks and separate SQLite offset databases for the input families. Those mechanisms supported restart continuity, but they solved different problems: where to resume reading and what still needed forwarding.

The configuration also had explicit limits. The output queue was bounded, oversized lines could be skipped, and local log rotation continued whether the destination was healthy or not.

Forward acknowledgments introduced another boundary. They supported retry, but an ambiguous acknowledgment could produce duplicates. An ACK from Fluentd was not proof that Elasticsearch had indexed the record.

That changed how I approached rollout and recovery:

- Start with a unique canary, then one host and a controlled source scope.
- Watch both Ceph and Kubernetes freshness, alongside CPU, disk, queue growth and destination errors.
- Test file access after rotation under the collector's actual identity.
- If the new traffic disrupts shared logging, stop that source agent and preserve its state.
- Resume gradually after repair; backlog drain competes with new input.

I also kept rollback focused on the collector and its owning configuration. Deleting offsets or receiver volumes could turn a recoverable incident into lost records, replay storms or both.

The lesson was to state the delivery limits clearly and rehearse recovery around them. Persistent storage improves the options; it does not establish zero loss or a guaranteed recovery time.

Which signal gives your team the earliest warning that a logging backlog is consuming its remaining recovery window?

\#ReliabilityEngineering #SRE #Ceph #Observability

## Editorial notes

- **Suggested headline:** Buffers buy time, not a delivery guarantee
- **Alternative hook:** The most useful logging guarantee was the one we refused to overstate.
- **Visual:** Two distinct state boxes, “Tail offsets” and “queued chunks,” followed by Forward ACK and ES indexing as separate milestones. Show finite capacity and rotation deadlines without invented throughput curves.
- **GitHub reference, only after public approval:** Link `docs/performance.md`, `docs/operations.md` and `docs/rollback.md` in the approved public repository.
- **Source support:** §§4, 6, 12, 17–19 and 21–23 plus appendix A support persistent state, ACKs, 4G/2M limits, rotation, staged rollout and non-destructive rollback. Recovery tests are described as practices and required gates, not a fabricated completed fault-injection campaign.
