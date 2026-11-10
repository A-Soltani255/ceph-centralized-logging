# Post 2 draft — What mTLS authenticated, and what it did not

**Review status:** Draft only. Confirm first-person attribution and publication rights before posting.

## Post

A client certificate passed TLS validation. That did not prove it represented the intended node.

While working on the Ceph logging path, I had to separate three questions: can the peers build a trusted certificate chain, is the server identity correct, and is this particular client authorized?

The transport passed encrypted Forward traffic through HAProxy and ingress to Fluentd. Fluentd held the server key and trusted the client issuing CA. Each physical node had its own client certificate and key.

One chain-validation failure came down to a missing intermediate. Supplying the intermediate as chain-building material made the local verification succeed. That was a trust-chain repair, not a reason to disable verification.

Another finding was more subtle: a client Certificate resource had been copied with another host's identity. Shared CA trust could still allow a connection. Trusting an issuer was not an exact node allowlist, and a `ceph_host` field inside an event was not cryptographic identity.

The recorded Fluent Bit version also rejected a hostname-verification option. An independent OpenSSL check helped diagnosis, but I would not claim it proved the agent enforced that same policy.

The lifecycle mattered too. cert-manager renewed Kubernetes Secrets; it did not replace certificate files on physical hosts. Installed expiry, matching key/certificate pairs and a fresh handshake needed their own deployment checks.

My takeaway: mTLS is a strong building block, but the trust policy, identity policy and renewal workflow must be explicit. Least-privilege file access belongs in that design as well.

Where do you enforce client membership beyond “this certificate chains to a trusted CA”?

\#SecurityEngineering #mTLS #DevOps #Ceph

## Editorial notes

- **Suggested headline:** What mTLS authenticated, and what it did not
- **Alternative hook:** Issuing certificates was only one part of securing the logging pipeline.
- **Visual:** Two trust directions between a Ceph client and Fluentd, with separate boxes for chain validation, server identity and client authorization. Show renewal → host deployment → reload as distinct steps.
- **GitHub reference, only after public approval:** Link `docs/security.md` and `docs/certificate-lifecycle.md` in the approved public repository.
- **Source support:** §§8–11, 20.4–20.6, 20.13 and 21 describe ACLs, intermediate-chain failure, shared CA behavior, copied CN, unsupported TLS option and remote renewal gap. No claim of a deployed fingerprint/SAN allowlist or verified revocation is made.
