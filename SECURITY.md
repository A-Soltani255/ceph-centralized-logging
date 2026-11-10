# Security guidance

This is documentation and example configuration, not a supported production distribution. No version is represented as security-certified, penetration-tested or currently free of vulnerabilities. See the [security review](docs/security.md), especially ingress-nginx retirement and unresolved historical agent hostname verification.

Do not post secrets, raw logs, real identities, customer content or private topology in issues or pull requests. For a sensitive finding, use GitHub private vulnerability reporting **if the repository exposes it**, or an established private channel with the repository owner. No reporting mailbox or response-time promise is invented here. If no private channel is available, request one without disclosing the sensitive payload.

Report affected revision, component/version, sanitized reproduction, impact and proposed mitigation. Do not test exploitation on production or other people's systems. A leaked credential requires prompt containment/rotation and history review; deleting the current file alone does not remove it from Git history.

Repository checks and Gitleaks are screening controls, not a confidentiality guarantee. Publication requires human rights, security and content review. Never grant this repository production secrets merely to test its documentation workflow.
