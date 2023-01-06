# Deploying Sample YELB Appliction with Amazon ECS, AWS CloudFormation, and an Application Load Balancer

## Sample Application for Service Discovery to ECS Service Connect Migration

This repo was created in conjunction with the AWS Blog Post [Migrate Existing ECS Services to ECS Service Connect Configured Services](..)

This reference architecture provides an easy to use YAML template for deploying a sample YELB application using service discovery to [Amazon EC2 Container Service (Amazon ECS)](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html) with [AWS CloudFormation](https://aws.amazon.com/cloudformation/).

There are two ways you can launch the [CloudFormation stack](iac/base-infra-cfn.yaml) in your account.

1. You can use the provided [setup.sh](scripts/setup.sh) script located in the `scripts` folder.

To run the provided script, you will need to have the AWS CLI installed on your system, and the minimum required AWS CLI version is `2.9.2`.

The script takes 4 optional arguments:

1. `AWS_PROFILE`: Name of the AWS CLI profile you wish to use. If you do not provide a value `default` will be used.
2. `AWS_DEFAULT_REGION`: Default Region where Cloud Formation Resources will be deployed. If you do not provide a value `us-west-2` will be used.
3. `ENVIRONMENT_NAME`: Environment Name for ECS cluster. If you do not provide a value `ecs` will be used.
4. `CLUSTER_NAME`: Desired ECS Cluster Name. If you do not provide a value `yelb-cluster` will be used.

To use the setup script with all arguments in the `us-east-2` region, you would run the following command:

```sh
./scripts/setup.sh default-aws-profile us-east-2 my-ecs-environment my-ecs-cluster
```

The setup script will take around 5 minutes to complete.

2. You can also deploy the provided [CloudFormation template](iac/base-infra-cfn.yaml) by clicking the button next to the desired region below:

| AWS Region                | Short name     |                                                                                                                                                                                                                                                                                  |
| ------------------------- | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| US East (Ohio)            | us-east-2      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| US East (N. Virginia)     | us-east-1      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| US GovCloud               | us-gov-west-1  | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.amazonaws-us-gov.com/cloudformation/home?region=us-gov-west-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml) |
| US West (Oregon)          | us-west-2      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| US West (N. California)   | us-west-1      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| Canada (Central)          | ca-central-1   | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ca-central-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)        |
| EU (Paris)                | eu-west-3      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-3#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| EU (London)               | eu-west-2      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-2#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| EU (Ireland)              | eu-west-1      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |
| EU (Frankfurt)            | eu-central-1   | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)        |
| Asia Pacific (Seoul)      | ap-northeast-2 | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-northeast-2#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)      |
| Asia Pacific (Tokyo)      | ap-northeast-1 | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-northeast-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)      |
| Asia Pacific (Sydney)     | ap-southeast-2 | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)      |
| Asia Pacific (Singapore)  | ap-southeast-1 | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)      |
| Asia Pacific (Mumbai)     | ap-south-1     | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-south-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)          |
| South America (São Paulo) | sa-east-1      | [![cloudformation-launch-button](images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=sa-east-1#/stacks/new?stackName=yelb-serviceconnect&templateURL=https://s3.amazonaws.com/aws-sample-templates/base-infra-cfn.yaml)           |

## Overview

![infrastructure-overview](images/service-discovery-architecture-overview.png)

The repository consists of a single cloudformation template that deploys the following:

- A [VPC](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html) with public and private subnets.
- A highly available ECS cluster deployed across two [Availability Zones](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).
- A pair of [NAT gateways](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html) (one in each zone) to handle outbound traffic.
- Four microservices deployed as [ECS services](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) (yelb-ui, yelb-appserver, yelb-db, yelb-redis).
- An [Application Load Balancer (ALB)](https://aws.amazon.com/elasticloadbalancing/applicationloadbalancer/) to the public subnets to handle inbound traffic.
- ALB path-based routes for each ECS service to route the inbound traffic to the correct service.
- Internal Load Balancer used to handle internal traffic through a private hosted zone using Route 53.
- Centralized container logging with [Amazon CloudWatch Logs](http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html).
- ECS Service Definitions and Task Defintions for YELB-DB, YELB-Redis, YELB-Appserver, and YELB-UI.

## Why use AWS CloudFormation with Amazon ECS?

Using CloudFormation to deploy and manage services with ECS has a number of nice benefits over more traditional methods ([AWS CLI](https://aws.amazon.com/cli), scripting, etc.).

#### Infrastructure-as-Code

A template can be used repeatedly to create identical copies of the same stack (or to use as a foundation to start a new stack). Templates are simple YAML- or JSON-formatted text files that can be placed under your normal source control mechanisms, stored in private or public locations such as Amazon S3, and exchanged via email. With CloudFormation, you can see exactly which AWS resources make up a stack. You retain full control and have the ability to modify any of the AWS resources created as part of a stack.

#### Self-documenting

Fed up with outdated documentation on your infrastructure or environments? Still keep manual documentation of IP ranges, security group rules, etc.?

With CloudFormation, your template becomes your documentation. Want to see exactly what you have deployed? Just look at your template. If you keep it in source control, then you can also look back at exactly which changes were made and by whom.

#### Intelligent updating & rollback

CloudFormation not only handles the initial deployment of your infrastructure and environments, but it can also manage the whole lifecycle, including future updates. During updates, you have fine-grained control and visibility over how changes are applied, using functionality such as [change sets](https://aws.amazon.com/blogs/aws/new-change-sets-for-aws-cloudformation/), [rolling update policies](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html) and [stack policies](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html).

## How do I...?

### Change the VPC or subnet IP ranges

The provided [CloudFormation template](iac/base-infra-cfn.yaml) deploys the following network design:

| Item           | CIDR Range   | Usable IPs | Description                                        |
| -------------- | ------------ | ---------- | -------------------------------------------------- |
| VPC            | 10.0.0.0/16  | 65,534     | The whole range used for the VPC and all subnets   |
| Public Subnet  | 10.0.0.0/19  | 8,190      | The public subnet in the first Availability Zone   |
| Public Subnet  | 10.0.32.0/19 | 8,190      | The public subnet in the second Availability Zone  |
| Private Subnet | 10.0.64.0/19 | 8,190      | The private subnet in the first Availability Zone  |
| Private Subnet | 10.0.96.0/19 | 8,190      | The private subnet in the second Availability Zone |

You can adjust the CIDR ranges used in `Mappings:` section of the [iac/ base-infra-cfn.yaml](iac/base-infra-cfn.yaml) template. Below is an example:

```yaml
Mappings:
  # Hard values for the subnet masks. These masks define
  # the range of internal IP addresses that can be assigned.
  # The VPC can have all IP's from 10.0.0.0 to 10.0.255.255
  # There are four subnets which cover the ranges:
  #
  # 10.0.0.0 - 10.0.31.255
  # 10.0.32.0 - 10.0.63.255
  # 10.0.64.0 - 10.0.95.255
  # 10.0.96.0 - 10.0.127.255
  #
  # If you need more IP addresses (perhaps you have so many
  # instances that you run out) then you can customize these
  # ranges to add more
  SubnetConfig:
    VPC:
      CIDR: "10.0.0.0/16"
    Public1:
      CIDR: "10.0.0.0/19"
    Public2:
      CIDR: "10.0.32.0/19"
    Private1:
      CIDR: "10.0.64.0/19"
    Private2:
      CIDR: "10.0.96.0/19"
```

### Generate Load Balancer traffic for Internal Load Balancer

We created a simple `./scripts/generate-traffic.sh` script for you to use. This script takes one optional argument `AWS_DEFAULT_REGION` where you can specify the region you opted to deploy your CloudFormation template in the previous step.

To use the provided `generate-traffic.sh` script with the optional argument enabled for us-east-2, you would use the following command:

```sh

./scripts/generate-traffic.sh us-east-2
```

Note: Be sure to update the AWS_DEFAULT_REGION to the region you used with the `./scripts/setup.sh` script.

Once the script completes, you will see a message similar to the following:

```sh
[{"name": "outback", "value": 0},{"name": "bucadibeppo", "value": 0},{"name": "ihop", "value": 0}, {"name": "chipotle", "value": 0}]
[{"name": "outback", "value": 0},{"name": "bucadibeppo", "value": 0},{"name": "ihop", "value": 0}, {"name": "chipotle", "value": 0}]
[{"name": "outback", "value": 0},{"name": "bucadibeppo", "value": 0},{"name": "ihop", "value": 0}, {"name": "chipotle", "value": 0}]

Traffic successfully generated for: yelb-serviceconnect-1727720706.us-east-2.elb.amazonaws.com

View the EC2 Load Balancer Console here: https://console.aws.amazon.com/ec2/home#LoadBalancers:
Be sure to choose the correct region for your deployment.
```

### Migrate from Service Discovery to ECS Service Connect

To migrate from Service Discovery to ECS Service Connect you can run the provided `./scripts/use-service-connect.sh` script.

The script takes two optional arguments.

2. `AWS_DEFAULT_REGION`: Default Region where Cloud Formation Resources will be deployed. If you do not provide a value `us-west-2` will be used.
3. `CLUSTER_NAME`: Desired ECS Cluster Name. If you do not provide a value `yelb-cluster` will be used.

Below is an example of how you would run the provided script using the `AWS_DEFAULT_REGION` argument but leaving the `CLUSTER_NAME` argument empty so the default `yelb-cluster` value is used:

```sh
./scripts/use-service-connect.sh us-east-2
```

Once the script completes, you should see output similar to the following example:

```sh
Updating yelb-db...
Updating yelb-redis...
Updating yelb-appserver...
Updating yelb-ui...
Service Connect migration complete!
```

After the migration is complete, the sample application architecture will look like this:

![](images/service-connect-migration-example.png)

### Clean up

After you are done with the application and infrastructure deployed as part of the CloudFormation Template included in this repo, it is time to clean up.

To make it easier, we created a `cleanup.sh` script for you to use. The clean up script takes one argument for `AWS_PROFILE`. The default value is `default`, but if your AWS CLI profile name is different, you will want to set that accordingly. Below is an example of how you would run the clean up command using the `AWS_PROFILE` argument:

```sh
./scripts/cleanup default-aws-profile
```

### Add a new item to this list

If you found yourself wishing this set of frequently asked questions had an answer for a particular problem, please [submit a pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/). The chances are that others will also benefit from having the answer listed here.

## Contributing

Please [create a new GitHub issue](https://github.com/awslabs/ecs-refarch-cloudformation/issues/new) for any feature requests, bugs, or documentation improvements.

Where possible, please also [submit a pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/) for the change.

## License

MIT License

Copyright (c) 2022 Jessica Deen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
