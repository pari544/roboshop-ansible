#!/bin/bash

if [ -z "$1" ]; then
  echo "Instance Name as argument is needed"
  exit 1
fi

if [ -z "$2" ]; then
  echo "ENV as argument is needed"
  exit 1
fi

if [ "$1" == "list" ]; then
  aws ec2 describe-instances  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}"  --output table
  exit 0
fi

NAME=$1
ENV=$2

aws ec2 describe-spot-instance-requests --filters Name=tag:Name,Values=${NAME}-${ENV} Name=state,Values=active --output table | grep InstanceId &>/dev/null
if [ $? -eq 0 ]; then
  echo "Instance Already exists"
else
  AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=Centos-7-DevOps-Practice" --output table  | grep ImageId | awk '{print $4}')
  aws ec2 run-instances --image-id ${AMI_ID} --instance-type t3.micro --instance-market-options "MarketType=spot,SpotOptions={SpotInstanceType=persistent,InstanceInterruptionBehavior=stop}" --tag-specifications "ResourceType=spot-instances-request,Tags=[{Key=Name,Value=${NAME}-${ENV}}]" "ResourceType=instance,Tags=[{Key=Name,Value=${NAME}-${ENV}}]" --security-group-ids   aws ec2 run-instances --image-id ami-0bb6af715826253bf --instance-type t3.micro --instance-market-options "MarketType=spot,SpotOptions={SpotInstanceType=persistent,InstanceInterruptionBehavior=stop}" --tag-specifications "ResourceType=spot-instances-request,Tags=[{Key=Name,Value=${NAME}-${ENV}}]" "ResourceType=instance,Tags=[{Key=Name,Value=${NAME}-${ENV}}]" --security-group-ids sg-0856919658d8bb085 &>/dev/null
  echo EC2 Instance Created
  sleep 30
fi

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests --filters Name=tag:Name,Values=${NAME}-${ENV} Name=state,Values=active --output table | grep InstanceId | awk '{print $4}')

IPADDRESS=$(aws ec2 describe-instances  --instance-ids ${INSTANCE_ID}  --output table | grep PrivateIpAddress | head -n 1 | awk '{print $4}')

sed -e "s/COMPONENT/${NAME}-${ENV}/" -e "s/IPADDRESS/${IPADDRESS}/" record.json >/tmp/record.json
aws route53 change-resource-record-sets --hosted-zone-id Z10056041904PV3USAS19 --change-batch file:///tmp/record.json &>/dev/null
echo DNS Record Created

touch inv
sed -i -e "/${NAME}/,+1 d" inv
echo -e "[${NAME}]\n${IPADDRESS}" >>inv


