#!/bin/bash
set -e

# This script will run a CloudFormation template deployment to deploy all the
# required resources into the AWS Account specified.

# Requirements:
#  AWS CLI Version: 2.9.2 or higher

# source functions and exports
# must use . instead of 'source' for linux runs to support /bin/dash instead of /bin/bash
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

# Get AWS Account ID and set it as environment variable
if [ -z "${AWS_ACCOUNT_ID}" ]; then
    echo "Getting AWS Account ID..."
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) || {
        echo "Failed to get AWS Account ID"
        exit 1
    }
fi

# Create the ECR repositories
echo "Creating ECR repositories"
aws --profile "${AWS_PROFILE}" \
    --region "${AWS_DEFAULT_REGION}" \
    cloudformation deploy \
    --stack-name "yelb-ecr-repositories" \
    --template-file "${SPATH}/iac/ecr-images.yaml" \

# Check for container runtime
if command -v docker &> /dev/null; then
    echo "Using Docker as container runtime"
    CONTAINER_CMD="docker"
elif command -v finch &> /dev/null; then
    echo "Using Finch as container runtime"
    CONTAINER_CMD="finch"
elif command -v podman &> /dev/null; then
    echo "Using Podman as container runtime"
    CONTAINER_CMD="podman"
elif command -v nerdctl &> /dev/null; then
    echo "Using Nerdctl as container runtime"
    CONTAINER_CMD="nerdctl"
else
    echo "No container runtime found. Please install Docker, Finch, Podman, or Nerdctl"
    exit 1
fi

# Login to ECR (required before pushing)
echo "Logging into Amazon ECR"
aws ecr get-login-password --region $AWS_DEFAULT_REGION | $CONTAINER_CMD login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

declare -A images=(
    ["mreferre/yelb-db:0.6"]="yelb-db"
    ["mreferre/yelb-ui:0.10"]="yelb-ui"
    ["mreferre/yelb-appserver:0.7"]="yelb-appserver"
    ["public.ecr.aws/docker/library/redis:5.0.14"]="redis"
    ["jldeen/hey-loadtest:1.0"]="hey-loadtest"
)

# Loop through the images
echo "Download the container images"
for source_image in "${!images[@]}"; do
    repo_name="${images[$source_image]}"
    target_image="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$repo_name:latest"

    echo "Processing $source_image -> $target_image"

    # Pull the image
    echo "Pulling $source_image..."
    $CONTAINER_CMD pull "$source_image"

    # Tag the image
    echo "Tagging as $target_image..."
    $CONTAINER_CMD tag "$source_image" "$target_image"

    # Push to ECR
    echo "Pushing to ECR..."
    $CONTAINER_CMD push "$target_image"

    echo "Completed processing $repo_name"
    echo "----------------------------------------"
done
echo "All images have been processed"

linebreak

# Deploy the infrastructure, service definitions, and task definitions WITHOUT ECS Service Connect
echo "Creating the Base Infrastructure"
aws --profile "${AWS_PROFILE}" \
    --region "${AWS_DEFAULT_REGION}" \
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

echo "Access your Yelb application here: ${appEndpoint}"
