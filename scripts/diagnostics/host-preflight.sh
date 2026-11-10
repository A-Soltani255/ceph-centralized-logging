#!/usr/bin/env bash
# ADAPTED EXAMPLE. Read-only checks; diagnostic output remains confidential.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/host-env.sh
source "$SCRIPT_DIR/../lib/host-env.sh"
[[ $EUID -eq 0 ]] || { printf 'Run as an authorized administrator (root).\n' >&2; exit 1; }
load_ceph_env "${1:-/etc/fluent-bit/ceph.env}"
for tool in runuser getfacl namei openssl systemctl df du; do
  command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool" >&2; exit 1; }
done
log_dir="/var/log/ceph/$CEPH_FSID"
test -d "$log_dir"
namei -l "$log_dir"
getfacl -p "$log_dir"
# Expansion intentionally happens in the nested shell under the reader identity.
# shellcheck disable=SC2016
runuser -u ceph-logreader -- bash -c '
  set -euo pipefail
  d=$1
  test -r "$d" && test -x "$d"
  shopt -s nullglob
  files=("$d"/*.log)
  ((${#files[@]} > 0)) || { echo "No matching current log files" >&2; exit 1; }
  for file in "${files[@]}"; do
    test -r "$file" || { echo "Unreadable log file" >&2; exit 1; }
  done
  printf "Readable current files: %s\n" "${#files[@]}"
' _ "$log_dir"
if [[ -e /var/log/ceph/cephadm.log ]]; then
  runuser -u ceph-logreader -- test -r /var/log/ceph/cephadm.log
fi
df -h /var/lib/fluent-bit-ceph
du -sh /var/lib/fluent-bit-ceph
systemctl show fluent-bit-ceph -p User -p Group -p MainPID -p MemoryCurrent
openssl x509 -in /etc/fluent-bit/certs/client-fullchain.crt -noout -subject -issuer -dates
printf 'Preflight checks passed; this does not establish delivery or capacity.\n'
