#!/bin/bash
set -e

# Requirements:
#  AWS CLI Version: 2.9.2 or higher

# This script will store all functions and arguments for the 
# service connect demo

# NOTE: POSIX syntax does not use function and mandates the use of parenthesis 

# Get outputs from Cloudformation deployment
getOutput () {
    echo $(\
    aws cloudformation --region ${AWS_DEFAULT_REGION} \
    describe-stacks --stack-name yelb-serviceconnect \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text)
}

#  Get Service ID for AWS Cloud Map Namespaces
getServiceId () {
   export namespaceId=$(getNamespaceId)
   echo $(\
        aws --region ${AWS_DEFAULT_REGION} \
        servicediscovery list-services \
        --filters Name="NAMESPACE_ID",Values=$namespaceId,Condition="EQ" \
        --query "Services[*].Id" \
        --output text
    )
}

# Get Namespace ID for AWS Cloud Map Namespaces
getNamespaceId () {
   echo $(\
      aws --region ${AWS_DEFAULT_REGION} \
      servicediscovery list-namespaces \
      --query "Namespaces[?contains(Name, 'yelb.sc.internal')].Id" \
      --output text
   )
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

# Delete CFN Stack
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

# Drain Service Connect services from AWS Cloud Map
drainServiceConnect () {
   # Update YAML files enabled key to false for roll back
   sed -i.bak '/"enabled":/ s/"enabled":[^,]*/"enabled": 'false'/' sc-update/svc-db.json

   sed -i.bak '/"enabled":/ s/"enabled":[^,]*/"enabled": 'false'/' sc-update/svc-appserver.json

   sed -i.bak '/"enabled":/ s/"enabled":[^,]*/"enabled": 'false'/' sc-update/svc-redis.json

   sed -i.bak '/"enabled":/ s/"enabled":[^,]*/"enabled": 'false'/' sc-update/svc-ui.json

   # make directory to store created .bak files
   mkdir sc-update/bak/; mv sc-update/*.bak sc-update/bak/

   # # delete unnecessary files
   rm -rf sc-update/bak

   # Update services
   echo "Draining $SVC_DB..."
   aws ecs update-service \
      --region "${AWS_DEFAULT_REGION}" \
      --cluster $ecsName \
      --service $SVC_DB \
      --service-connect-configuration file://sc-update/svc-db.json >/dev/null

   echo "Draining $SVC_REDIS..."
   aws ecs update-service \
      --region "${AWS_DEFAULT_REGION}" \
      --cluster $ecsName \
      --service $SVC_REDIS \
      --service-connect-configuration file://sc-update/svc-redis.json >/dev/null

   echo "Draining $SVC_APPSERVER..."
   aws ecs update-service \
      --region "${AWS_DEFAULT_REGION}" \
      --cluster $ecsName \
      --service $SVC_APPSERVER \
      --service-connect-configuration file://sc-update/svc-appserver.json >/dev/null

   echo "Draining $SVC_UI..."
   echo "Please wait..."
   aws ecs update-service \
      --region "${AWS_DEFAULT_REGION}" \
      --cluster $ecsName \
      --service $SVC_UI \
      --service-connect-configuration file://sc-update/svc-ui.json >/dev/null
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
