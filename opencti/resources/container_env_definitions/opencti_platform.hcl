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
  }
]