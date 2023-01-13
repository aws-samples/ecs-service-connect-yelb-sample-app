#!/bin/bash

# This script will store all functions and arguments for the 
# service connect demo

# Get outputs from Cloudformation deployment
function getOutput {
    echo $( \
    aws cloudformation --region ${AWS_DEFAULT_REGION} \
    describe-stacks --stack-name yelb-serviceconnect \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text)
}

# Progress Spinner
function spinner { 
   local pid=$!
   local spin='-\|/'
   local i=0
   while kill -0 $pid 2>/dev/null; do
      (( i = (i + 1) % 4 ))
      printf '\b%c' "${spin:i:1}"
      sleep .1
   done
   printf ' \r'
}

# Linebreak carriage return
function linebreak {
   printf ' \n '
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
