# Certificate issuance, trust and rotation

[Home](../README.md) · [Security](security.md) · [Rollback](rollback.md)

## Artifact roles

| Artifact | Role and location |
|---|---|
| Fluentd server leaf plus intermediates | `/fluentd/ceph-tls/tls.crt`; SAN must match the client endpoint |
| Fluentd server private key | `/fluentd/ceph-tls/tls.key`; never distributed to source hosts |
| Client issuing CA trust | `/fluentd/ceph-client-ca/ca.crt`; public trust material, not a client allowlist |
| Per-host client leaf plus intermediates | `/etc/fluent-bit/certs/client-fullchain.crt` |
| Per-host client private key | `/etc/fluent-bit/certs/client.key`; never copied between hosts |
| Server CA trust bundle | `/etc/fluent-bit/certs/server-ca.crt`; independently approved trust anchors |

The [client Certificate example](../configs/cert-manager/client.example.yaml) requests 2160h duration, renewal 360h before expiry, `client auth`, and `rotationPolicy: Always`. These are requests; Vault policy and actual issued validity decide the resulting dates. The server example requests `server auth`. Discover the existing Certificate object name before editing; the Secret name and Certificate name are not interchangeable.

An issuer error saying the requested common name is not allowed is a policy rejection. Correct the allowed identity with PKI owners, not by broadening all issuance or bypassing Vault. The source described a copy/paste client CN error; audit object name, Secret, SAN/CN, deployed host and certificate together.

## Secure export and distribution

An authorized deployment system may read only the required client Secret and distribute to the matching physical node. Example for a restricted workstation, outside this repository:

```bash
set -euo pipefail
umask 077
SECRET=fluentbit-ceph-node-02-tls
STAGE=$(mktemp -d)
kubectl -n fluentd get secret "$SECRET" -o jsonpath='{.data.tls\.crt}' \
  | base64 -d > "$STAGE/client-fullchain.crt"
kubectl -n fluentd get secret "$SECRET" -o jsonpath='{.data.tls\.key}' \
  | base64 -d > "$STAGE/client.key"
```

Do not enable shell tracing or print key bytes. Use an approved secure transfer/secret-management workflow, inspect staging permissions, and remove transient material after verified installation and approved encrypted backup. The staging commands alone do not implement distribution or cleanup.

`tls.crt` normally carries the leaf and available intermediate chain; do not confuse it with a CA bundle. Treat root trust distribution as its own lifecycle. cert-manager cautions against relying on the leaf Secret's `ca.crt` for application trust distribution. [Certificate and trust guidance](https://cert-manager.io/docs/usage/certificate/)

## Local certificate checks

```bash
openssl x509 -in client-fullchain.crt -noout -subject -issuer -serial -dates \
  -ext extendedKeyUsage,subjectAltName
openssl x509 -in client-fullchain.crt -pubkey -noout \
  | openssl pkey -pubin -outform DER | sha256sum
openssl pkey -in client.key -pubout -outform DER | sha256sum
openssl verify -purpose sslclient -CAfile trusted-client-root.crt \
  -untrusted intermediate.crt client-leaf.crt
```

Public-key hashes must match. The verification command supplies intermediates as untrusted chain-building material and roots as trust anchors. An error at depth zero about a missing local issuer may indicate a missing intermediate, not an invalid leaf. `unknown ca` from the peer means that peer rejected a chain; inspect the correct direction's trust bundle.

Check your OpenSSL version's `s_client` chain options. Supplying a multi-certificate file to `-cert` must not be assumed to transmit all intermediates. The repository's [TLS probe](../scripts/diagnostics/check-mtls.sh) takes leaf and intermediate files separately and uses `-cert_chain` on supported OpenSSL builds. This improves the source's diagnostic command without changing the historical Fluent Bit snapshot. Confirm the Fluent Bit backend sends the intended chain using controlled receiver diagnostics.

## Rotation procedure

1. Check Certificate Ready status, actual expiry and renewal time; verify the installed host certificate separately.
2. Export the new pair for exactly one host through the approved deployment path. Verify identity, chain, EKU and public-key match.
3. Store the previous valid pair only in approved encrypted rollback storage. Do not retain a compromised key as a rollback candidate.
4. Stage new files root-only. Two independent file renames are not one atomic transaction: stop the agent during pair replacement, or use a tested versioned-directory switch and reload process.
5. Install restrictive ownership/modes, verify as the service identity, restart only the collector, then establish a new TLS connection and unique canary.
6. Confirm both Ceph and Kubernetes freshness, record fingerprint/expiry internally, clean temporary material, then proceed to the next host.

cert-manager renews Kubernetes Secrets; it does not deploy to physical hosts. A projected server Secret may update while Fluentd continues serving the old in-memory certificate. Verify plugin reload behavior. If a restart is needed, roll one collector pod at a time through its owner, preserving persistent buffers and monitoring both streams. Do not assert uninterrupted service without a test.

## Expiry, CA changes and revocation

```bash
openssl x509 -in /etc/fluent-bit/certs/client-fullchain.crt -checkend 1296000 -noout
```

This checks whether the certificate will expire within 15 days; it does not perform full chain or not-before validation. Use 604800 for seven days. Monitor file identity and dates on the host, not merely a renewed Secret.

Existing TLS connections may survive a leaf expiry until reconnect. A new handshake revalidates credentials, so intermittent reconnect failures can precede complete delivery loss. Ceph daemons are not stopped by a log-client certificate expiring.

For a new CA, distribute overlapping old/new trust first, then reissue and deploy leaves, verify every client/server path, and retire old trust only after the migration is complete. Root or intermediate compromise needs coordinated incident response. Deleting a Secret or issuing a replacement leaf does not revoke an exported old certificate. Verify actual CRL/OCSP enforcement; it is not shown in the supplied configuration.
