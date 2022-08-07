[
    {
      "name" : "OPENCTI_URL",
      "value" : "${OPENCTI_PLATFORM_URL}"
    },
    {
      "name" : "CONNECTOR_ID",
      "value" : "${RANDOM_UUID}"
    },
    {
      "name" : "CONNECTOR_TYPE",
      "value" : "EXTERNAL_IMPORT"
    },
    {
      "name" : "CONNECTOR_NAME",
      "value" : "MITRE Datasets"
    },
    {
      "name" : "CONNECTOR_SCOPE",
      "value" : "marking-definition,identity,attack-pattern,course-of-action,intrusion-set,campaign,malware,tool,report,external-reference-as-report"
    },
    {
      "name" : "CONNECTOR_CONFIDENCE_LEVEL",
      "value" : "90"
    },
    {
      "name" : "CONNECTOR_UPDATE_EXISTING_DATA",
      "value" : "true"
    },
    {
      "name" : "CONNECTOR_RUN_AND_TERMINATE",
      "value" : "false"
    },
    {
      "name" : "CONNECTOR_LOG_LEVEL",
      "value" : "info"
    },
    {
      "name" : "MITRE_ENTERPRISE_FILE_URL",
      "value" : "https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json"
    },
    {
      "name" : "MITRE_PRE_ATTACK_FILE_URL",
      "value" : "https://raw.githubusercontent.com/mitre/cti/master/pre-attack/pre-attack.json"
    },
    {
      "name" : "MITRE_MOBILE_ATTACK_FILE_URL",
      "value" : "https://raw.githubusercontent.com/mitre/cti/master/mobile-attack/mobile-attack.json"
    },
    {
      "name" : "MITRE_ICS_ATTACK_FILE_URL",
      "value" : "https://raw.githubusercontent.com/mitre/cti/master/ics-attack/ics-attack.json"
    },
    {
      "name" : "MITRE_CAPEC_FILE_URL",
      "value" : "https://raw.githubusercontent.com/mitre/cti/master/capec/2.1/stix-capec.json"
    },
    {
      "name" : "MITRE_INTERVAL",
      "value" : "30"
    }
]