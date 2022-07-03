# ServianTechnicalChallenge

## Setup

### Prerequisites:
* awscli with AdministratorAccess credentials
* terraform CLI tool
* docker

### Steps:
1. Setup S3 Bucket for terraform state file storage
```bash
scripts/bucket.sh
```

2. Initialise ECR repo for ECS to use
```bash
cd infra/
terraform init -reconfigure
terraform apply -auto-approve -target=module.ecr
```

3. Build and push modified version of app to ECR (issues with updatedb and AWS RDS - doesn't have pg_default tablespace)
```bash
cd ../app/
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account | sed 's/"//g')
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/servian-tech-app:latest .
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/servian-tech-app:latest
```

4. Stand up the rest of the infrastructure
```bash
cd ../infra/
terraform apply -auto-approve
```

5. Initialise the RDS instance for the app to use (might have to wait a bit for DB to be running)
```bash
cd ../scripts/
./updatedb.sh
```

6. Get the ALB dns endpoint and test app (may take a while for containers to be online)
```bash
cd ../infra/
terraform console
module.app.endpoint_url
```

## Deploy
If you have made changes to the app and would like to deploy you can do so by running the following script:
```bash
cd scripts/
./build_deploy.sh
```

## Architecture

### Frontend
The frontend is deployed to an ECS cluster with autoscaling enabled to scale based on CPU Utilization. It is made highly available by an application load balancer and network security is provided by segmenting the ALB, App and Database each into their own subnets (only ALB is public) with their own security groups restricting access to only what's required for the services to run.

### Database
The database is secured similarly to the App only allowing ingress access from the App itself and is also highly available as it is provisioned as a multi-az RDS instance.

### CI/CD (Not Implemented)
This could be implemented using GitHub actions by including yml files in a ```.github/workflows/``` directory. Jobs could be setup to perform different tasks (ie, update/deploy IaC, build/deploy App). To check for success or failure of the pipeline a job could be added to check the status of all other jobs and could be configured to post the results to a channel in slack/discord/etc.

### Security (Improvements Needed)
Terraform state is stored encrypted in an S3 bucket and any outputs containing secrets are marked as sensitive.

## Improvements

### CI/CD
It could be implemented.

### Database
The process to initialise it could be improved/automated as part of the deployment.

### Security
IAM permissions could be reviewed to ensure least privilege.
There are a couple of options for improving database security (currently has password stored in ECS/Lambda env vars):
1. Use secrets manager to store and rotate the password (would require updating app to pull password from secrets manager for Lambda - ECS can get valueFrom and given the secrets ARN)
2. Implement RDS IAM authentication (would require updating app code to get the temporary credentials - might be problematic for long running tasks like ECS if the connection drops logic would have to be included to grab new temporary credentials)
