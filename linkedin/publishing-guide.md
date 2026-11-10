# LinkedIn publishing guide

[Home](../README.md) · [Publication review](../docs/publication-review.md)

All four posts are reviewable drafts. Nothing has been published or scheduled. The recommended sequence is editorial: establish the system, examine trust, show the investigation, then explain operations. It is not a claim about an algorithmically optimal posting schedule.

| Order | Draft | Reader progression |
|---|---|---|
| 1 | [Architecture](post-01-architecture.md) | Understand the problem, path and protocol boundaries |
| 2 | [Security](post-02-security.md) | Distinguish trust, identity, authorization and remote renewal |
| 3 | [Troubleshooting](post-03-troubleshooting.md) | Follow evidence through shared filters and destination permissions |
| 4 | [Reliability](post-04-lessons-learned.md) | Understand finite buffering, staged rollout and recovery limits |

Publish only after ownership/confidentiality authorization and the author's first-person fact check. Resolve whether incident descriptions, recorded versions and architectural detail may be discussed outside the company. Keep the repository private until explicitly approved for public release and an authorized license decision is made.

For an initial editorial cadence, leave several days between posts so readers can discuss each topic. Choose timing using the author's actual audience activity; no universal best day/time or engagement result is asserted. Revise later posts to address useful technical questions without revealing internal data.

Use one sanitized visual per post: architecture, trust lifecycle, filter scope, then state/recovery boundaries. Reuse the same labels and colors. Do not use production screenshots, host inventories, certificate subjects, bucket names, graphs with identifiable workloads or fabricated before/after charts.

Each file separates the post body from its headline, alternate hook, visual brief, conditional GitHub reference and supporting source facts. Copy only the reviewed post body into LinkedIn. Keep the evidence notes for editorial review. The posts contain four relevant hashtags each and no invented outcomes.

Once public release is explicitly approved, insert the verified public GitHub link and point to the relevant document named in each draft. Until then, omit the repository link from public content. Do not invite readers to an inaccessible private URL or imply the project is open source before licensing is resolved.

Before each post, confirm that retirement/support statements remain current, links work, the visual matches the text, first-person attribution is accurate, and no recommendation is phrased as completed production work. Answer questions with evidence and uncertainty; do not claim zero loss, exactly-once delivery or quantified performance gains.
