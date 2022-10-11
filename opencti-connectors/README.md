<h1 align="center">
  OpenCTI Connectors AWS Deployment
</h1>

<p align="center">
An <strong>optional deployment</strong> for OpenCTI Connectors that makes use of existing OpenCTI Platform resources created in the previous deployment. <strong>It is important to read the below to understand the requirements of this deployment.</strong> It may be possible to make use of CloudFormation/Service Catalog products instead to setup OpenCTI Connectors.
</p>

## Design Decisions

OpenCTI ingests data through OpenCTI Connectors; each connector is designed to target a single source of data.

As OpenCTI Connectors **should** have dedicated User Accounts set up within OpenCTI Platform (to ensure a restriction of TLP content access and general permissions), the deployment of the OpenCTI Platform and OpenCTI Connectors have been segregated into two deployments. 

> **Note**: Currently OpenCTI do not build ARM64 Connector Images so X86_64 has to be used. This should be changed to ARM64 when supported to reduce cost.

## Deployment Requirements

> **Note**
> - awscli
> - terraform
> - Review the `/config/{YOUR_ENVIRONMENT}/variables.tfvars` file for each deployment to ensure correct configuration.
>   - To deploy this solution, the variable `resource_prefix` must be the same as that defined in the OpenCTI Platform deployment. In this example, it is set to `tf-opencti`.
>   - The `opencti_platform_url` variable in `variables.tfvars` must use the output value from the core OpenCTI deployment.
> - Ensure that the `backend.conf` and `provider.tf` are both set to the correct AWS Region.

#### Prerequisite Information
Prior to deploying OpenCTI Connectors, follow these steps:

> **Note**
> - It is recommended to set the `Connector` role as the default OpenCTI role for new accounts temporarily. In addition, 
you will want to create a group with access to marking definitions and set it as default as well. This ensures that as you deploy the Connectors, each user account corresponding to each connector, will, by default, use the Connector role and be in the group, so it can have the permissions required to run.

#### Adding Additional Connectors

Follow these steps to add additional connectors to OpenCTI:

1. Update `opencti-connectors/connectors.tf` with a module block for your connector.
2. Create a folder in `opencti-connectors/connectors` with the connector's template files.
3. Deploy.

> **Note**:
> Secret template files, i.e. secrets.hcl should not be committed to source control.
> Rather it is recommended to make use of secure credential storage through a pipeline or to deploy manually.
> Sample secret template files can be found in `opencti-connectors/connectors/*/secrets.hcl.sample`.

#### Deploying

To deploy, run the following commands:

- `terraform init`
- `terraform apply -auto-approve -var-file=./config/{YOUR_ENVIRONMENT}/variables.tfvars`

If the Scheduled Connector template (AWS EventBridge w Lambda) is used, then the `cron_job` variable must also be defined. As it stands, the Cron Job is setup to use the UTC Time Zone and cannot be changed due to AWS limitations.

> **Note**:
> If a connector is scheduled (i.e. with a CronJob) then it should match the configuration of that Connector (i.e. how often a Connector should run)

OpenCTI Connectors can be customised through environment variable and secret template files. See existing folders within `connectors` to learn more.
