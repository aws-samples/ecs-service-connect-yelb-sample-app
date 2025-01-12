#!/bin/bash
set -e

# This script will clean up the resources created by the CloudFormation template deployment.

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

echo "Getting AWS ECS Cluster Name..."
CLUSTER_NAME=$(getOutput 'ClusterName')
echo "Cluster ${CLUSTER_NAME} found!"

linebreak

# Clean up cloud map namespace services
. ./scripts/remove-service-connect.sh

linebreak

# Clean up remaining deployed infrastructure by deleting the Cloud Formation Stack and wait for the delete to complete
deleteCfnStack 'hey-loadtest'

linebreak

deleteCfnStack 'yelb-serviceconnect'

linebreak

deleteCfnStack 'yelb-ecr-repositories'

# Final cleanup of tmp files and restore any sc-update files to original state
rm -rf .region

git restore ./sc-update/svc-appserver.json
git restore ./sc-update/svc-db.json
git restore ./sc-update/svc-redis.json
git restore ./sc-update/svc-ui.json
