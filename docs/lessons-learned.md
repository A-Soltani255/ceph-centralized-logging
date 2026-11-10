# Engineering lessons

[Home](../README.md) · [Incident detail](troubleshooting.md) · [LinkedIn drafts](../linkedin/publishing-guide.md)

## Access must match how a program reads

A file readable by its exact name does not prove a wildcard Tail input can enumerate the directory. The source's named `--x` ACL explained why adding supplementary group membership failed to solve glob scanning. Test the real service identity and effective ACLs, then test again after rotation.

## Protocol boundaries deserve their own diagram

443 is a port, not a protocol. Fluent Forward remained inside TLS across HAProxy and SNI ingress, terminating at Fluentd. Debugging the receiver's local socket before the VIP prevented routing and certificate changes from obscuring the actual failure. The retired ingress implementation is history to learn from; a maintained replacement still has to preserve that boundary deliberately.

## One stream can affect another before routing

Separate destinations do not isolate a shared process. Generic Ruby filters processed Ceph records even though they existed for Kubernetes metadata. Restricting filter scope addressed unnecessary work, while writer authorization and destination health needed their own fixes. The source does not establish a numerical before/after improvement.

## Credentials have deployment lifecycles

cert-manager issuance is only one step. Physical hosts retain old files until a deployment mechanism replaces them. Trust anchors, leaf/key pairing, identity correctness, process reload and new-handshake validation all need owners. Same-CA trust does not establish exact host membership.

## Persistent does not mean infinite or lossless

Offsets and chunks protect different parts of delivery. A 4G cap, 2M line limit, rotation and normal sync policy all impose limits. ACK retries can duplicate, and an ACK is not an ES commit. Recovery needs reconciliation and a documented loss policy, not optimistic language.

## Observe the service users care about

Pod readiness, EndpointSlices, TLS success and a green metrics target each answer a narrower question than “are logs searchable now?” Acceptance must include new records from both Ceph and Kubernetes during normal and burst load. Metrics without type, unit and timestamp context can mislead as easily as missing logs.

## Preserve evidence boundaries

Keep snapshots, examples and recommendations visibly separate. Missing role JSON, operator CRs and HAProxy policy should remain explicit gaps. A professional project is more useful when it states what has not been verified than when it fills the gaps with plausible-looking production manifests.
