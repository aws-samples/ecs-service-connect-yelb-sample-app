# !/bin/bash

# The default region where the CloudFormation Stack and all Resources were deployed
AWS_DEFAULT_REGION=$1
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}

# Get YELB APP URL
export YELB_APP_URL=$(aws --region "${AWS_DEFAULT_REGION}" elbv2 describe-load-balancers --query 'LoadBalancers[?contains(DNSName, `yelb-serviceconnect`) == `true`].DNSName' --output text)

# Generate traffic
for i in `seq 1 200`; do curl $YELB_APP_URL/api/getvotes ; echo ; done

echo ""

echo "Traffic successfully generated for: $YELB_APP_URL"

echo ""

echo "View the EC2 Load Balancer Console here: https://console.aws.amazon.com/ec2/home#LoadBalancers"
echo "Be sure to choose the correct region for your deployment."
