#!/bin/bash

if [ -z $1 ]; then
  echo "Instance name as the first argument is needed"
  exit 1
fi

if [ "$1" == "list" ]; then
  aws ec2 describe-instances --query "Reservations[*].Instances[*].{PrivateIp:PrivateIpAddress,PublicIP:PublicIpAddress,Name:Tags[?Key=='Name']|[0].Value,
  Status:State.Name}"  --output table
  exit 0
fi

INSTANCE_NAME=$1

aws ec2 describe-spot-instance-requests --filters Name=tag:Name,Values=${INSTANCE_NAME} Name=state,Values=active --output table | grep InstanceId &>/dev/null

if [ $? -eq 0 ]; then
  echo "Instance already exists"
  exit 0
fi
AMI_ID=$(aws ec2 describe-images  --filters "Name=name,Values=Centos-7-DevOps-Practice" --output table | grep ImageId | awk '{print $4}')

aws ec2 run-instances --image-id ${AMI_ID} --instance-type t3.micro --instance-market-options "MarketType=spot,SpotOptions={SpotInstanceType=persistent,
InstanceInterruptionBehavior=stop}" --tag-specifications "ResourceType=spot-instances-request,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" "ResourceType=instance,
Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" &>/dev/null
echo "EC2 Instance created"

sleep 30

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests --filters Name=tag:Name,Values=${INSTANCE_NAME} Name=state,Values=active --output table | grep InstanceId | awk  '{print $4}')
echo "Instance id is ${INSTANCE_ID}"
IPADDRESS=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --output table | grep PrivateIpAddress | head -n 1 | awk '{print $4}')
echo "IP Address is ${IPADDRESS}"
sed -e "s/COMPONENT/${INSTANCE_NAME}/" -e "s/IPADDRESS/${IPADDRESS}/" record.json >/tmp/record.json
aws route53 change-resource-record-sets --hosted-zone-id Z10056041904PV3USAS19 --change-batch file:///tmp/record.json &>/dev/null

echo "DNS record created"

sed -i -e '/frontend/,+1 d' inv
echo "[${COMPONENT}]\n${IPADDRESS}" >>inv