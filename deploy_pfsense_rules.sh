#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
fi

: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD is required in .env}"

KIBANA_AUTH="elastic:${ELASTIC_PASSWORD}"
KIBANA_URL="https://localhost:5601"

create_rule() {
  local file="$1"

  docker exec -i kibana curl -s -k -u "${KIBANA_AUTH}" \
    -X POST "${KIBANA_URL}/api/detection_engine/rules" \
    -H 'kbn-xsrf: true' \
    -H 'Content-Type: application/json' \
    --data-binary @- < "${file}" >/dev/null
}

delete_rule() {
  local rule_id="$1"

  docker exec kibana curl -s -k -u "${KIBANA_AUTH}" \
    -X DELETE "${KIBANA_URL}/api/detection_engine/rules?rule_id=${rule_id}" \
    -H 'kbn-xsrf: true' >/dev/null || true
}

delete_rule test_pfsense_external_inbound_blocks
delete_rule pfsense_external_inbound_block_burst
delete_rule pfsense_geolocated_source_burst
delete_rule pfsense_possible_external_port_scan
delete_rule pfsense_targeted_internal_host
delete_rule pfsense_internal_egress_port_sweep
delete_rule pfsense_multicast_block_storm
delete_rule pfsense_sshguard_stopped_monitoring
delete_rule pfsense_dhcp6c_prefix_failure_burst

create_rule "${ROOT_DIR}/payloads/rules/pfsense-external-inbound-block-burst.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-geolocated-source-burst.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-external-port-scan.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-targeted-internal-host.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-internal-egress-port-sweep.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-multicast-block-storm.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-sshguard-exit.json"
create_rule "${ROOT_DIR}/payloads/rules/pfsense-dhcp6c-prefix-failure-burst.json"

echo "pfSense detection rules deployed."
