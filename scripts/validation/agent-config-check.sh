#!/usr/bin/env bash
# ADAPTED EXAMPLE. Parser validation only; does not start a collection service.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/host-env.sh
source "$SCRIPT_DIR/../lib/host-env.sh"
[[ $EUID -eq 0 ]] || { printf 'Run as an authorized administrator (root).\n' >&2; exit 1; }
load_ceph_env "${1:-/etc/fluent-bit/ceph.env}"
for file in /etc/fluent-bit/ceph.conf /etc/fluent-bit/ceph-parsers.conf \
  /etc/fluent-bit/certs/client-fullchain.crt /etc/fluent-bit/certs/client.key \
  /etc/fluent-bit/certs/server-ca.crt; do
  runuser -u ceph-logreader -- test -r "$file"
done
runuser -u ceph-logreader -- env CEPH_FSID="$CEPH_FSID" CEPH_HOSTNAME="$CEPH_HOSTNAME" \
  /usr/bin/fluent-bit --dry-run -c /etc/fluent-bit/ceph.conf
