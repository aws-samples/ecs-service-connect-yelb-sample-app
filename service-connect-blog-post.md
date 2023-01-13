# Migrate existing ECS services from service discovery to ECS Service Connect configured services

Jessica Deen, Principal Developer Advocate, ECS

At re:Invent 2022 in November of last year we announced a new Amazon Elastic Container Service (Amazon ECS) solution for service-to-service communication called ECS Service Connect. Amazon ECS Service Connect enables easy communication between microservices and across virtual private clouds (VPCs) by leveraging AWS Cloud Map namespaces and logical service names. This allows you to seamlessly distribute traffic between your ECS tasks without having to deploy, configure, and maintain load balancers.

Today's post will focus on how to migrate your existing ECS tasks from using service discovery and load balancers to using the new ECS Service Connect functionality.

## Overview of Solution

To demonstrate how easy it is to migrate your existing ECS services, we will use a sample YELB application hosted on GitHub [here](link-to-be-added). This sample application currently uses an internal load balancer and an alias record in a private hosted zone for service discovery. Below is an architectural diagram of the sample application:

![](images/service-discovery-architecture-overview.png)

## Walkthrough

For this sample migration to work, we will need the following resources:

- A VPC
- pair of public and private subnets spread across two availability zones
- an internet gateway, with a default route on the public subnets
- a pair of NAT gateways (one in each AZ)
- default routes for the NAT gateways in the private subnets
- IAM roles for the sample YELB application tasks and task execution roles
- Security groups for the YELB app service components
- Service discovery namespaces for the YELB app components
- 1 External Load Balancer and target groups to expose the YELB UI app
- 1 Internal Load Balancer and target groups to expose the YELB app server
- 1 ECS Cluster
- ECS service and ECS task definitions deployed

## Prerequisites

For this walk through, you will need the following pre-requisites:

- An AWS Account
- Access to a shell environment. This can be a shell running in an [AWS Cloud9 Instance](https://aws.amazon.com/cloud9/), [AWS CloudShell](https://aws.amazon.com/cloudshell/), or locally on your system.
- Your shell environment will need to have the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with version 2.9.2 or higher
- Your AWS CLI will need to have a profile [configured with access to the AWS account](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) you wish to use for this walk through

### Step 1: Setup Infrastructure and Deploy Sample App

Luckily, we have an AWS Cloudformation template available to help us provision the necessary infrastructure, service, and task deployments.

We created a simple setup script for you to use from the shell environment of your choice to deploy the provided CloudFormation template. The script takes 4 optional arguments:

1. `AWS_PROFILE`: Name of the AWS CLI profile you wish to use. If you do not provide a value `default` will be used.
2. `AWS_DEFAULT_REGION`: Default Region where Cloud Formation Resources will be deployed. If you do not provide a value `us-west-2` will be used.
3. `ENVIRONMENT_NAME`: Environment Name for ECS cluster. If you do not provide a value `ecs` will be used.
4. `CLUSTER_NAME`: Desired ECS Cluster Name. If you do not provide a value `yelb-cluster` will be used.

To use the setup script with all arguments, you would run the following command:

```sh
./scripts/setup.sh my-profile us-east-2 my-ecs-environment my-ecs-cluster
```

The setup script will take around 5 minutes to complete.

> Note: It may take some time for every service and task to come to a `RUNNING` state.

Once the deployment has completed successfully, you can navigate to the [AWS ECS Console](console.aws.amazon.com/ecs/v2/clusters) and visually verify all services and tasks are in the `RUNNING` state.

> Note: You will want to ensure you are viewing the ECS Console for the region you chose to deploy the CloudFormation Template.

You can also view the sample YELB application through the deployed elastic load balancer. Upon successful completion, the setup script will provide a URL for you to view your newly deployed YELB application. Below is an example of the sample application:

![](images/Yelb-example.png)

### Step 2. Generate Traffic for Internal Load Balancer

Now that we have our sample application and all required infrastructure deployed, we are ready to generate some traffic using the application endpoint. To do this, we created a simple `./scripts/generate-traffic.sh` script for you to use.

To use the provided `generate-traffic.sh` script, you would use the following command:

```sh

./scripts/generate-traffic.sh
```

Once the script completes, you will see a message similar to the following:

```sh
Successfully created/updated stack - hey-loadtest

 Running Hey Loadtest with 100 workers and 10,000 requests for 2 minutes...

 Please wait...

Hey Loadtest for: http://yelb-serviceconnect-319970139.us-east-2.elb.amazonaws.com/ complete!
View the EC2 Load Balancer Console here: https://console.aws.amazon.com/ec2/home#LoadBalancers
Be sure to choose the correct region for your deployment.
```

### Step 3: View Monitoring Metrics for Service Discovery and Internal Load Balancer

To view the traffic you just generated using the monitoring metrics tab in the EC2 Load Balancer dashboard, you can navigate to the provided URL: https://console.aws.amazon.com/ec2/home#LoadBalancers. Be sure to select the appropriate region for your deployment.

Once you are in the Load Balancers console, select the `serviceconnect-appserver` instance, which should have a DNS prefix name similar to `internal-serviceconnect-appserver-xxxx`. Below is an example:

![](images/lb-example-1.png)

From within the serviceconect-appserver page, you will then want to navigate to the “Monitoring” tab.

![](images/lb-example-monitoring-1.png)

From the monitoring tab, if you adjust the time options to a 1hr period, you should see spikes similar to the following example:

![](images/monitoring-spike-example.png)

### Step 4: Migrate to Service Connect

Great, now we are ready to migrate from service discovery to ECS Service Connect. After the migration is complete, the sample application architecture will look like this:

![](images/service-connect-migration-example.png)

For this migration example, we will be using the AWS CLI to update the 4 services that make up this sample YELB application.

To simply the commands needed, we have created a `./scripts/use-service-connect.sh` script for you to use.

To use the provided `use-service-connect.sh` script, you would use the following command:

```sh
./scripts/use-service-connect.sh
```

Once the script completes, you should see output similar to the following example:

```sh
Updating yelb-db...
Updating yelb-redis...
Updating yelb-appserver...
Updating yelb-ui...
Service Connect migration complete!
```

### Step 5: What changed?

Let’s break down what changed when we ran the `./scripts/use-service-connect.sh` script.

The real magic in the `use-service-connect.sh` script is in the `aws ecs update-service` command, specifically using the `--service-connect-configuration` flag.

If we take a look at the [AWS CLI Documentation for the ecs update-service command](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ecs/update-service.html), we can see the `--service-connect-configuration` flag is expecting a JSON structure.

> Note: You cannot use a YAML service connect configuration file at this time; it must be JSON.

If we cross reference that guidance with our script, you'll notice each command starting from line 32 and on, uses that flag with a json file referenced. Below is an example of the update service command for the YELB_DB service.

```sh
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $CLUSTER_NAME \
    --service $SVC_DB \
    --service-connect-configuration file://sc-update/svc-db.json >/dev/null
```

The `--service-connect-configuration` flag is referencing a `svc-db.json` file located in the `sc-update/` directory of the provided GitHub repo. If we take a look at the file, we can see line 2 has the key `enabled` set to a value of `true`. Below is an example of the same `svc-db.json` file:

```json
{
  "enabled": true,
  "namespace": "yelb.sc.internal",
  "services": [
    {
      "portName": "yelb-db",
      "clientAliases": [
        {
          "port": 5432,
          "dnsName": "yelb-db.yelb.cloudmap.internal"
        }
      ]
    }
  ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "ecs/serviceconnectdemo",
      "awslogs-region": "us-west-2",
      "awslogs-stream-prefix": "db-envoy"
    }
  }
}
```

From the sample code snippet above, we can also see the `dnsName` key on line 10 is still pointing to the load balancers service discovery id. In this example the load balancer service discovery name is `yelb-db.yelb.cloudmap.internal`.

If you want to see other examples, you may click through the svc json files in the `sc-update` directory to see the service connect configuration for each service.

### Step 6: View Monitoring Metrics for Internal Load Balancer for Service Connect

Once the migration is complete, navigate to the [ECS Console](console.aws.amazon.com/ecs/v2/clusters) and verify all the services and tasks are in the `RUNNING` state. This may take some time as the existing tasks will have to be stopped and the new tasks should come up as shown below:

![](images/services-example-1.png)

![](imgaes/../images/tasks-example-1.png)

Once all services and tasks are in the `RUNNING` state, go ahead and generate traffic for the application endpoint again using the `./generate-traffic.sh` script and the following command:

```sh
./scripts/generate-traffic.sh
```

Now, just as we did previously, let’s navigate to the EC2 Load Balancer console and choose the app server’s internal load balancer again. Under the monitoring tab, you should now notice the app server traffic is no longer served by the internal load balancer after the service migration from service discovery to service connect! This is evident by the requests dashboard not seeing any new traffic. Below is an example:

![](images/sc-monitoring-example.png)

## Cleaning Up

To avoid future charges, one final step to finish with this tutorial is to clean up what we created. To make it easier, we created a `./scripts/cleanup.sh` script for you to use.

To use the provided `cleanup.sh`, you would use the following command:

```sh
./scripts/cleanup.sh
```

## Conclusion

Congratulations! You just learned how to migrate from service discovery to the new ECS Service Connect!

## Author Bio
