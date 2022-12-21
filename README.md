# Service Connect Blog

## Setting up the base infrastructure

### Setting Env variables

```bash
export AWS_DEFAULT_REGION="us-west-2"
export ENVIRONMENT_NAME="ecs"

export CLUSTER_NAME="yelb-cluster"

export SERVICE_CONNECT_NS="yelb.sc.internal"
export CLOUD_MAP_NS="yelb.cloudmap.internal"
export PRIVATE_HOSTED_ZONE_DN="yelb.lb.internal"

export SVC_APPSERVER=yelb-appserver
export SVC_UI=yelb-ui
export SVC_REDIS=yelb-redis
export SVC_DB=yelb-db

export SPATH=$(pwd)
```

### Deploy the Yelb application without service connect

```bash
aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation deploy \
    --stack-name "yelb-serviceconnect" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --template-file "${SPATH}/base-infra-cfn.yaml" \
    --parameter-overrides \
    EnvironmentName="${ENVIRONMENT_NAME}" \
    YelbCloudMapDomain="${CLOUD_MAP_NS}" \
    HostedZoneDomainName="${PRIVATE_HOSTED_ZONE_DN}" \
    ClusterName="${CLUSTER_NAME}"
```


### Update Services to use Service Connect

```bash
aws ecs update-service --cluster $CLUSTER_NAME --service $SVC_DB --service-connect-configuration file://sc-update/svc-db.json

aws ecs update-service --cluster $CLUSTER_NAME --service $SVC_REDIS --service-connect-configuration file://sc-update/svc-redis.json

aws ecs update-service --cluster $CLUSTER_NAME --service $SVC_APPSERVER --service-connect-configuration file://sc-update/svc-appserver.json

aws ecs update-service --cluster $CLUSTER_NAME --service $SVC_UI --service-connect-configuration file://sc-update/svc-ui.json
```

### Cleanup

```bash
aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation delete-stack \
    --stack-name "${ENVIRONMENT_NAME}-base-infra" 

aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation wait stack-delete-complete \
    --stack-name "${ENVIRONMENT_NAME}-base-infra" 
```
