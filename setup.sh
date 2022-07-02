#!/bin/bash

BUCKET_NAME=servian-tech-app-$(date +"%s")

aws s3api create-bucket --bucket ${BUCKET_NAME} --region ap-southeast-2 --create-bucket-configuration LocationConstraint=ap-southeast-2

sed "s/bucket.*/bucket  = \"${BUCKET_NAME}\"/" -i infra/provider.tf
