[
  {
    "name" : "APP__PORT",
    "value" : "${opencti_platform_port}"
  },
  {
    "name" : "APP__ADMIN__EMAIL",
    "value" : "${opencti_platform_admin_email}"
  },
  {
    "name" : "NODE_OPTIONS",
    "value" : "--max-old-space-size=${opencti_platform_memory_size}"
  },
  {
    "name" : "APP__APP_LOGS__LOGS_LEVEL",
    "value" : "${opencti_logging_level}"
  },
  {
    "name" : "REDIS__HOSTNAME",
    "value" : "${elasticache_endpoint_address}"
  },
  {
    "name" : "REDIS__PORT",
    "value" : "${elasticache_redis_port}"
  },
  {
    "name" : "REDIS__USE_SSL",
    "value" : "true"
  },
  {
    "name" : "REDIS__TRIMMING",
    "value" : "${redis_trimming}"
  },
  {
    "name" : "ELASTICSEARCH__URL",
    "value" : "https://${opensearch_endpoint_address}"
  },
  {
    "name" : "ELASTICSEARCH__NUMBER_OF_SHARDS",
    "value" : "${opensearch_template_primary_shard_count}"
  },
  {
    "name" : "MINIO__ENDPOINT",
    "value" : "s3.${aws_region}.amazonaws.com"
  },
  {
    "name" : "MINIO__PORT",
    "value" : "443"
  },
  {
    "name" : "MINIO__BUCKET_NAME",
    "value" : "${minio_s3_bucket_name}"
  },
  {
    "name" : "MINIO__BUCKET_REGION",
    "value" : "${aws_region}"
  },
  {
    "name" : "MINIO__USE_SSL",
    "value" : "true"
  },
  {
    "name" : "MINIO__USE_AWS_ROLE",
    "value" : "true"
  },
  {
    "name" : "RABBITMQ__HOSTNAME",
    "value" : "${private_network_load_balancer_dns}"
  },
  {
    "name" : "RABBITMQ__PORT",
    "value" : "${rabbitmq_node_port}"
  },
  {
    "name" : "RABBITMQ__PORT_MANAGEMENT",
    "value" : "${rabbitmq_management_port}"
  },
  {
    "name" : "RABBITMQ__USE_SSL",
    "value" : "false"
  },
  {
    "name" : "PROVIDERS__OPENID__STRATEGY",
    "value" : "OpenIDConnectStrategy"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__LABEL",
    "value" : "Login with OpenID"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__ISSUER",
    "value" : "${oidc_information_issuer}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__CLIENT_ID",
    "value" : "${oidc_information_client_id}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__CLIENT_SECRET",
    "value" : "${oidc_information_client_secret}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__REDIRECT_URIS",
    "value" : ${oidc_information_redirect_uris}
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__TOKEN_REFERENCE",
    "value" : "${opencti_openid_mapping_config_roles_token}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__ROLES_SCOPE",
    "value" : "${opencti_openid_mapping_config_roles_scope}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__ROLES_MAPPING",
    "value" : ${opencti_openid_mapping_config_roles_mapping}
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__ROLES_MANAGEMENT__ROLES_PATH",
    "value" : ${opencti_openid_mapping_config_roles_path}
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__TOKEN_REFERENCE",
    "value" : "${opencti_openid_mapping_config_groups_token}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__GROUPS_SCOPE",
    "value" : "${opencti_openid_mapping_config_groups_scope}"
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__GROUPS_MAPPING",
    "value" : ${opencti_openid_mapping_config_groups_mapping}
  },
  {
    "name" : "PROVIDERS__OPENID__CONFIG__GROUPS_MANAGEMENT__GROUPS_PATH",
    "value" : ${opencti_openid_mapping_config_groups_path}
  },
  {
    "name" : "PROVIDERS__LOCAL__STRATEGY",
    "value" : "LocalStrategy"
  }
]