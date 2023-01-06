# !/bin/bash

# The default region where the CloudFormation Stack and all Resources were deployed
AWS_DEFAULT_REGION=$1
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}

# ECS Cluster Name
CLUSTER_NAME=$2
CLUSTER_NAME=${CLUSTER_NAME:-yelb-cluster}

# Service Names
export SVC_APPSERVER=yelb-appserver
export SVC_UI=yelb-ui
export SVC_REDIS=yelb-redis
export SVC_DB=yelb-db

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
    --cluster $CLUSTER_NAME \
    --service $SVC_DB \
    --service-connect-configuration file://sc-update/svc-db.json >/dev/null

echo "Updating $SVC_REDIS..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $CLUSTER_NAME \
    --service $SVC_REDIS \
    --service-connect-configuration file://sc-update/svc-redis.json >/dev/null

echo "Updating $SVC_APPSERVER..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $CLUSTER_NAME \
    --service $SVC_APPSERVER \
    --service-connect-configuration file://sc-update/svc-appserver.json >/dev/null

echo "Updating $SVC_UI..."
aws ecs update-service \
    --region "${AWS_DEFAULT_REGION}" \
    --cluster $CLUSTER_NAME \
    --service $SVC_UI \
    --service-connect-configuration file://sc-update/svc-ui.json >/dev/null && echo "Service Connect migration complete!"
