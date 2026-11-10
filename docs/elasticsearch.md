# Elasticsearch, mappings and search

[Home](../README.md) · [Troubleshooting](troubleshooting.md) · [Performance](performance.md)

## One stream with multiple datasets

Ceph events use `logs-ceph-default`; `ceph_dataset` distinguishes daemon, cluster, audit and RGW families within it. Existing Kubernetes outputs remain separate. The full production output, role and template were not provided. The examples are not a replacement for current objects.

Before changing anything, inspect privately in Kibana Dev Tools:

```http
GET _data_stream/logs-ceph-default
GET _index_template
GET logs-ceph-default/_mapping
GET logs-ceph-default/_field_caps?fields=log,message,ceph_*,source_file
GET _cat/shards/.ds-logs-ceph-default*?v&expand_wildcards=all
```

Find the actual matching template, priority and lifecycle policy. The example name `ceph-logs-template`, priority 501, one primary and one replica are illustrative. They are not measured production sizing advice. For a fresh environment, review the [template example](../configs/elasticsearch/create-template.example.http) before the [stream example](../configs/elasticsearch/create-stream.example.http). Data stream documents require a date-compatible `@timestamp`; inspect the installed output plugin's timestamp behavior.

Template changes generally affect new backing indices. Plan rollover and mapping compatibility; a changed template does not repair old incompatible fields. Do not delete a stream to fix a mapping error or arbitrarily add shards to treat collector CPU saturation.

## Mapping and confidentiality

Keep `log` scalar and `source_file` flat in this baseline. Sending an object `log.file.path` into an existing text `log` mapping produces a conflict. Moving to an ECS-style shape requires a migration plan, not a publication-time edit to the snapshot.

The JSON parser preserves original types and unknown fields. `dynamic: true` in the extracted template is a source example and may admit unbounded field growth. Review explicit mappings, field limits, privacy and malformed-record handling before production. The template does not comprehensively map every parsed field. In particular, compare `ceph_rgw_http_status` and `ceph_rgw_status_code` across formats before applying numeric aggregations.

RGW records can expose client addresses, users, bucket/object names, URI parameters and user agents; audit command strings may contain sensitive values. Restrict access and retention and test any redaction against forensic requirements. Raw fields preserved for troubleshooting can defeat superficial field-only redaction.

## The metadata-privilege incident

The source reports a 403 on `indices:admin/data_stream/get` for the Ceph writer. The stream could exist and routing could work while plugin initialization/introspection still failed. Granting the necessary privileges reportedly restored Ceph canary delivery and Kubernetes flow. The exact repaired role JSON is unavailable.

Start with a pre-provisioned stream and a restricted writer. Candidate privileges include `create_doc` if the plugin uses compatible create operations and `view_index_metadata` for stream metadata. Auto-creation, mapping updates, templates, ILM or plugin startup may require additional actions. Inspect the installed plugin and test its full lifecycle with the same identity used in Fluentd. A successful admin Dev Tools request proves only the admin's rights. [Privilege reference](https://www.elastic.co/docs/reference/elasticsearch/security-privileges)

No role JSON is fabricated here. Prefer separate provisioning and writer identities and narrow stream-name scope; do not grant broad `manage` or disable security just to eliminate a 403. Use secret-backed authentication without passwords in command arguments, shell history, tickets or Git.

## Search and acceptance

Create a data view for `logs-ceph-default`, normally using `@timestamp`, and select a time range that includes the source event. Browser timezone and parsed source timezone can differ. A successful historical search is not proof of current delivery.

Dev Tools uses REST/JSON:

```http
GET logs-ceph-default/_search
{
  "size": 10,
  "query": {
    "bool": {
      "filter": [
        {"term": {"ceph_host": "ceph-node-01"}},
        {"range": {"@timestamp": {"gte": "now-15m"}}}
      ]
    }
  },
  "sort": [{"@timestamp": "desc"}]
}

GET logs-ceph-default/_search
{
  "query": {"match_phrase": {"message": "CEPH_FORWARD_CANARY_REPLACE_WITH_UNIQUE_ID"}}
}

GET logs-ceph-default/_search
{
  "size": 0,
  "query": {"range": {"@timestamp": {"gte": "now-1h"}}},
  "aggs": {
    "hosts": {"terms": {"field": "ceph_host", "size": 20}},
    "datasets": {"terms": {"field": "ceph_dataset", "size": 20}},
    "parse_results": {"terms": {"field": "ceph_parse_status", "size": 5}},
    "source_files": {"terms": {"field": "source_file", "size": 30}}
  }
}
```

KQL belongs in Discover, not Dev Tools:

```kql
ceph_dataset: "ceph.audit"
ceph_daemon_type: "osd" and ceph_daemon_id: "7"
ceph_parse_status: "unparsed"
ceph_rgw_status_code >= 500
```

Term queries and aggregations assume keyword fields; use a real `.keyword` multifield only if the live mapping defines it. Numeric status comparisons require numeric mappings. Verify naturally produced post-start records and a unique canary alongside fresh Kubernetes events.

An ingest-time `event.ingested` field was proposed but not deployed in the evidence. Do not report exact end-to-end latency from event timestamps alone. A manual `_refresh` only exposes already indexed records and is a mutating operation; repeated refreshes do not repair rejected events and add load.
