#!/bin/bash
set -e

# Requirements:
#  AWS CLI Version: 2.9.2 or higher

# source functions and arguments script
# must use . instead of 'source' for linux runs to support /bin/dash instead of /bin/bash
. ./scripts/env.sh

# Get deployed region
echo "Checking Cloudformation deployment region..."
AWS_DEFAULT_REGION=$(cat .region)
echo "Cloudformation deployment region found: ${AWS_DEFAULT_REGION}"

linebreak

# Get outputs from CFN Setup
export ecsName=$(getOutput 'ClusterName')
export appEndpoint=$(getOutput 'EcsLoadBalancerDns')
export privateSubnet1=$(getOutput 'PrivateSubnet1')

# Deploy Hey in Fargate
echo "Creating ECS Fargate Task for Load Test using Hey..."
aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation deploy \
    --stack-name "hey-loadtest" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --template-file "${SPATH}/iac/load-test-cfn.yaml" \
    --parameter-overrides \
    EnvironmentName="${ENVIRONMENT_NAME}" \
    URL="${appEndpoint}/api/getvotes"

linebreak

# Run Task
echo "Running Hey Loadtest with 100 workers and 10,000 requests for 2 minutes..."
aws ecs run-task --region "${AWS_DEFAULT_REGION}" \
    --cluster ${ecsName} \
    --task-definition "yelb-loadtest" \
    --network-configuration "awsvpcConfiguration={subnets=[${privateSubnet1}],assignPublicIp=DISABLED}" \
    --count 1 \
    --launch-type FARGATE > /dev/null

linebreak

echo "Please wait..."
linebreak

sleep 120 &
spinner

echo "Hey Loadtest for: ${appEndpoint} complete!"

linebreak

echo "View the Amazon EC2 Load Balancer Console here: https://console.aws.amazon.com/ec2/home#LoadBalancers"
echo "Be sure to choose the correct region for your deployment."
