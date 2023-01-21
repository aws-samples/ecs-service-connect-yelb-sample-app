# !/bin/bash
set -e

# source functions and arguments script
# must use . instead of 'source' for linux runs to support /bin/dash instad of /bin/bash
. ./scripts/env.sh

# Get deployed region
echo "Checking Cloudformation deployment region..."
AWS_DEFAULT_REGION=$(cat .region)
echo "Cloudformation deployment region found: ${AWS_DEFAULT_REGION}"

linebreak

# Get outputs from CFN Setup
export ecsName=$(getOutput 'ClusterName')

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

# Get Namespace ID
   namespaceId=$(\
      aws --region ${AWS_DEFAULT_REGION} \
      servicediscovery list-namespaces \
      --query "Namespaces[?contains(Name, 'yelb.sc.internal')].Id" \
      --output text
   )

# Get Service ID
    serviceId=$(\
        aws --region ${AWS_DEFAULT_REGION} \
        servicediscovery list-services \
        --filters Name="NAMESPACE_ID",Values=$namespaceId,Condition="EQ" \
        --query "Services[*].Id" \
        --output text
    )

    if [ -n "$serviceId" ]; then
        # Wait 5 min or 300 seconds to avoid deregistration delay: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#deregistration-delay

        sleep 300 && echo 'Amazon ECS Service Connect Drain Complete!'
    fi
