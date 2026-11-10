# Day-2 operations and recovery

[Home](../README.md) · [Certificates](certificate-lifecycle.md) · [Rollback](rollback.md)

## Daily and weekly routines

Daily, verify intended agents are active without crash loops; free disk and buffered-byte trends are safe; receiver listeners and mounts are present; and **new** Ceph and Kubernetes events are searchable. Check writer authorization/mapping failures, TLS errors and installed-certificate expiry. Review unusual RGW/audit fields under the access policy.

Weekly, compare active config hashes with the approved revision, test a real log rotation's new-file permissions, inspect per-host/source/dataset rates, review parse-status changes and correlate slow flush with queues, CPU and ES write rejects. Reconcile cert-manager Secret renewal with actual host deployment. A fixed schedule does not substitute for alerts.

Local retention, Tail/queue survival time, receiver buffer capacity and Elasticsearch lifecycle retention are independent. The source reported daily rotation, seven rotations, compression, shared postrotate signaling, missing/empty handling and root rotation ownership. Reconfirm target policy. The Tail patterns do not ingest compressed archives. Audit retention needs an explicit end-to-end design, not reliance on a 4G queue.

## Upgrade control

| Change | Before | Canary and rollback |
|---|---|---|
| Fluent Bit | Record exact RPM/config/state format; review TLS/parser/storage changes | One host, target-binary dry run, synthetic fixtures, wrong-name TLS test, canary and backlog restart; downgrade state only with verified format compatibility |
| Operator/Fluentd | Export CRDs, owner manifests, plugin inventory, selectors, mounts and private generated config | Controlled pod roll, every listener and match, persistent-buffer continuity and both streams; revert owning revision |
| Transport | Preserve route identity and client-auth boundary; inventory current exposure | New TLS session and Forward canary through each hop; site-approved route rollback |
| Elasticsearch | Export templates, roles, lifecycle, shard inventory; take approved backups | Test writer startup/bulk/mapping and rollover; revert future-index template safely without deleting data |

Do not combine Operator upgrade, filter changes, output tuning and mappings into an untraceable rollout. Retired ingress-nginx requires a migration plan; this repository has no verified replacement implementation.

## Elasticsearch unavailable or rejecting writes

1. Identify authentication, mappings, capacity or network failure from receiver output logs and destination health.
2. Preserve all DBs, chunks, PVCs and existing streams. Pause the newest Ceph input if Kubernetes delivery is affected; track how long local rotation will retain unread source data.
3. Repair the destination without disabling security. Observe each output's pending and in-flight work.
4. Resume one host and permit measured draining. Output capacity must exceed ongoing input to reduce backlog.
5. Verify current records in both streams, duplicates and any irreversible loss from eviction, rotation or corruption. Document gaps; do not claim full recovery without reconciliation.

## Host reboot or collector replacement

After a host reboot, verify FSID/environment, credential readability, installed expiry, ACLs on recreated files and persistent state. Check automatic startup only if previously enabled after acceptance. Recover queued chunks and saved offsets using the same ownership/paths; investigate unexpected backfill before increasing rate.

For a Fluentd pod replacement, verify its restored volume, Secret mounts, selected configuration, listener and Service labels. A fresh empty buffer volume is not recovery of the prior queued data. Do not delete a PVC to force readiness. Confirm volume snapshots/restores with the storage owner.

## Disaster recovery boundary

Maintain the configuration source, secure credentials/trust backup, host state snapshot procedure, receiver PVC backup procedure and Elasticsearch snapshot/restore policy internally. None of those backup systems is implemented by this repository. Rehearse restore in a lab with matching versions and isolated destinations; never run two consumers against the same live state.

If host state is lost, preserved source files may permit a deliberate isolated backfill, with duplicates and finite retention constraints. If receiver state is lost after ACK, source retries may not recover those events. ES replica count is not a backup. No recovery point or recovery time objective has been validated.

Where the buffer storage depends on Ceph itself, plan for correlated storage/observability failure and retain a separate troubleshooting path. The source's earlier RBD claim makes this worth checking but does not prove the current storage topology.
