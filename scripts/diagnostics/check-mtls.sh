#!/usr/bin/env bash
# ADAPTED EXAMPLE. Network handshake only; no Forward event is emitted.
# Requires OpenSSL with -cert_chain support and GNU timeout (Linux target).
set -euo pipefail
if (($# < 5 || $# > 6)); then
  printf 'Usage: %s HOST SERVER_CA CLIENT_LEAF CLIENT_KEY INTERMEDIATES_OR_DASH [CONNECT_HOST:PORT]\n' "$0" >&2
  exit 2
fi
host=$1
server_ca=$2
client_leaf=$3
client_key=$4
intermediates=$5
connect=${6:-$host:443}
[[ "$host" =~ ^[[:alnum:]][[:alnum:].-]{0,252}$ ]] || exit 2
for file in "$server_ca" "$client_leaf" "$client_key"; do test -r "$file"; done
args=(-connect "$connect" -servername "$host" -verify_hostname "$host"
  -verify_return_error -CAfile "$server_ca" -cert "$client_leaf" -key "$client_key"
  -tls1_2 -brief)
if [[ "$intermediates" != '-' ]]; then
  test -r "$intermediates"
  args+=(-cert_chain "$intermediates")
fi
timeout 20s openssl s_client "${args[@]}" </dev/null
printf 'Handshake command completed; verify receiver client-auth logs and run a separate canary.\n'
