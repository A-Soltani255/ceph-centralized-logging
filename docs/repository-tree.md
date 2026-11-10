# Repository file tree

[Home](../README.md)

Actual deliverable files; generated dependencies and local Git metadata excluded.

```text
ceph-centralized-logging/
├── .gitattributes
├── .github/
│   └── workflows/
│       └── docs-validation.yml
├── .gitignore
├── .markdownlint-cli2.jsonc
├── CHANGELOG.md
├── configs/
│   ├── cert-manager/
│   │   ├── client.example.yaml
│   │   └── server.example.yaml
│   ├── elasticsearch/
│   │   ├── create-stream.example.http
│   │   └── create-template.example.http
│   ├── fluent-bit/
│   │   ├── ceph-canary.conf.example
│   │   ├── ceph-parsers.conf
│   │   ├── ceph.conf
│   │   ├── fluent-bit-ceph.service
│   │   └── journal.proposed.fragment.example.conf
│   ├── fluentd/
│   │   ├── cluster-input.example.yaml
│   │   ├── elasticsearch-output.fragment.example.conf
│   │   ├── mounts.historical.fragment.example.yaml
│   │   ├── routing-order.fragment.example.conf
│   │   ├── selector.fragment.example.yaml
│   │   └── service.example.yaml
│   ├── haproxy/
│   │   └── haproxy.example.cfg
│   ├── ingress/
│   │   └── ingress.example.yaml
│   └── provenance.json
├── CONTRIBUTING.md
├── diagrams/
│   ├── architecture.mmd
│   └── architecture.svg
├── docs/
│   ├── architecture.md
│   ├── certificate-lifecycle.md
│   ├── configuration.md
│   ├── elasticsearch.md
│   ├── evidence.md
│   ├── installation.md
│   ├── lessons-learned.md
│   ├── operations.md
│   ├── optional-journal.md
│   ├── performance.md
│   ├── prerequisites.md
│   ├── publication-review.md
│   ├── publishing.md
│   ├── quality-report.md
│   ├── references.md
│   ├── repository-tree.md
│   ├── rollback.md
│   ├── security.md
│   ├── source-coverage.md
│   ├── troubleshooting.md
│   └── validation.md
├── examples/
│   └── environment/
│       └── ceph.env.example
├── linkedin/
│   ├── post-01-architecture.md
│   ├── post-02-security.md
│   ├── post-03-troubleshooting.md
│   ├── post-04-lessons-learned.md
│   └── publishing-guide.md
├── package-lock.json
├── package.json
├── README.md
├── scripts/
│   ├── diagnostics/
│   │   ├── check-mtls.sh
│   │   ├── host-preflight.sh
│   │   └── receiver-check.sh
│   ├── lib/
│   │   └── host-env.sh
│   └── validation/
│       ├── agent-config-check.sh
│       ├── check-mermaid.mjs
│       └── check-repository.mjs
└── SECURITY.md
```
