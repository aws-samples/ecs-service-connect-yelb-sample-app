#!/bin/bash

# This script will clean up the resources created by the CloudFormation template deployment.

# Requirements:
#  AWS CLI Version: 2.9.2 or higher

# source functions and arguments script
source ./scripts/env.sh

# Get deployed region
echo "Checking Cloudformation deployment region..."
AWS_DEFAULT_REGION=$(cat .region)
echo "Cloudformation deployment region found: ${AWS_DEFAULT_REGION}"

linebreak

# Clean up the deployed infrastructure by deleting the Cloud Formation Stack and wait for the delete to complete

echo "Deleting hey-loadtest CloudFormation Stack now..."
echo "Please wait..."

aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation delete-stack \
    --stack-name "hey-loadtest" 

aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation wait stack-delete-complete \
    --stack-name "hey-loadtest" && echo "CloudFormation Stack 'hey-loadtest' deleted succcessfully."

linebreak

echo "Deleting yelb-serviceconnect CloudFormation Stack now..."
echo "Please wait..."

aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation delete-stack \
    --stack-name "yelb-serviceconnect" 

aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation wait stack-delete-complete \
    --stack-name "yelb-serviceconnect" && echo "CloudFormation Stack 'yelb-serviceconnect' deleted succcessfully."

# Final cleanup of tmp files
rm -rf .region