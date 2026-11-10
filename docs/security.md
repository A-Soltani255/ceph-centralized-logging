# Security architecture and review

[Home](../README.md) · [Certificate lifecycle](certificate-lifecycle.md) · [Publication review](publication-review.md)

## Trust boundaries

Ceph readers need file read access, private local state and client TLS credentials. They do not need Elasticsearch credentials or privileged access to Ceph administration. HAProxy and the legacy ingress passthrough path carry ciphertext. Fluentd holds the inbound TLS server key, client trust bundle and separate Elasticsearch credentials. PKI issuance, Kubernetes Secret access, host deployment and search access are distinct privileges.

The inbound TLS session does **not** extend through Fluentd to Elasticsearch. Export and inspect the real output privately to establish HTTPS, certificate validation, server identity checks and authentication. Those output fields are missing from the evidence; encryption of the first hop cannot establish security of the second.

## Findings and controls

| Priority | Finding | Evidence / required action |
|---|---|---|
| Deployment blocker for new use | Retired ingress-nginx dependency | Preserve history; choose and test maintained TCP/TLS transport, including mTLS boundary and rollback |
| High | Agent hostname enforcement unresolved | 2.2.2 rejected `tls.verify_hostname`; SNI and a successful OpenSSL test do not prove agent hostname verification. Test a trusted wrong-name server in a lab, inspect exact TLS backend/build, and use a supported verified implementation |
| High | CA trust wider than an exact node allowlist | Any accepted certificate under the trusted issuance boundary may authenticate. Constrain PKI issuance and validate an identity authorization control if exact membership is required |
| High | Shared collector can delay Kubernetes logs | Scope filters, restrict source/network access, cap resources, monitor both streams, and stage rollout; consider isolation after measurement |
| High | Renewal does not deploy host credentials | Monitor installed host certificates and automate controlled pair replacement; Secret Ready status is insufficient |
| High | RGW/audit data can contain sensitive payloads | Restrict query access and retention; review redaction before collection. Renaming fields is not redaction |
| Medium | CA trust sourced from one leaf Secret | Historical mount is preserved as an example; independently manage public trust anchors and overlap during CA rotation |
| Medium | Pilot used broad Ceph group access and permissive SELinux | Prefer narrow effective ACLs; validate enforcing policy rather than copying permissive settings |
| Medium | Local state and diagnostics contain operational data | Restrict permissions, encrypted backups where required, secure incident storage and approved retention |
| Unverified | Revocation and recipient identity binding | CRL/OCSP/fingerprint/SAN authorization not proven by supplied configuration |
| Unverified | ES role, output TLS, ingress/host firewall and NetworkPolicy | Obtain current private exports and test minimum permissions and allowed network paths |

These are design/evidence findings, not a penetration test or a claim that a live system remains vulnerable today.

## mTLS mechanics

Fluent Bit supplies SNI, trusts the Fluentd server CA and presents its own leaf/chain with proof of private-key possession. Fluentd requests and validates client certificates against its CA bundle. Confirm validity, chain, intended usage and identities independently. The exact enforcement of EKU, hostname and revocation must be tested on the deployed TLS stack.

The historical `tls.vhost` setting is documented as SNI, while the 2.2 transport options list `tls.verify` for certificate validation. This is insufficient evidence for a hostname guarantee. [Fluent Bit 2.2 transport security](https://docs.fluentbit.io/manual/2.2/administration/transport-security)

A client-supplied `ceph_host` or tag is not cryptographically bound to its certificate by this configuration. A trusted but compromised client could claim another host field or send unexpected tags toward the shared runtime. Consider a dedicated receiver/routing boundary with enforced accepted tags and authenticated identity enrichment. No such enforcement is claimed deployed here. Negative-lookahead filtering is an optimization, not an authorization rule.

## Least-privilege host access

Use named ACLs granting directory enumeration/traversal and file read. Inspect effective masks and all parents. The agent needs write access only to its own state directory, not Ceph logs or data. Broad recursive chmod, root execution and adding the reader to a privileged group are inappropriate repairs.

The service example uses `NoNewPrivileges`, `ProtectHome`, `ProtectSystem=strict`, explicit read-only log paths and a state write path. These reduce exposure but do not replace SELinux, host policy or verification on the target systemd release. Keep metrics loopback-only. Restrict client private-key readability to root and the service group; a compromised collector can still read its own key and sensitive logs.

## Network and destination access

Limit source egress and ingress admission to the intended path. Protect backend 24225 from unrelated workloads with tested network controls where possible. A ClusterIP is service addressing, not a complete network security boundary. Keep metrics accessible only to intended scrapers. Restrict Kubernetes Secret RBAC to operational need and prevent debug/CI systems from collecting secret-bearing configuration.

Provision Elasticsearch templates/retention using a separate administrative identity where supported. Test the writer's actual startup and bulk actions. `create_doc` and `view_index_metadata` are candidates for a pre-created stream, not a proven complete role for an unknown plugin version. Avoid cluster-wide `all` as a 403 workaround. [Elasticsearch privileges](https://www.elastic.co/docs/reference/elasticsearch/security-privileges)

## Security acceptance

In an isolated environment verify rejection of no-client, untrusted-client, wrong-server-name and invalid/expired certificate cases, using controlled test certificates. Include an unauthorized-but-same-CA client to expose the difference between trust and membership. Do not revoke production identities or disable security to create a test. Verify that sensitive records, credentials and real topology remain absent from repository history before any external push.
