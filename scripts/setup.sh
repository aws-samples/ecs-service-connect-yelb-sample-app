#!/bin/bash
set -e

# This script will run a CloudFormation template deployment to deploy all the
# required resources into the AWS Account specified.

# Requirements:
# AWS CLI Version 2.9.2 or higher
#

# source functions and exports
# must use . instead of 'source' for linux runs to support /bin/dash instad of /bin/bash
. ./scripts/env.sh

# Arguments
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

linebreak

# store region for future use
echo "$(getOutput 'Region')" > .region

# get ELB output
appEndpoint=$(getOutput 'EcsLoadBalancerDns')

echo "Access your YELB application here: ${appEndpoint}"
