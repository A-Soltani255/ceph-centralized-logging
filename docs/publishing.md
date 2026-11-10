# Repository presentation and publishing

[Home](../README.md) · [Publication review](publication-review.md) · [Quality report](quality-report.md)

Repository name: `ceph-centralized-logging`. Initial visibility: **private**. No public release or license grant is authorized. No LinkedIn publication or scheduling is authorized.

Suggested description: Evidence-based Ceph logging architecture, sanitized configuration examples, mTLS guidance, and operations for shared Fluentd pipelines. Private publication review.

Suggested topics: `ceph`, `fluent-bit`, `fluentd`, `kubernetes`, `elasticsearch`, `observability`, `mtls`, `sre`, `logging`, `runbook`. Add topics only to accurately describe content; they are not claims of supported integrations.

## Local commit and authenticated publication

Use only the authenticated owner's account. Check whether the repository exists and verify private visibility before any upload. Do not push over an unrelated existing project or change an existing public repository's visibility casually.

With GitHub CLI authenticated as the intended owner, these are the recovery steps if local Git credentials or connector repository access are unavailable:

```bash
gh auth status
gh api user --jq .login
gh repo view A-Soltani255/ceph-centralized-logging --json nameWithOwner,visibility
```

The repository has already been created privately for this task; do not run `gh repo create` again. From the completed local checkout, inspect the remote and history, rerun the scans, then authenticate Git and push only if the destination is still private and its history is compatible:

```bash
gh auth setup-git
git remote -v
git fetch origin
git log --oneline --all --decorate -10
git status --short
npm ci --ignore-scripts
npm run check
npm run lint:markdown
npm run check:mermaid
gitleaks git --redact --no-banner .
git push -u origin main
```

If the remote contains an independent bootstrap commit, fetch/reconcile normally and review the resulting diff; do not force-push by default. If `origin` is absent, add `https://github.com/A-Soltani255/ceph-centralized-logging.git` after verifying its owner and private status. Never paste a token into a remote URL, commit, shell history or support message.

GitHub connector access and browser sign-in are separate authentication paths. The connector returned 404 for this private repository, local Git had no usable credentials, and browser bulk upload required the extension's disabled file-URL permission. Publication therefore uses GitHub's authenticated web text editor, preserving private visibility without expanding permissions. The remote history starts with its own README commit and differs from the independently prepared local Git history.

For future work, clone the populated remote after authenticating Git, or reconcile both histories deliberately. Do not force-push the independent local history over the web commits. Web-created shell files may lack executable mode; invoke them with `bash scripts/diagnostics/host-preflight.sh` (and equivalent paths), or review and commit executable modes from an authenticated checkout. Inspect Actions separately: publishing workflow source is not evidence that its checks passed.

## Public release checklist

Complete [publication review](publication-review.md), resolve rights/licensing, review historical facts and first-person drafts, validate a maintained target stack, inspect full Git history and get explicit approval before changing visibility. Then verify anonymous access and update conditional LinkedIn links. Do not add passing CI, coverage, production-tested or certification badges without matching evidence.
