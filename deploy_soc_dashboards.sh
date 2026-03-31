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

upsert_saved_object() {
  local type="$1"
  local id="$2"
  local file="$3"

  docker exec -i kibana curl -s -k -u "${KIBANA_AUTH}" \
    -X POST "${KIBANA_URL}/api/saved_objects/${type}/${id}?overwrite=true" \
    -H 'kbn-xsrf: true' \
    -H 'Content-Type: application/json' \
    --data-binary @- < "${file}" >/dev/null
}

update_config() {
  docker exec kibana curl -s -k -u "${KIBANA_AUTH}" \
    -X PUT "${KIBANA_URL}/api/saved_objects/config/9.3.2" \
    -H 'kbn-xsrf: true' \
    -H 'Content-Type: application/json' \
    -d '{"attributes":{"defaultRoute":"/app/dashboards#/view/soc-pfsense-executive","timepicker:timeDefaults":"{\"from\":\"now-24h\",\"to\":\"now\"}"}}' >/dev/null
}

upsert_saved_object visualization soc-external-countries-table "${ROOT_DIR}/payloads/soc-external-countries-table.json"
upsert_saved_object visualization soc-external-blocked-sources-table "${ROOT_DIR}/payloads/soc-external-blocked-sources-table.json"
upsert_saved_object visualization soc-egress-top-destinations-table "${ROOT_DIR}/payloads/soc-egress-top-destinations-table.json"
upsert_saved_object visualization soc-egress-top-ports-pie "${ROOT_DIR}/payloads/soc-egress-top-ports-pie.json"
upsert_saved_object visualization soc-internal-top-talkers-table "${ROOT_DIR}/payloads/soc-internal-top-talkers-table.json"
upsert_saved_object visualization soc-system-processes-table "${ROOT_DIR}/payloads/soc-system-processes-table.json"
upsert_saved_object visualization soc-alert-severity-pie "${ROOT_DIR}/payloads/soc-alert-severity-pie.json"
upsert_saved_object visualization soc-alert-status-pie "${ROOT_DIR}/payloads/soc-alert-status-pie.json"
upsert_saved_object visualization soc-alert-rules-table "${ROOT_DIR}/payloads/soc-alert-rules-table.json"
upsert_saved_object visualization soc-alert-sources-table "${ROOT_DIR}/payloads/soc-alert-sources-table.json"
upsert_saved_object visualization soc-alert-timeline "${ROOT_DIR}/payloads/soc-alert-timeline.json"
upsert_saved_object visualization soc-exec-open-alerts-metric "${ROOT_DIR}/payloads/soc-exec-open-alerts-metric.json"
upsert_saved_object visualization soc-exec-high-alerts-metric "${ROOT_DIR}/payloads/soc-exec-high-alerts-metric.json"
upsert_saved_object visualization soc-exec-attackers-metric "${ROOT_DIR}/payloads/soc-exec-attackers-metric.json"
upsert_saved_object visualization soc-exec-top-rules-table "${ROOT_DIR}/payloads/soc-exec-top-rules-table.json"
upsert_saved_object visualization soc-exec-top-sources-table "${ROOT_DIR}/payloads/soc-exec-top-sources-table.json"
upsert_saved_object visualization soc-exec-sequence-timeline "${ROOT_DIR}/payloads/soc-exec-sequence-timeline.json"

upsert_saved_object dashboard 42562f7a-3d2e-4ce4-862b-2f1a7c1c27d5 "${ROOT_DIR}/payloads/dashboard-soc-overview.json"
upsert_saved_object dashboard soc-wan-threat-monitoring "${ROOT_DIR}/payloads/dashboard-soc-wan.json"
upsert_saved_object dashboard soc-lan-egress-activity "${ROOT_DIR}/payloads/dashboard-soc-lan.json"
upsert_saved_object dashboard soc-pfsense-alerts "${ROOT_DIR}/payloads/dashboard-soc-alerts.json"
upsert_saved_object dashboard soc-pfsense-alerts-open "${ROOT_DIR}/payloads/dashboard-soc-alerts-open.json"
upsert_saved_object dashboard soc-pfsense-alerts-high-open "${ROOT_DIR}/payloads/dashboard-soc-alerts-high-open.json"
upsert_saved_object dashboard soc-pfsense-executive "${ROOT_DIR}/payloads/dashboard-soc-executive.json"

update_config

echo "SOC dashboards deployed."
