<h1 align="center">
  OpenCTI AWS Deployment
</h1>

<p align="center">
A Terraform deployment of OpenCTI designed to make use of native AWS Resources (where feasible). This includes AWS ECS Fargate, AWS OpenSearch, AWS ElastiCache for Redis and AWS S3 (through a Gateway Endpoint).
</p>


> **Note**
> This deployment is designed to help with OpenCTI Platform adoption. QinetiQ does not offer warranty on usage of this deployment. It is highly recommended to understand AWS, Terraform and Docker and if used within a production environment, perform an analysis of the deployment's security.

## Requirements
This deployment requires
- Terraform AWS Provider Version `~> 4.29.0`
  - This is to make use of AWS EBS GP3 volumes, an important requirement to OpenCTI Platform performance.
- Terraform Version `>= 1.2.6`
- OpenCTI Platform Version `>= 5.3.8`
  - This deployment uses IAM Roles and AWS S3 Gateway Endpoint which requires the recent `aws-sdk` implementation that has been merged. Hence, `ROLLING` can be used temporarily.


## Key Features
- Regionally resilient with auto recovery capabilities

- Autoscaling OpenCTI Worker through AWS Lambda interacting with RabbitMQ metrics

- [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html) Jump Box solution to avoid SSH Keys

- Security conscious design

- OpenID Connect Implementation

- Scheduled Connectors capability (discussed in the OpenCTI Platform Connectors folder)

## High-Level Architecture
![OpenCTI Architecture](/assets/OpenCTI%20Architecture.png)

## Guidance

This Terraform deployment consists of two parts; deploying the core OpenCTI Platform and separately deploying the OpenCTI Connectors. This is to avoid the issue of redeploying the same Terraform deployment twice as OpenCTI Connectors should make use of their own OpenCTI User Account.

Design decisions for each deployment are covered within the respective folder's `README`.

## OpenCTI URLs
- [OpenCTI Page](https://www.opencti.io/)
- [OpenCTI Demo](https://demo.opencti.io/)
- [OpenCTI GitHub](https://github.com/OpenCTI-Platform/opencti)
- [OpenCTI Slack](https://slack.luatix.org/)

#### Terraform Initialize
```sh
terraform init
```
Or in the case of using an S3 bucket to store Terraform State files.
1) Uncomment in `versions.tf` `lines 8 - 10` to enable backend configuration and configure in `./config/dev/backend.conf` the S3 bucket.
```sh
terraform init --backend-config=./config/dev/backend.conf
```

#### Terraform Deploy
```sh
terraform apply -var-file=config/dev/variables.tfvars
```

## Terraform Tools
#### checkov

> **Note**: When running checkov, it will fire a warning regarding an AWS WAF missing from the Application Load Balancer in the main OpenCTI Platform deployment. This is a resource you will need to add to this Terraform deployment.

Checkov is a tool used for checking static Terraform code against best security practices. To run locally, [install checkov](https://www.checkov.io/2.Basics/Installing%20Checkov.html) and then run `checkov -d . --var-file=config/dev/variables.tfvars` within either deployment.

#### tflint

tflint checks Terraform code against style guidelines. To run locally, [install tflint](https://github.com/terraform-linters/tflint), then run `tflint --init` and `tflint`.

## License
This code is released under the Apache2 License. See LICENSE.