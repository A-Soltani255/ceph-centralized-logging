# Rollback and safe recovery

[Home](../README.md) · [Operations](operations.md) · [Troubleshooting](troubleshooting.md)

## Immediate overload response

When activating a Ceph host causes Kubernetes delivery to lag, stop **that collector**:

```bash
sudo systemctl stop fluent-bit-ceph
```

Ceph daemons keep running. Preserve offsets/chunks and observe whether shared CPU, queues and freshness recover. Stopping agents does not discard already accepted receiver work and does not extend source log retention. Track the pause window.

Keep the Ceph output available to drain accepted chunks unless an incident-specific plan requires otherwise. Removing a match/output can strand chunks or route records into the catchall. A historical temporary output disable restored Kubernetes flow, but the durable fix was destination authorization and routing/capacity work; it is not a universal recovery command.

## Configuration rollback

Stop the agent. Restore the approved paired main/parser revision and this host's matching environment and unit, retaining existing DB/chunk paths. Restore ownership/modes; daemon-reload only if the unit changed. Run the service-user config check and certificate validation, then start one agent, canary and observe both streams. Do not blindly downgrade across incompatible state formats.

For Operator/filter/output/Ingress changes, revert the precise owning Git revision and reconcile through Argo CD/Helm/Operator. Inspect actual generated routing and mounts on every pod; verify listeners and both output paths. Editing `/fluentd/etc/app.conf` in a pod is not durable rollback. Avoid deleting an existing shared ingress to solve a duplicate without checking ownership.

## ACL rollback

Restore a trusted, pre-change `getfacl` snapshot with the approved ACL restore procedure. Confirm path scope and current owner changes before using `setfacl --restore`. A directory-only snapshot cannot restore file ACL modifications. Re-test enumeration and read under `ceph-logreader`, including newly rotated files. Reverting access may intentionally stop ingestion; coordinate that consequence with Storage.

## Certificate rollback

Restore the previous **matched pair** only if still valid, trusted and uncompromised. Stop the process during pair replacement, verify identity/key match and restart only the agent. Never restore an expired or revoked pair to recover connectivity. For a bad new issuer chain, repair trust/issuance through PKI; trust-anchor rollback is coordinated and may need overlap on both sides.

## Corrupt or exhausted state

Stop the affected collector, capture a consistent restricted copy of DB/WAL/SHM and chunk files, record versions and filesystem health, then distinguish corruption from access failure. Use an incident-specific restore plan. Never delete `/var/lib/fluent-bit-ceph`, receiver PVCs or ES streams as a first repair. Lost queues and reset offsets can cause both gaps and replay storms.

## Recovery acceptance and lab faults

Verify a new unique canary, fresh natural source events and continuing Kubernetes freshness, stable queues, no crash loop, and expected permissions/identity. Record unresolved loss windows and duplicate risk. Test unavailable ES, denied writer, stale certificate, unavailable worker, ACL failure and backlog restart only in an isolated environment with explicit traffic and disk bounds. Do not fill production volumes, revoke a production CA or stop all shared collectors to demonstrate resilience.
