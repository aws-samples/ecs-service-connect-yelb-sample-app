#!/bin/bash

# This script will run a CloudFormation template deployment to deploy all the
# required resources into the AWS Account specified.

# Requirements:
# AWS CLI Version 2.9.2 or higher
#

# Overrides
# The name of the AWS CLI profile you wish to use
AWS_PROFILE=$1
AWS_PROFILE=${AWS_PROFILE:-default}

# The default region where the CloudFormation Stack and all Resources will be deployed
AWS_DEFAULT_REGION=$2
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}

# Environment Name for the ECS cluster
ENVIRONMENT_NAME=$3
ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-ecs}

# ECS Cluster Name
CLUSTER_NAME=$4
CLUSTER_NAME=${CLUSTER_NAME:-yelb-cluster}

# Environment Variables
# Namespace Records
export SERVICE_CONNECT_NS="yelb.sc.internal"
export CLOUD_MAP_NS="yelb.cloudmap.internal"
export PRIVATE_HOSTED_ZONE_DN="yelb.lb.internal"

# Current working directory set as source path
export SPATH=$(pwd)

# Deploy the infrastructure, service definitions, and task definitions WITHOUT ECS Service Connect
aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation deploy \
    --stack-name "yelb-serviceconnect" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --template-file "${SPATH}/iac/base-infra-cfn.yaml" \
    --parameter-overrides \
    EnvironmentName="${ENVIRONMENT_NAME}" \
    YelbCloudMapDomain="${CLOUD_MAP_NS}" \
    HostedZoneDomainName="${PRIVATE_HOSTED_ZONE_DN}" \
    ClusterName="${CLUSTER_NAME}"

# Outputs
# Get the APP URL for the newly deployed YELB application and provide to user
echo

export YELB_APP_URL=$(aws --region "${AWS_DEFAULT_REGION}" elbv2 describe-load-balancers --query 'LoadBalancers[?contains(DNSName, `yelb-serviceconnect`) == `true`].DNSName' --output text)

echo "Access your YELB application here: http://${YELB_APP_URL}"
