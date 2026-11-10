# Installation and staged rollout

[Home](../README.md) · [Prerequisites](prerequisites.md) · [Configuration catalog](configuration.md) · [Rollback](rollback.md)

**EXAMPLE procedure.** Commands in this document change infrastructure when an operator runs them. None were executed against a live cluster for this project. Complete the target-version, security and change gates first. Work through the owning GitOps repository; do not use the illustrative fragments as a replacement deployment.

## 1. Establish the receiver before enabling sources

Export the active Fluentd CR, global config, relevant inputs/filters/outputs, Service, Ingress, StatefulSet and PVC inventory into restricted change storage. Do not export Secrets or generated credentials into this repository. Confirm selectors and namespace scope with `kubectl api-resources` and `kubectl explain`.

1. Have PKI issue the Fluentd server certificate for `logs.example.com` and one correctly named client Certificate per host. The issuer example is `vault-issuer`; its policy is not supplied.
2. Mount the server pair at `/fluentd/ceph-tls/` and approved client trust bundle at `/fluentd/ceph-client-ca/ca.crt`. Test process UID/GID readability. The historical mount fragment uses one client Secret's `ca.crt`; a separately controlled CA bundle is recommended.
3. Add the [ClusterInput example](../configs/fluentd/cluster-input.example.yaml) through the installed Operator schema, preserving existing Kubernetes input 24224.
4. Include the Ceph output before the catchall; verify the dedicated match covers `ceph.ops ceph.audit`. Obtain the missing complete production ClusterOutput instead of inventing its credentials, plugin fields or buffer settings.
5. Exclude `ceph.*` from **each** existing Kubernetes-only filter. Preserve its Ruby expressions. Validate the actual generated config in all replicas.
6. Wire the [Service](../configs/fluentd/service.example.yaml) to verified pod labels. Inspect EndpointSlices and the actual pod-local listening socket separately.
7. Reconcile the unique SNI route and TCP forwarding. Preserve the existing HAProxy shared frontend; run its config check before a site-approved reload. Validate a maintained ingress design before a new deployment.

Read-only checks, with names adapted to the target:

```bash
kubectl get clusterfluentdconfig fluentd-config -o yaml
kubectl get clusterinputs.fluentd.fluent.io ceph-forward-input --show-labels
kubectl get clusteroutputs.fluentd.fluent.io a-ceph-es-output --show-labels
kubectl -n fluentd get pods --show-labels
kubectl -n fluentd get endpointslice -l kubernetes.io/service-name=fluentd-ceph
kubectl -n fluentd exec fluentd-0 -- ruby -rsocket -e \
  'Socket.tcp("127.0.0.1",24225,connect_timeout:2) { puts "LISTEN OK" }'
```

Repeat the listener and mount checks on every selected pod. “Valid” CR status and a ready pod are insufficient. Review generated config privately because it may include output credentials.

## 2. Inspect sources and install the tested package

```bash
sudo dnf repolist
sudo dnf list fluent-bit --showduplicates
# Install the exact approved RPM version from the approved repository/bundle.
rpm -q fluent-bit
/usr/bin/fluent-bit --version
systemctl status fluent-bit --no-pager
systemctl list-units 'ceph-*.service' --all
find /var/log/ceph -maxdepth 2 -type f -name '*.log' -printf '%p %s bytes\n'
cat /etc/logrotate.d/cephadm
```

The historical package was 2.2.2 at `/usr/bin/fluent-bit`, not `/opt/fluent-bit/`. That version is preserved for evidence; selecting a secure supported target and testing migration is a prerequisite. Do not start the generic package service if it duplicates this collector, or disable an unrelated service without identifying its owner.

Record large files and byte-growth rates. Do not enable historical backfill by changing `Read_from_Head` casually. A daemon may log to journald and have no current file; discovery is required.

## 3. Provision the reader and state

```bash
getent group ceph-logreader >/dev/null || sudo groupadd --system ceph-logreader
id ceph-logreader >/dev/null 2>&1 || sudo useradd --system \
  --gid ceph-logreader --home-dir /var/lib/fluent-bit-ceph \
  --shell /sbin/nologin ceph-logreader
sudo install -d -m 0750 -o ceph-logreader -g ceph-logreader \
  /var/lib/fluent-bit-ceph /var/lib/fluent-bit-ceph/storage
sudo install -d -m 0750 -o root -g ceph-logreader /etc/fluent-bit/certs
```

Set `CEPH_FSID` to the verified target UUID; validate it and inspect **all** path components before changing ACLs:

```bash
CEPH_FSID='<CEPH_FSID>'
[[ "$CEPH_FSID" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]] || exit 1
test -d "/var/log/ceph/$CEPH_FSID" || exit 1
namei -l "/var/log/ceph/$CEPH_FSID/ceph.log"
getfacl -p /var/log/ceph "/var/log/ceph/$CEPH_FSID"
```

Capture existing directory **and file** ACLs in restricted backup storage before mutation. For example, run as an authorized administrator with `umask 077`; use `sudo tee` for root-owned redirection rather than assuming `sudo getfacl > /root/...` elevates the shell redirect.

```bash
umask 077
sudo getfacl -R -p "/var/log/ceph/$CEPH_FSID" | \
  sudo tee /root/ceph-log-acl-before.txt >/dev/null
sudo setfacl -m u:ceph-logreader:r-x "/var/log/ceph/$CEPH_FSID"
sudo setfacl -d -m u:ceph-logreader:r-x "/var/log/ceph/$CEPH_FSID"
sudo find "/var/log/ceph/$CEPH_FSID" -maxdepth 1 -type f -name '*.log' \
  -exec setfacl -m u:ceph-logreader:r-- {} +
```

Inspect ACL masks after `setfacl`: mask recalculation can alter other named/group entries' effective rights. Grant parent traversal only where needed. `/var/log/ceph` also needs enumeration for globbed discovery; test effective access. Handle top-level `cephadm.log` separately, including its rotation policy. Default ACL inheritance is subject to create modes, ACL masks and logrotate behavior.

Run [host-preflight.sh](../scripts/diagnostics/host-preflight.sh) as an authorized administrator. It checks access as the reader, not root. A named user ACL of `--x` is insufficient for wildcard enumeration and can override apparent supplementary-group access. Prefer narrow ACLs to membership in a Ceph group with write rights. Enforcing SELinux may require reviewed labels/policy; the permissive pilot is not justification to disable it.

## 4. Stage configuration and credentials

Create `/etc/fluent-bit/ceph.env` from the [template](../examples/environment/ceph.env.example), using the verified UUID and this host's short name. Use root ownership and mode 0644; there are no credentials in this file. Avoid hidden CR characters and never copy another host's environment or state.

Run these install commands from the repository root **only after** preparing the approved target configuration:

```bash
sudo install -o root -g ceph-logreader -m 0640 \
  configs/fluent-bit/ceph.conf /etc/fluent-bit/ceph.conf
sudo install -o root -g ceph-logreader -m 0640 \
  configs/fluent-bit/ceph-parsers.conf /etc/fluent-bit/ceph-parsers.conf
sudo install -o root -g root -m 0644 \
  configs/fluent-bit/fluent-bit-ceph.service /etc/systemd/system/fluent-bit-ceph.service
```

`logs.example.com` must be replaced consistently in Host, SNI, server SAN and ingress rules. Retain DB paths/input order for continuity. The snapshot's `environment production` is historical metadata, not evidence this example is deployed; change it explicitly for a lab. Document all deviations from the sanitized snapshot.

Use secure secret deployment to install this host's leaf plus intermediate chain and matching private key, and the independently approved server CA bundle, at the paths referenced by the snapshot. Set `root:ceph-logreader`, mode 0640, parent 0750. Do not put actual certificate/key files in this repository. See [certificate lifecycle](certificate-lifecycle.md) for controlled export, pairing and transfer.

The [systemd unit](../configs/fluent-bit/fluent-bit-ceph.service) is an observed-pattern example, not an exact unit export. Review `CPUQuota=200%`, `MemoryMax=256M`, idle IO scheduling and `ReadWritePaths` against target systemd/kernel behavior. Memory limits may cause OOM during bursts; low IO priority is not a guarantee of zero Ceph impact.

```bash
sudo systemctl daemon-reload
sudo systemctl show fluent-bit-ceph -p User -p Group -p EnvironmentFiles \
  -p MemoryMax -p ReadOnlyPaths -p ReadWritePaths
sudo sed -n 'l' /etc/fluent-bit/ceph.env
sha256sum /etc/fluent-bit/ceph.conf /etc/fluent-bit/ceph-parsers.conf
```

## 5. Validate offline and run a unique canary

Use [agent-config-check.sh](../scripts/validation/agent-config-check.sh) to pass validated environment values explicitly to a dry run under the service identity. An arbitrary environment file must not be sourced as root shell code. Syntax success does not prove file-tail behavior, TLS, parser outcomes or delivery.

Run local key/chain checks, then [check-mtls.sh](../scripts/diagnostics/check-mtls.sh) with explicitly supplied target and certificate paths. A no-client negative test and a wrong-server-name test belong in the controlled lab. Preserve hostname verification; do not use `tls.verify Off`.

Adapt [ceph-canary.conf.example](../configs/fluent-bit/ceph-canary.conf.example): unique marker, correct host identity, endpoint and credentials. It has no production offset DB or chunk directory and must not be combined with a second production Tail process. Install the canary file mode 0640 and run:

```bash
sudo runuser -u ceph-logreader -- /usr/bin/fluent-bit --dry-run \
  -c /etc/fluent-bit/ceph-canary.conf
sudo timeout 15s runuser -u ceph-logreader -- /usr/bin/fluent-bit \
  -c /etc/fluent-bit/ceph-canary.conf
```

Timeout exit 124 is a harness timeout, not delivery evidence. Query the exact marker in Elasticsearch. Confirm normal Kubernetes documents still arrive. A canary can itself duplicate after an ambiguous ACK; search by its unique marker and inspect counts.

## 6. One-host activation and expansion

Start with a deliberately narrowed, reviewed low-volume source pattern in a separate deployment revision, or delay starting the full snapshot until capacity is approved. Do not silently modify the preserved snapshot. Start only `fluent-bit-ceph`; never restart Ceph daemons to test collection.

```bash
sudo systemctl start fluent-bit-ceph
systemctl is-active fluent-bit-ceph
sudo journalctl -u fluent-bit-ceph -n 100 --no-pager
curl -fsS http://127.0.0.1:2020/api/v1/metrics
```

Observe Ceph CPU/IO/latency, both log destinations, receiver CPU/memory/queues, Elasticsearch rejects and local disk. If Kubernetes freshness degrades, stop the newly enabled agent and preserve state. Expand patterns, then hosts, one at a time. Enable at boot only after the [acceptance checklist](validation.md) passes through representative workload and rotation:

```bash
sudo systemctl enable fluent-bit-ceph
```

For each host record version, config hashes, FSID verification, source inventory, ACL results, client identity/expiry, unique canary, destination evidence, performance observation and rollback checkpoint internally. Do not publish that inventory.
