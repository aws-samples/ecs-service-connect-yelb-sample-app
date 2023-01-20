#!/bin/bash

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
      echo -n ' '
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

# Cleanup Service Discovery
serviceDiscoveryCleanup () {
    # Get Service ID
    serviceId=$(aws --region ${AWS_DEFAULT_REGION} \
    servicediscovery list-services \
    --query "Services[?contains(Name, '$1')].Id" \
    --output text)

   # now loop through the above array
    for service in $(echo $serviceId)
    do
        echo "Cleaning up Cloud Map entries for: $1"
        echo ""

        # Get Instance ID
        instanceId=$(aws --region ${AWS_DEFAULT_REGION} \
        servicediscovery list-instances \
        --service-id $service \
        --query "Instances[*].Id" \
        --output text)

        for instance in $(echo $instanceId)
        do
            dergisterInstance=$(\
               # Deregister Service Discovery Service
               aws --region ${AWS_DEFAULT_REGION} \
               servicediscovery deregister-instance \
               --service-id $service \
               --instance-id $instance \
               --output text > /dev/null
            ) 
               
            # deregister loop if first try fails
            dergisterInstance
            if  [ $? -ne 0 ]; then
               # retry
               dergisterInstance
            fi
        done

        echo "Please wait..."

        # Delete Service Discovery Service
        aws --region ${AWS_DEFAULT_REGION} \
        servicediscovery delete-service \
        --id $service \
        --output text > /dev/null
    done
}

deleteCfnStack () {
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
