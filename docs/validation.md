# Validation: local checks and deployment acceptance

[Home](../README.md) · [Quality report](quality-report.md) · [Troubleshooting](troubleshooting.md)

## What local checks establish

Run from the repository root with Node.js 24 or newer:

```bash
npm ci --ignore-scripts
npm run check
npm run lint:markdown
npm run check:mermaid
git diff --check
```

The checker validates JSON/YAML parsing, duplicate YAML keys, relative documentation links/anchors, fenced-block balance, selected configuration references, independent Tail DB paths, parser references and extracted-content hashes. Its generic secret patterns are supplementary, not a substitute for Gitleaks or human review. It never sources host files, contacts a cluster or sends a canary.

For shell examples, from the repository root:

```bash
find scripts -name '*.sh' -print0 | xargs -0 -n1 bash -n
find scripts -name '*.sh' -print0 | xargs -0 shellcheck -x -P SCRIPTDIR
gitleaks git --redact --no-banner .
```

Use Gitleaks on a clean source-only export too; exclude dependency folders from that export rather than uploading/scanning them as project content. A private local comparison against the confidential source's known identifiers must happen outside Git so the denylist itself is not published.

Mermaid parse success is syntax validation, not a visual rendering check. Kubernetes schema checks validate only declared target schemas. Fragments are deliberately excluded from whole-resource checks. The live Kubernetes, cert-manager and Operator schemas remain authoritative for deployment. Never use `--ignore-missing-schemas` to report a fully validated custom resource.

Before target deployment, an authorized operator should validate complete rendered resources using the installed CRDs and server-side dry run in an appropriate test context. Admission webhooks can run even for dry-run requests, so this is not part of the default offline documentation checks. The workflow must never receive production kubeconfig, ES credentials or TLS keys.

## Script contracts

| Script | Purpose, prerequisites and exit behavior |
|---|---|
| `scripts/lib/host-env.sh` | Helper parses only two literal unquoted environment keys, rejects CR/unknown/duplicate keys, validates UUID and hostname; no `eval` or sourcing environment contents |
| `scripts/validation/agent-config-check.sh` | Authorized root on target Linux host; runuser and installed Fluent Bit; checks required files as reader and executes `--dry-run`; does not start service or check metrics |
| `scripts/diagnostics/host-preflight.sh` | Authorized root, Bash/ACL/OpenSSL/systemd tools; validates source glob access and state visibility; nonzero on missing prerequisite/access; output is confidential |
| `scripts/diagnostics/check-mtls.sh` | OpenSSL with explicit chain support and GNU timeout; explicit host/CA/leaf/key/intermediates; opens a bounded TLS 1.2 connection, no Forward event; timeout/failure is nonzero |
| `scripts/diagnostics/receiver-check.sh` | Explicit kubectl context, namespace and pods; read/exec privileges, Ruby in container; checks mounts/socket and EndpointSlices without printing Secret bytes or full `app.conf` |
| `scripts/validation/check-repository.mjs` | Local Node/YAML check; prints counts and failures, nonzero on failure |
| `scripts/validation/check-mermaid.mjs` | Local Mermaid parser with DOM shim; checks diagram equivalence and syntax, throws on failure |

The shell scripts are adapted examples, not exact copies of source appendix C. They do not change infrastructure configuration. `receiver-check.sh` executes read-only probes inside pods and the TLS script creates a network connection: run them only in an authorized context. No production diagnostic script was run during authoring.

## End-to-end acceptance gates

| Gate | Evidence needed |
|---|---|
| Host scope | Correct target FSID and host identity; intended daemons/source inventory |
| Reader | Non-root process, effective read-only ACLs and post-rotation access |
| Config | Approved binary/config hashes, no duplicate agent/state sharing, service-user dry run |
| PKI | Correct installed SAN/CN/EKU, valid dates, matching key, complete chain and trust direction |
| Identity policy | Target agent rejects a trusted wrong-name server; unauthorized-client policy tested, not inferred from SNI |
| Receiver | Every selected pod mounts TLS material and listens on 24225; selectors and EndpointSlices agree |
| Transport | Correct TCP path and unique SNI route; no unintended termination; new TLS connection through full path |
| Output | Exact tag match before catchall, Kubernetes-only filters scoped correctly, same writer identity authorized |
| Delivery | Unique canary and new natural Ceph events indexed with correct time/host, alongside new Kubernetes logs |
| Load | Approved CPU/IO/memory/disk margins and stable queues during representative normal/burst conditions |
| Lifecycle | Controlled client/server renewal, rotation and agent restart demonstrated in a pilot |
| Recovery | Safe stop/revert, buffer retention, documented replay/loss handling and trained on-call |

A timeout-terminated canary process is neither a pass nor a fail by itself. Query the unique event. TLS success proves transport authentication under that probe, not parser correctness, destination authorization or ongoing delivery.

## Private handover record

Record change ID, owner/reviewer, target versions, GitOps/config revisions, internal host scope, public certificate fingerprints/expiry, receiver schemas/plugin versions, ES template/role/lifecycle revision, canary IDs, both-stream freshness, representative load evidence, rollback checkpoint and outstanding risks. Keep actual addresses, identities and diagnostic evidence in approved internal storage, outside this publication repository.
