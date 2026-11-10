# Confidentiality and publication review

[Home](../README.md) · [Security](security.md) · [Publishing](publishing.md)

**Status: public release authorized.** On 10 November 2026, the repository owner explicitly authorized public release of the sanitized documentation, configurations, incident descriptions and commit history, and confirmed authority to release that material. The source remains a confidential internal operational runbook and is excluded. This records the owner’s authorization, not an independent legal determination of ownership. No LICENSE file is included and no open-source rights are granted. A license choice follows owner authorization; it cannot create rights the publisher does not hold.

## Sanitization performed

| Category | Treatment |
|---|---|
| Internal DNS/FQDNs | Replaced with `logs.example.com`, node names under `example.com`, and example CA naming |
| Hostnames/inventory | Replaced with `ceph-node-01`/`ceph-node-02`; identifiable inventory excluded |
| Ceph FSID | Replaced with literal `<CEPH_FSID>`; no real UUID in artifacts |
| Organization and internal PKI labels | Generalized to role/team and example CA descriptions |
| Writer username and storage class | Placeholder or omitted; no credential value invented |
| Infrastructure addresses | No actual VIP, worker or destination IP supplied in extracted examples; explicit placeholders retained |
| Internal repository/source paths | Original local path and internal repository details omitted |
| Certificates, private keys and Kubernetes Secret payloads | None included; only resource references and secure handling instructions |
| Logs/customer data | No raw production log samples, bucket/object names or sensitive transcript export |
| Historical measurements | Retained only as source-reported investigation samples with limitations; owner must approve disclosure |

Manual full-source review found references to key/certificate handling but no complete PEM private-key/certificate blocks or actual password/token values. That is a scoped review result, not proof that all possible secrets can be detected. The original source, raw text and private sanitization map remain outside the repository.

## Residual publication concerns

Architecture, incident history, selected versions, scope counts, operating patterns and historical metrics may still reveal internal engineering work even after identifier removal. Sanitization does not establish publication rights or make all business context nonconfidential. The owner approved release of the current sanitized material. Review newly contributed facts separately and remove/generalize any information outside that authorization.

The LinkedIn posts use first-person wording as requested. The author must confirm personal involvement and the accuracy of attribution before publishing. They are drafts, not posts or endorsements. The public repository is a reader reference; visibility does not itself grant an open-source license.

## Release gate

- Current sanitized release: owner authorization recorded above; assess authorization again when scope or source material changes.
- Resolve authorship and select a suitable license only with authorized owners; then add the approved license text.
- Approve the historical metrics and all first-person statements; remove any information outside the permitted scope.
- Re-scan the complete Git history and staged release, including diagrams, generated assets and package lockfiles.
- Complete target-version/security review, especially maintained ingress transport and in-agent server identity validation.
- Review example labels, known gaps and quality report; do not turn skipped tests into badges.
- Change visibility only after explicit approval. Do not publish LinkedIn drafts automatically.
