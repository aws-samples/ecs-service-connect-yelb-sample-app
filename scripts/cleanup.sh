#!/bin/bash

# This script will clean up the resources created by the CloudFormation template deployment.

# Requirements:
#  AWS CLI Version: 2.9.2 or higher

# source functions and arguments script
# must use . instead of 'source' for linux runs to support /bin/dash instad of /bin/bash
. ./scripts/env.sh

# Get deployed region
echo "Checking Cloudformation deployment region..."
AWS_DEFAULT_REGION=$(cat .region)
echo "Cloudformation deployment region found: ${AWS_DEFAULT_REGION}"

echo "Getting AWS ECS Cluster Name..."
CLUSTER_NAME=$(getOutput 'ClusterName')
echo "Cluster ${CLUSTER_NAME} found!"

linebreak

# Clean up service discovery
serviceDiscoveryCleanup 'yelb-db'
serviceDiscoveryCleanup 'yelb-redis'
serviceDiscoveryCleanup 'yelb-appserver'

linebreak

# Clean up remaining deployed infrastructure by deleting the Cloud Formation Stack and wait for the delete to complete
echo "Deleting hey-loadtest CloudFormation Stack now..."
echo "Please wait..."

deleteCfnStack 'hey-loadtest'

linebreak

echo "Deleting remaining yelb-serviceconnect CloudFormation Stack now..."
echo "Please wait..."

deleteCfnStack 'yelb-serviceconnect'

# Final cleanup of tmp files
rm -rf .region
