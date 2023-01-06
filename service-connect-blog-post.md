# Migrate existing ECS services to ECS Service Connect configured services

At re:Invent 2022 in November of last year we announced a new Amazon Elastic Container Service (Amazon ECS) solution for service-to-service communication called ECS Service Connect. Amazon ECS Service Connect enables easy communication between microservices and across virtual private clouds (VPCs) by leveraging AWS Cloud Map namespaces and logical service names. This allows you to seamlessly distribute traffic between your ECS tasks without having to deploy, configure, and maintain load balancers.

Today's post will focus on how to migrate your existing ECS tasks from using service discovery and load balancers to using the new ECS Service Connect functionality.

### Step 1: Setup Infrastructure and Deploy Sample App

To demonstrate how easy it is to migrate your existing ECS services, we will use a sample YELB application hosted on GitHub [here](link-to-be-added). This sample application currently uses an internal load balancer and an alias record in a private hosted zone for service discovery. Below is an architectural diagram of the sample application:

![](images/service-discovery-architecture-overview.png)

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

Luckily, we have a cloud formation template available to help us provision the necessary infrastructure, service, and task deployments.

We created a simple setup script for you to use to deploy the provided CloudFormation template. The script takes 4 optional arguments:

1. `AWS_PROFILE`: Name of the AWS CLI profile you wish to use. If you do not provide a value `default` will be used.
2. `AWS_DEFAULT_REGION`: Default Region where Cloud Formation Resources will be deployed. If you do not provide a value `us-west-2` will be used.
3. `ENVIRONMENT_NAME`: Environment Name for ECS cluster. If you do not provide a value `ecs` will be used.
4. `CLUSTER_NAME`: Desired ECS Cluster Name. If you do not provide a value `yelb-cluster` will be used.

To use the setup script with all arguments, you would run the following command:

```sh
./scripts/setup.sh default-aws-profile us-east-2 my-ecs-environment my-ecs-cluster
```

The setup script will take around 5 minutes to complete.

Once the deployment has completed successfully, you can navigate to the [AWS ECS Console](console.aws.amazon.com/ecs/v2/clusters) and visually verify all services and tasks are in the `RUNNING` state.

Note: You will want to ensure you are viewing the ECS Console for the region you chose to deploy the CloudFormation Template.

You can also view the sample YELB application through the deployed elastic load balancer. Upon successful completion, the setup script will provide a URL for you to view your newly deployed YELB application. Below is an example of the sample application:

![](images/Yelb-example.png)

### Step 2. Generate Traffic for Internal Load Balancer

Now that we have our sample application and all required infrastructure deployed, we are ready to generate some traffic using the application endpoint. To do this, we created a simple `generate-traffic.sh` script for you to use. This script takes one optional argument `AWS_DEFAULT_REGION` where you can specify the you opted to deploy your CloudFormation template in the previous step.

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

For this migration example, we will be using the AWS CLI to update the 4 services that make up this sample YELB application. To simply the commands needed, we have created a `./use-service-connect.sh` script for you to use. The script takes two optional arguments.

2. AWS_DEFAULT_REGION: Default Region where Cloud Formation Resources will be deployed. If you do not provide a value `us-west-2` will be used.
3. CLUSTER_NAME: Desired ECS Cluster Name. If you do not provide a value `yelb-cluster` will be used.

Below is an example of how you would run the provided script using the `AWS_DEFAULT_REGION` argument but leaving the `CLUSTER_NAME` empty so the default `yelb-cluster` value is used:

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

### Step 5: What changed?

Let’s break down what changed when we ran the `./scripts/use-service-connect.sh` script.

The real magic in the `use-service-connect.sh` script is in the `aw secs update-service` command, specifically using the `--service-connect-configuration` flag.

If we take a look at the [AWS CLI Documentation for the ecs udpate-service command](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ecs/update-service.html), we can see the --service-connect-configuration flag is expecting a structure.

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
./scripts/generate-traffic.sh us-east-2
```

Now, just as we did previously, let’s navigate to the EC2 Load Balancer console and choose the app server’s internal load balancer again. Under the monitoring tab, you should now notice the app server traffic is no longer served by the internal load balancer after the service migration from service discovery to service connect! This is evident by the requests dashboard not seeing any new traffic. Below is an example:

![](images/sc-monitoring-example.png)

### Step 7: Clean Up

One final step to finish with this tutorial is to clean up what we created. To make it easier, we created a `cleanup.sh` script for you to use. The clean up script takes one argument for `AWS_PROFILE`. The default value is `default`, but if your AWS CLI profile name is different, you will want to set that accordingly. Below is an example of how you would run the clean up command using the `AWS_PROFILE` argument:

```sh
./scripts/cleanup default-aws-profile
```

Congratulations! You just learned how to migrate from service discovery to the new ECS Service Connect!
