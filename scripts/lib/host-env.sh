#!/usr/bin/env bash
# ADAPTED EXAMPLE: parse two literal keys; never evaluate a host environment file.
load_ceph_env() {
  local env_file=${1:?environment path required} line key value
  CEPH_FSID=''
  CEPH_HOSTNAME=''
  [[ -r "$env_file" ]] || { printf 'Environment file unreadable\n' >&2; return 1; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" != *$'\r'* && "$line" == *=* ]] || return 1
    key=${line%%=*}
    value=${line#*=}
    case "$key" in
      CEPH_FSID) [[ -z "$CEPH_FSID" ]] || return 1; CEPH_FSID=$value ;;
      CEPH_HOSTNAME) [[ -z "$CEPH_HOSTNAME" ]] || return 1; CEPH_HOSTNAME=$value ;;
      *) printf 'Unexpected environment key\n' >&2; return 1 ;;
    esac
  done < "$env_file"
  [[ "$CEPH_FSID" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ]] || {
    printf 'Invalid or unresolved CEPH_FSID\n' >&2; return 1;
  }
  [[ "$CEPH_HOSTNAME" =~ ^[[:alnum:]][[:alnum:].-]{0,252}$ ]] || {
    printf 'Invalid CEPH_HOSTNAME\n' >&2; return 1;
  }
  export CEPH_FSID CEPH_HOSTNAME
}
