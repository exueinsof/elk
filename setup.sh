#!/bin/bash

set -euo pipefail

CERTS_DIR="/usr/share/elasticsearch/config/certs"
CA_CERT="${CERTS_DIR}/ca/ca.crt"
CA_KEY="${CERTS_DIR}/ca/ca.key"

mkdir -p "${CERTS_DIR}"

if [[ ! -f "${CA_CERT}" ]]; then
  cat > "${CERTS_DIR}/instances.yml" <<'YAML'
instances:
  - name: elasticsearch
    dns:
      - elasticsearch
      - localhost
    ip:
      - 127.0.0.1
  - name: kibana
    dns:
      - kibana
      - localhost
    ip:
      - 127.0.0.1
  - name: logstash
    dns:
      - logstash
      - localhost
    ip:
      - 127.0.0.1
YAML

  /usr/share/elasticsearch/bin/elasticsearch-certutil ca --silent --pem --out "${CERTS_DIR}/ca.zip"
  unzip -qo "${CERTS_DIR}/ca.zip" -d "${CERTS_DIR}"
  /usr/share/elasticsearch/bin/elasticsearch-certutil cert --silent --pem \
    --in "${CERTS_DIR}/instances.yml" \
    --ca-cert "${CA_CERT}" \
    --ca-key "${CA_KEY}" \
    --out "${CERTS_DIR}/certs.zip"
  unzip -qo "${CERTS_DIR}/certs.zip" -d "${CERTS_DIR}"
fi

find "${CERTS_DIR}" -type d -exec chmod 755 {} \;
find "${CERTS_DIR}" -type f -exec chmod 644 {} \;

echo "Certificates ready."
