# Proposed journal and kernel extension

[Home](../README.md) · [Configuration](configuration.md) · [Security](security.md)

**PROPOSED ONLY.** No revised deployed snapshot or successful multi-host journal output was supplied. The [fragment](../configs/fluent-bit/journal.proposed.fragment.example.conf) is deliberately separate from the preserved baseline.

Journald can provide systemd/service messages and retained kernel transport records. Reading both the journal and `dmesg` indiscriminately can duplicate kernel events; the ring buffer also does not establish durable history. Journal coverage depends on persistence/retention and boot history. Ceph daemon events may overlap the file-tail sources too.

The proposed input uses `Name systemd`, tag `ceph.host.journal`, its own `journal.db`, `Read_From_Tail On`, `Max_Entries 500` and filesystem storage. `Max_Entries` bounds work per iteration, not records per second. The deployed receiver match accepts only `ceph.ops ceph.audit`; the new tag would be forwarded by the agent's broader match and could fall into the Kubernetes catchall. Design the receiver route **before** enabling it.

## Controlled validation plan

1. Verify plugin availability and journal access under the actual reader identity. Review group/ACL changes and sandbox paths for `/run/log/journal` or `/var/log/journal`; broad host-log access is a new security boundary.
2. Inspect `journalctl --disk-usage`, `journalctl --list-boots`, and `journalctl -k` under authorized access. Do not assert missing historical kernel coverage exists.
3. Use an isolated cursor and local stdout output in a lab. Review record sensitivity and volume before forwarding.
4. Decide explicitly whether these records belong in the single Ceph stream or a separately approved host stream. Add an exact receiver match and safe mappings.
5. Select unit families to avoid duplicate Ceph file/journal ingestion. Review `_SYSTEMD_UNIT`, `_PID`, `_COMM`, `_TRANSPORT`, `SYSLOG_IDENTIFIER`, `PRIORITY`, `_HOSTNAME` and boot ID; do not forward unrestricted credential-bearing messages.
6. Test kernel and daemon cases, cursor restart, duplicates, parse/field types, throughput, disk and both destinations' freshness.
7. Roll out one node at a time. Roll back only the extension and preserve existing Tail DBs and its separate journal cursor.
