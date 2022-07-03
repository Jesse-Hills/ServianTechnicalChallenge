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
