#!/bin/bash

aws s3api list-buckets | fgrep -q servian-tech-app-jesse-

if [[ $? -eq 0 ]]; then
  echo >&2 "bucket already exists, skipping creation..."
  exit 1
fi;

BUCKET_NAME=servian-tech-app-jesse-$(date +"%s")
aws s3api create-bucket --bucket ${BUCKET_NAME} --region ap-southeast-2 --create-bucket-configuration LocationConstraint=ap-southeast-2
sed "s/bucket.*/bucket  = \"${BUCKET_NAME}\"/" -i infra/provider.tf
