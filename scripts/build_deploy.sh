#!/bin/bash

cd $(dirname $0)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/servian-tech-app:latest ../app/
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/servian-tech-app:latest
aws --region ap-southeast-2 ecs update-service --cluster ServianTechApp --service servian-tech-app --force-new-deployment
