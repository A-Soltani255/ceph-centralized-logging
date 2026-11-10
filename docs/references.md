# Primary references

[Home](../README.md) · [Evidence](evidence.md)

These support product semantics and maintenance review, not deployment evidence. Consult documentation matching the exact installed builds and CRDs. The following selected primary pages were reviewed on 10 November 2026: Forward/TLS/storage, Fluentd Forward, ingress passthrough and retirement, cert-manager Certificate, and Elasticsearch privileges. Other links are implementation references to recheck during target validation.

- [Fluent Bit 2.2 Forward output](https://docs.fluentbit.io/manual/2.2/pipeline/outputs/forward)
- [Fluent Bit 2.2 transport security](https://docs.fluentbit.io/manual/2.2/administration/transport-security)
- [Fluent Bit 2.2 buffering and storage](https://docs.fluentbit.io/manual/2.2/administration/buffering-and-storage)
- [Fluent Bit 2.2 Tail](https://docs.fluentbit.io/manual/2.2/pipeline/inputs/tail)
- [Fluent Bit 2.2 systemd input](https://docs.fluentbit.io/manual/2.2/pipeline/inputs/systemd)
- [Fluentd Forward input](https://docs.fluentd.org/input/forward)
- [Fluentd transport section](https://docs.fluentd.org/configuration/transport-section)
- [Fluentd buffer section](https://docs.fluentd.org/configuration/buffer-section)
- [Fluent Operator source and CRDs](https://github.com/fluent/fluent-operator)
- [Legacy ingress-nginx TLS passthrough](https://kubernetes.github.io/ingress-nginx/user-guide/tls/)
- [Kubernetes ingress-nginx retirement announcement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
- [cert-manager Certificate lifecycle](https://cert-manager.io/docs/usage/certificate/)
- [Elasticsearch security privileges](https://www.elastic.co/docs/reference/elasticsearch/security-privileges)
- [Elasticsearch create data stream](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-indices-create-data-stream)
- [Elasticsearch index template API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-indices-put-index-template)

The confidential source itself is intentionally not linked or bundled. Maintainers should keep their source custody and ownership records in restricted internal storage.
