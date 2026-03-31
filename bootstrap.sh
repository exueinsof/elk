#!/bin/bash

set -euo pipefail

CA_CERT="/usr/share/elasticsearch/config/certs/ca/ca.crt"

echo "Waiting for Elasticsearch authentication..."
until curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  https://elasticsearch:9200/_security/_authenticate >/dev/null 2>&1; do
  sleep 5
done

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X POST https://elasticsearch:9200/_security/user/kibana_system/_password \
  -H "Content-Type: application/json" \
  -d "{\"password\":\"${KIBANA_PASSWORD}\"}" >/dev/null

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/_security/role/logstash_writer \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor", "manage_index_templates", "manage_ilm", "manage_ingest_pipelines"],
    "indices": [
      {
        "names": ["logs-pfsense.*", "logs-pfsense-*"],
        "privileges": ["auto_configure", "create_doc", "create_index", "manage", "write", "view_index_metadata"]
      }
    ]
  }' >/dev/null

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/_security/user/logstash_internal \
  -H "Content-Type: application/json" \
  -d "{\"password\":\"${LOGSTASH_PASSWORD}\",\"roles\":[\"logstash_writer\"],\"full_name\":\"Logstash Internal\"}" >/dev/null

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/_component_template/logs-pfsense-settings \
  -H "Content-Type: application/json" \
  -d '{
    "template": {
      "settings": {
        "index.number_of_replicas": 0
      }
    }
  }' >/dev/null

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/_component_template/logs-pfsense-mappings \
  -H "Content-Type: application/json" \
  -d '{
    "template": {
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "@version": { "type": "keyword" },
          "message": { "type": "match_only_text" },
          "data_stream": {
            "properties": {
              "type": { "type": "constant_keyword", "value": "logs" },
              "dataset": { "type": "constant_keyword" },
              "namespace": { "type": "constant_keyword", "value": "default" }
            }
          },
          "device": {
            "properties": {
              "name": { "type": "keyword" },
              "vendor": {
                "properties": {
                  "name": { "type": "keyword" }
                }
              }
            }
          },
          "ecs": { "properties": { "version": { "type": "keyword" } } },
          "event": {
            "properties": {
              "action": { "type": "keyword" },
              "category": { "type": "keyword" },
              "dataset": { "type": "keyword" },
              "kind": { "type": "keyword" },
              "original": { "type": "keyword", "index": false, "doc_values": false },
              "outcome": { "type": "keyword" },
              "type": { "type": "keyword" }
            }
          },
          "host": {
            "properties": {
              "ip": { "type": "ip" },
              "name": { "type": "keyword" }
            }
          },
          "source": {
            "properties": {
              "ip": { "type": "ip" },
              "port": { "type": "long" },
              "geo": {
                "properties": {
                  "continent_code": { "type": "keyword" },
                  "country_iso_code": { "type": "keyword" },
                  "country_name": { "type": "keyword" },
                  "timezone": { "type": "keyword" },
                  "location": { "type": "geo_point" }
                }
              }
            }
          },
          "destination": {
            "properties": {
              "ip": { "type": "ip" },
              "port": { "type": "long" }
            }
          },
          "observer": {
            "properties": {
              "vendor": { "type": "keyword" },
              "product": { "type": "keyword" },
              "type": { "type": "keyword" },
              "ingress": {
                "properties": {
                  "interface": { "type": "keyword" }
                }
              }
            }
          },
          "service": { "properties": { "type": { "type": "keyword" } } },
          "process": {
            "properties": {
              "name": { "type": "keyword" },
              "pid": { "type": "long" }
            }
          },
          "network": {
            "properties": {
              "direction": { "type": "keyword" },
              "transport": { "type": "keyword" },
              "type": { "type": "keyword" }
            }
          },
          "labels": {
            "properties": {
              "firewall_direction": { "type": "keyword" },
              "traffic_flow": { "type": "keyword" }
            }
          },
          "log": {
            "properties": {
              "syslog": {
                "properties": {
                  "priority": { "type": "long" }
                }
              }
            }
          }
        }
      }
    }
  }' >/dev/null

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/_index_template/logs-pfsense-custom \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["logs-pfsense.*-*"],
    "data_stream": {},
    "priority": 250,
    "composed_of": ["logs-pfsense-settings", "logs-pfsense-mappings"],
    "_meta": {
      "description": "pfSense single-node production template"
    }
  }' >/dev/null

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/logs-pfsense.firewall-default/_settings \
  -H "Content-Type: application/json" \
  -d '{"index.number_of_replicas":0}' >/dev/null || true

curl --silent --fail --cacert "${CA_CERT}" -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT https://elasticsearch:9200/logs-pfsense.system-default/_settings \
  -H "Content-Type: application/json" \
  -d '{"index.number_of_replicas":0}' >/dev/null || true

echo "Security bootstrap completed."
