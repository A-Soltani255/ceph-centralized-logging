# Confidentiality and publication review

[Home](../README.md) · [Security](security.md) · [Publishing](publishing.md)

**Status: keep private.** The source is an internal operational runbook. Company ownership, authorship rights and permission to distribute derived configuration/documentation have not been established. No LICENSE file is included and no open-source rights are granted. A license choice follows owner authorization; it cannot create rights the publisher does not hold.

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

Architecture, incident history, selected versions, scope counts, operating patterns and historical metrics may still reveal internal engineering work even after identifier removal. Sanitization does not establish publication rights or make all business context nonconfidential. Ask the owner/security reviewers whether those facts can be released and remove/generalize them if needed.

The LinkedIn posts use first-person wording as requested. The author must confirm personal involvement and the accuracy of attribution before publishing. They are drafts, not posts or endorsements. A private GitHub URL is not a public reader reference.

## Release gate

- Obtain documented authorization for derived docs, extracted configurations, architecture and incidents.
- Resolve authorship and select a suitable license only with authorized owners; then add the approved license text.
- Approve the historical metrics and all first-person statements; remove any information outside the permitted scope.
- Re-scan the complete Git history and staged release, including diagrams, generated assets and package lockfiles.
- Complete target-version/security review, especially maintained ingress transport and in-agent server identity validation.
- Review example labels, known gaps and quality report; do not turn skipped tests into badges.
- Change visibility only after explicit approval. Do not publish LinkedIn drafts automatically.
