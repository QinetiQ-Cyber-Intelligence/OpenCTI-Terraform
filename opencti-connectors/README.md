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
> - Review the `/config/dev/variables.tfvars` file for each deployment to ensure correct configuration.
>   - To deploy this solution, the variable `resource_prefix` must be the same as that defined in the OpenCTI Platform deployment. In this example, it is set to `tf-opencti`.
>   - The `opencti_connector_kms_arn` and `opencti_platform_url` values in `variables.tfvars` must use the outputted values from the core OpenCTI deployment.
> - Ensure that the `backend.conf` and `provider.tf` are both set to the correct AWS Region.

#### Prerequisite Information
Prior to deploying OpenCTI Connectors, you will need to make sure that all the required Secret Placeholders for API Tokens are created. The OpenCTI Platform deployment has a variable `opencti_connector_names` that contains a list of OpenCTI Connectors that have such a Secret placeholder created for them. 

In the OpenCTI console, create a dedicated user account per connector with the correct permissions and within the corresponding AWS Secrets Manager Secret, store the API Key in the `apikey` field of the Secret.

Connectors that are deployed in this Terraform deployment are then restricted through IAM Policies that only grant access to the Secret that is named with their `opencti_connector_name` value.

#### Deploying
Within this Terraform deployment, the configurations for the external import `OpenCTI`, `Mitre` and `CVE` variables have been added. This is to enable you to progressively understand the process in place for deploying connectors.

There are a minimum of 2 variables that are required for each connector deployment:
- `connector_image` - the name and location of the Docker Image to be used
- `connector_name`  - the general name assigned to that connector
  - This follows the convention of `connector_type + connector_name` e.g. `external-import-opencti`

If the Scheduled Connector template (AWS EventBridge w Lambda) is used, then the `cron_job` variable must also be defined. As it stands, the Cron Job is setup to use the UTC Time Zone and cannot be changed due to AWS limitations.

> **Note**:
> If a connector is scheduled (i.e. with a CronJob) then it should match the configuration of that Connector (i.e. how often a Connector should run)

OpenCTI Connectors can be customised through environment variables. The OpenCTI Connector configuration data is stored within the `resources/container_env_definitions` folder. Note that these connector definitions do not include the `OPENCTI_TOKEN` value as this is passed through by AWS Secrets Manager.
