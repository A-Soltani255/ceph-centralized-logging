# Prerequisites and change readiness

[Home](../README.md) · [Installation](installation.md) · [Validation](validation.md)

This project does not install a Ceph cluster, Kubernetes, Elasticsearch, PKI, or a maintained ingress replacement. It integrates with existing managed services. Example manifests have unresolved environment dependencies and must not be applied as a directory.

## Ownership and target inventory

Assign Storage to Ceph logging/rotation, Platform to host agents and Kubernetes, Network to VIP/transport, PKI to issuance/trust, and Observability to Fluentd/Elasticsearch. Record on-call and rollback owners internally. Verify source publication rights separately from infrastructure change authority.

On authorized systems, use these read-only discovery commands; they were not executed for this documentation project:

```bash
cephadm shell -- ceph -s
cephadm shell -- ceph fsid
cephadm shell -- ceph versions
cephadm shell -- ceph orch host ls
cephadm shell -- ceph orch ps --refresh
rpm -q fluent-bit
/usr/bin/fluent-bit --version
systemctl cat fluent-bit-ceph
systemctl list-unit-files 'fluent-bit*'
podman ps --format '{{.Names}} {{.Image}} {{.Status}}'
kubectl api-resources --api-group=fluentd.fluent.io
kubectl -n fluentd get pods,svc,ingress,pvc
kubectl -n ingress-nginx get deploy,svc
kubectl get clusterissuer vault-issuer
```

ClusterInput/ClusterFilter/ClusterOutput are cluster-scoped in the example API. A namespace flag does not scope a cluster-scoped resource. Confirm installed CRDs, chart and runtime image/plugin versions. Capture Helm values and GitOps revision privately; exports and generated `app.conf` may contain credentials.

## Per-host requirements

| Requirement | Gate |
|---|---|
| RHEL-family RPM host | Approved package source, tested version and dependencies; offline installs need a complete bundle |
| Exact FSID | Obtain from the target cluster; validate UUID and matching directory; never choose the first directory on a multi-cluster host |
| Reader identity | Dedicated non-root user/group; directory enumeration and file read tested under that identity |
| Local state | Persistent private directory, capacity beyond the logical 4G queue plus DB/WAL and host logs |
| Resources | CPU/memory/IO baseline and Ceph health; no concurrent storage recovery change without coordination |
| Time and DNS | `timedatectl`, `chronyc tracking`, correct name resolution and TCP path |
| PKI | Distinct client key, correct SAN/CN/EKU, server trust bundle, host certificate deployment owner |
| Rotation | Existing logrotate policy exported; post-rotation access test planned |
| Existing agent | Avoid competing services or shared offset DBs |

## Receiver requirements

- Existing Fluentd/Kubernetes logging baseline with a freshness signal and capacity observation window.
- Operator selectors include the new input/output; each pod has readable server TLS and client-CA mounts.
- Fluentd listens on 24225 on every selected pod; EndpointSlices match labels and port.
- A unique SNI route, working TCP exposure and no competing bind on port 443.
- A maintained transport strategy: the legacy ingress-nginx manifest is for reproduction and migration review.
- Approved Elasticsearch data stream/template, TLS settings, restricted writer credentials and persistent output buffer.
- Installed CRD schemas available for validation; PVC backup/restore and retention policies defined.

## Change checkpoint

Back up current configs, environment, unit, ACLs and owning Git revision into an access-controlled internal location. Back up keys only through the approved encrypted secret backup system. Stop the agent before taking a consistent copy of the complete Tail DB/WAL/SHM and chunk state; never clone that state to another host. Record both Ceph and Kubernetes freshness before a canary.

Set explicit deployment thresholds from local measurements: acceptable Kubernetes log delay, Ceph host CPU/IO impact, free disk margin, queue trend, permitted drops, parse failure rate and rollback trigger. The source's suggested quiet observation period is not a proven service-level objective.
