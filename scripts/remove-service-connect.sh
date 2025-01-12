#!/bin/bash
set -e

# source functions and arguments script
# must use . instead of 'source' for linux runs to support /bin/dash instead of /bin/bash
. ./scripts/env.sh

# Get outputs from CFN Setup
export ecsName=$(getOutput 'ClusterName')
export serviceId=$(getServiceId)

if [[ $serviceId ]]; then
    echo "Draining AWS Cloud Map and Amazon ECS Service Connect instances..."
    drainServiceConnect
    while [ -n "$serviceId" ]; do
        serviceId=$(getServiceId) && sleep 15;
    done
    echo 'Amazon ECS Service Connect Drain Complete!'
fi
