# Default tags to apply to all deployed resources
tags = {
  Company = "Example"
  Department = "Example"
  Environment = "dev"
  Name = "OpenCTI"
  Product = "OpenCTI"
}
# Must match that of the OpenCTI Core deployment
resource_prefix = "CHANGEME"
# Name of the environment, e.g. dev
environment = "CHANGEME"
# Amount of days to retain logs
# Must be one of: 0 1 3 5 7 14 30 60 90 120 150 180 365 400 545 731 1827 3653
log_retention   = "30"
# Number of days that AWS Secrets Manager waits before it can delete the secret.
# This value can be 0 to force deletion without recovery or range from 7 to 30 days.
secrets_manager_recovery_window = 0

############################
# --       Other        -- #
############################

# This domain is used for connector account emails
# In the form: {container_name}@{email_domain}
# See `connectors.tf`.
email_domain = "example.com"
# This URL is used to call the OpenCTI API to create
# connector accounts. If you didn't specify an environment/subdomain/domain
# in the OpenCTI core deployment, use the public
# load balancer url, otherwise use: https://{subdomain}.{environment}.{domain}
opencti_url  = "https://opencti.dev.example.com"

############################
# -- OpenCTI Deployment -- #
############################
# -- OpenCTI -- #
opencti_version           = "5.3.15"
# Use the outputted Internal Load Balancer information from the Core OpenCTI deployment.
# For example:
# http://resource-prefix-nlb-xxxxxxxxxxxxxxxx.elb.us-east-2.amazonaws.com:4000
opencti_platform_url      = "CHANGEME"
