<h1 align="center">
  Core OpenCTI Platform AWS Deployment
</h1>

<p align="center">
A deployment of the OpenCTI Platform and its main dependencies into AWS across 3 Availability Zones.
</p>

## Deployment

> **Note**
> Review the `/config/dev/variables.tfvars` file for each deployment to ensure the OpenCTI Platform is configured as expected. This includes setting the correct regional values such as the `aws_account_id_lb_logs` defined on `Line 15` in `variables.tfvars`. Ensure that the `backend.conf` and `provider.tf` are both set to the correct AWS Region.

## Guidance
This deployment, as it stands, will deploy the core OpenCTI Platform but there are additional components that can be added.

> **Note**
> - AWS Lambda is deployed as a private resource in a VPC. This can lead to longer resource delete times (~27mins). This is expected.
> - The OpenCTI Platform master user credentials can be found in AWS Secrets Manager post deployment.


### Route 53 Integration
Terraform code exists within this deployment (`load_balancing module`) that will make use of an existing Route53 Hosted Zone. The Route53 Hosted Zone value is configured by the `domain` Terraform variable in `variables.tfvars`. This will create a sub-domain of `https://opencti.domain`.

To enable this Terraform code, the following adjustments need to be made:
- In the `load_balancing` module, lines `47 - 48` are to be uncommented and lines `27 - 28 and 45 - 46` should be adjusted to the suggested values.
- Lines `91 - 130` should be uncommented.

### OpenID Connect Integration

OpenID Connect has been setup to authenticate inbound users on the public Application Load Balancer Endpoint and on the public OpenCTI Platform instance. This is to ensure that before a user can interact and be assigned permissions on the underlying platform, they will be authenticated at the Application Load Balancer Endpoint.

This requires having an Identity Provider Application setup prior to testing this code.

To enable this, the following adjustments need to be made:
- Configuration of the variables `opencti_openid_mapping_config` and `oidc_information`.
- Lines `49 - 62` of the `load_balancing` module should be uncommented.
- Lines `162 - 221` of the `ecs_opencti/opencti_platform` module should be uncommented and moved into the `environment` section of the ECS Task Definition.

In the case of setting up OpenID Connect, OpenCTI documentation can be found [here](https://luatix.notion.site/Configuration-a568604c46d84f39a8beae141505572a#896e296f1efb46a985048914fbe29e45).

It is worth noting:
- OpenCTI Platform can authorize a user either through the ID Token or Access Token.
- OpenCTI offers two authorization capabilities, OpenCTI Groups (TLP Levels) and OpenCTI Roles.
  - OpenCTI Roles are configured by `ROLES_MANAGEMENT` and OpenCTI Groups by `GROUPS_MANAGEMENT`.
  - Within each config option, the following are defined.
    - `SCOPE` represents additional `scopes` to be requested.
    - `PATH` represents where the information in the ID or Access Token can be found when performing mappings.
    - `MAPPING` represents an escaped list that will map an OpenID Connect attribute to OpenCTI Groups/Roles.
- When identifying the `PATH` value, setting the OpenCTI Platform to `debug` mode can help.


### ElastiCache Redis Trimming

Within OpenCTI, a configuration environment variable is setup to ensure that the OpenCTI Platform does not use up all of Redis' available memory. This is an effective solution but there have been a few edge cases where an alternative outcome has occurred. If a stage is reached where Redis' memory is full, the OpenCTI Platform will stop. This is an unlikely scenario but the quickest remediation possible requires connecting to ElastiCache Redis using the AWS SSM Jump Box.

When authenticated to Redis, the following commands can help to remove redundant information from Redis.

```
> SCAN 0 TYPE stream
> XLEN stream.opencti
> XTRIM stream.opencti MAXLEN 200000 # Or lower than 200000
```


### AWS SES SMTP

OpenCTI offers a subscription solution to send out emails based on events within OpenCTI. This has not been configured in this deployment as it requires a set of AWS SES SMTP credentials to be setup using an IAM User and verifying identities within AWS SES.

Once these configuration steps have been completed, setting up SMTP is straightforward. Following best practices, creating a Secret in Secrets Manager to house the credentials and then pulling this information in the ECS Fargate Task definition from Secrets is recommended.

The required environment variables can be found within OpenCTI [documentation](https://luatix.notion.site/Configuration-a568604c46d84f39a8beae141505572a#896e296f1efb46a985048914fbe29e45).


### OpenCTI Platform Autoscaling

Autoscaling of the ECS Fargate Service that houses the OpenCTI Platform is not defined. The variables required for such an autoscaling capability are available however, this has not been implemented as dedicated instances for Public and Private access are setup and should be sufficient for a typical deployment.

## Design Decisions

### AWS MQ RabbitMQ v AWS ECS Fargate RabbitMQ (w EFS)

AWS MQ RabbitMQ is a possible solution to be used with an OpenCTI deployment as it's AWS managed however, it does come with design and cost limitations.

The smallest instance AWS currently offer for AWS MQ (that meets the required specifications for OpenCTI) is feasible but AWS lists this option as having 'Low Network' performance. This could **potentially** present an issue in deployments where high amounts of data are ingested consistently.

Options that overcome this **potential** limitation make use of 'High Networking' and are backed by an EBS volume. The compute resources offered at this stage are more than sufficient for OpenCTI but do come with a cost. The instance will cost $0.288 to run per hour, coming to ~$200 a month. Furthermore, neither solution support a regionally resilient deployment without moving to a cluster deployment which is expensive (reaching over $5000 annually).

Therefore, the option chosen for this solution is AWS ECS Fargate with an EFS volume. This looks to meet the benefits offered by both the above options; improved networking, manageable costs and regional resiliency through an EFS volume. If an alternative deployment is chosen, creating a separate module would be straightforward to implement.

### AWS S3 v AWS ECS Fargate MinIO (w EFS)

MinIO is a non-native object storage solution for on-premise and cloud environments. This does present a significant overlap with AWS S3 and after the native AWS SDK was implemented in favour of the MinIO Client, AWS S3 is chosen.

### AWS OpenSearch v Elasticsearch Self-hosted

OpenCTI makes use of Elasticsearch. With this in mind, the decision between AWS OpenSearch and Elasticsearch comes down to a few factors:

- OpenCTI can leverage enhanced search capabilities of Elasticsearch 7.12+. AWS OpenSearch have released version [1.3](https://aws.amazon.com/about-aws/whats-new/2022/07/amazon-opensearch-service-supports-version-1-3/#:~:text=PPL%20now%20supports%20run%2Dtime%20fields) which supports `run-time` fields but this is awaiting an OpenCTI update to support this.
- Elasticsearch self-hosted requires Elasticsearch expertise to effectively manage and migrate between clusters.
- AWS OpenSearch has the ability to automatically transfer data between AWS OpenSearch clusters when scaling instance sizes.

In this deployment, AWS OpenSearch is chosen as it provides a simplified approach that adds to the goal of a low-management solution. However, it is recommended to have a baseline understanding of Elasticsearch. It may be the case in the future that AWS OpenSearch is no longer supported by OpenCTI.

> **Warning**
> It is important to correctly size AWS OpenSearch/Elasticsearch as the OpenCTI Platform makes a high number of queries per second when ingesting data from a new connector. This can lead to Index/Search Latency spikes that can harm the number of ingested bundles/second.
> AWS have recently released support for AWS EBS GP3 volumes which provide a much higher baseline of 3000 IOPs compared to the previous GP2 version of 3 IOPs per GB. This will help to resolve performance issues.
> If issues are still encountered, scaling the AWS OpenSearch data nodes up (to accommodate the expected increase in searches/indexing) can significantly help.
> More details can be found [here](https://aws.amazon.com/premiumsupport/knowledge-center/opensearch-indexing-performance/) and [here](https://www.elastic.co/guide/en/elasticsearch/reference/master/tune-for-indexing-speed.html).


> OpenCTI makes use of an `index pattern` that can be configured through environment variables. These are not documented fully but a list can be found at the following [link](https://github.com/OpenCTI-Platform/opencti/blob/e2078dc6b74a1c4250301c9d50944e06c8e11091/opencti-platform/opencti-graphql/src/database/engine.js#L76).
> This enables optimisation of the `opencti template` such as reducing the number of shards per index.
> If you are in a position where an index is becoming too large for the allocated shards, OpenCTI operates on an alias basis. Therefore, another index can be setup (e.g. opencti_stix_sighting_relationships-000001 --> 000002) and upon updating the Elasticsearch alias to point to the new index, OpenCTI will begin to push to the new index.
