#!/usr/bin/env bash
# ADAPTED EXAMPLE. Explicit context, namespace and pod list; no secret/config dump.
set -euo pipefail
if (($# < 3)); then
  printf 'Usage: %s CONTEXT NAMESPACE POD [POD ...]\n' "$0" >&2
  exit 2
fi
context=$1
namespace=$2
shift 2
for pod in "$@"; do
  printf 'Checking pod %s\n' "$pod"
  kubectl --context "$context" -n "$namespace" exec "$pod" -- sh -c '
    set -e
    test -r /fluentd/ceph-tls/tls.crt
    test -r /fluentd/ceph-tls/tls.key
    test -r /fluentd/ceph-client-ca/ca.crt
  '
  kubectl --context "$context" -n "$namespace" exec "$pod" -- ruby -rsocket -e \
    'Socket.tcp("127.0.0.1",24225,connect_timeout:2) { puts "LISTEN OK" }'
done
kubectl --context "$context" -n "$namespace" get endpointslice \
  -l kubernetes.io/service-name=fluentd-ceph
