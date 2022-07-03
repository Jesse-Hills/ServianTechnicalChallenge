#!/bin/bash

aws --region ap-southeast-2 lambda invoke --function-name servian-init-db /dev/null
