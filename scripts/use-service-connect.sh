#!/bin/bash
set -e

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

# Get outputs from CFN Setup
export ecsName=$(getOutput 'ClusterName')

# Update YAML files with AWS_DEFAULT_REGION argument
sed -i.bak 's/"awslogs-region": .*"/"awslogs-region": '\"${AWS_DEFAULT_REGION}\"'/g' sc-update/svc-db.json

sed -i.bak 's/"awslogs-region": .*"/"awslogs-region": '\"${AWS_DEFAULT_REGION}\"'/g' sc-update/svc-appserver.json

sed -i.bak 's/"awslogs-region": .*"/"awslogs-region": '\"${AWS_DEFAULT_REGION}\"'/g' sc-update/svc-redis.json

sed -i.bak 's/"awslogs-region": .*"/"awslogs-region": '\"${AWS_DEFAULT_REGION}\"'/g' sc-update/svc-ui.json

# make directory to store created .bak files
mkdir sc-update/bak/; mv sc-update/*.bak sc-update/bak/

# delete unnecessary files
rm -rf sc-update/bak

# Update services
echo "Updating $SVC_DB..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $ecsName \
    --service $SVC_DB \
    --service-connect-configuration file://sc-update/svc-db.json >/dev/null

echo "Updating $SVC_REDIS..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $ecsName \
    --service $SVC_REDIS \
    --service-connect-configuration file://sc-update/svc-redis.json >/dev/null

echo "Updating $SVC_APPSERVER..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $ecsName \
    --service $SVC_APPSERVER \
    --load-balancers "[]" \
    --service-connect-configuration file://sc-update/svc-appserver.json >/dev/null

echo "Updating $SVC_UI..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $ecsName \
    --service $SVC_UI \
    --service-connect-configuration file://sc-update/svc-ui.json >/dev/null && echo "Amazon ECS Service Connect migration complete!"
