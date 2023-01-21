#!/bin/bash
set -e

# This script will store all functions and arguments for the 
# service connect demo

# NOTE: POSIX syntax does not use function and mandates the use of parenthesis 

# Get outputs from Cloudformation deployment
getOutput () {
    echo $( \
    aws cloudformation --region ${AWS_DEFAULT_REGION} \
    describe-stacks --stack-name yelb-serviceconnect \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text)
}

# Progress Spinner
spinner () {
local pid=$! 
while ps -a | awk '{print $1}' | grep -q "${pid}"; do
   for c in / - \\ \|; do # Loop over the sequence of spinner chars.
      # Print next spinner char.
      printf '%s\b' "$c"

      sleep .1 # Sleep, then continue the loop.
   done
   done
}

# Linebreak carriage return
linebreak () {
   printf ' \n '
}

deleteCfnStack () {
   echo "Deleting '$1' CloudFormation Stack now..."
   echo "Please wait..."
   aws --profile "${AWS_PROFILE}" \
      --region "${AWS_DEFAULT_REGION}" \
      cloudformation delete-stack \
      --stack-name "$1" 

   aws --profile "${AWS_PROFILE}" \
      --region "${AWS_DEFAULT_REGION}" \
      cloudformation wait stack-delete-complete \
      --stack-name "$1" && echo "CloudFormation Stack '$1' deleted succcessfully."
}

# Environment Variables
# Namespace Records
export SERVICE_CONNECT_NS="yelb.sc.internal"
export CLOUD_MAP_NS="yelb.cloudmap.internal"
export PRIVATE_HOSTED_ZONE_DN="yelb.lb.internal"

# Service Names
export SVC_APPSERVER=yelb-appserver
export SVC_UI=yelb-ui
export SVC_REDIS=yelb-redis
export SVC_DB=yelb-db

# Current working directory set as source path
export SPATH=$(pwd)
