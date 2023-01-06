#!/bin/bash

# This script will clean up the resources created by the CloudFormation template deployment.

# Requirements:
#  AWS CLI Version: 2.9.2 or higher

# Overrides
# The name of the AWS CLI profile you wish to use
AWS_PROFILE=$1
AWS_PROFILE=${AWS_PROFILE:-default}

# The default region where the CloudFormation Stack and all Resources will be deployed
AWS_DEFAULT_REGION=$2
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}

# Clean up the deployed infrastructure by deleting the Cloud Formation Stack and wait for the delete to complete

echo "Deleting yelb-serviceconnect CloudFormation Stack now..."
echo "Please wait..."

aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation delete-stack \
    --stack-name "yelb-serviceconnect" 

aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation wait stack-delete-complete \
    --stack-name "yelb-serviceconnect" 

echo "CloudFormation Stack 'yelb-serviceconnect' deleted succcessfully."
