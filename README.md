# axis-terraform-flask

Boilerplate for a project using React frontend with a Terraform controlled backend API.

## Tech
* Cloud - AWS ECS Fargate, Cloudfront, Route53, SSL Certificate
* API - Flask, Celery, Websockets
* Frontend - React

## Tools
* [Docker](https://www.docker.com/) - Container developer environment
* [Terraform](https://www.terraform.io/) - Cloud infrastructure 
* [direnv](https://direnv.net/) - Environment variable management
* [jq](https://stedolan.github.io/jq/) - JSON cli processor
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-macos.html) - AWS CLI tool (brew install awscli)

# AWS Terraform Creation

## Configure Environment

Setup domain that is already registered in AWS Route53 in env.dist: 
```bash
export PROJECT_DOMAIN="example.com"
```

## Bootstrap Terraform setup
Create AWS Terraform shared environment for shared state locking.  The file `backend_config.tf` is generated with Terraform setup information.  NOTE: 

Run from the terraform directory
```bash
$ cd terraform
terraform $ make bootstrap
```

## Create AWS Infrastructure
Terraform will create all the necessary resources on AWS.  Environment variables will be saved to the file `aws.env`, and the environment will need to be refreshed after running this step.  

NOTE: Run from the terraform directory
```bash
$ cd terraform
$ make init 
$ make plan 
$ make apply
```

If you recieve `InvalidViewerCertificate` the first time your run plan/apply, run terraform plan apply process a second time.   The SSL certificate needs to be validated when created and takes a bit of time.

```bash
$ make plan apply
```

# Site Deploy
Deploy the backend containers to the ECR and update the two services.  NOTE: Run from the root directory of the project
```bash
$ make dist-backend-build
$ make dist-backend-deploy
```

Deploy the frontend react app to a serverless cloudfront distribution
```
$ make dist-frontend-build
$ make dist-frontend-deploy
```
Get coffee...

# Destroy backend
Tear down and remove all AWS infastructure components.   NOTE: Run from the Terraform directory
```bash
$ cd terraform
$ make destroy
```
Get coffee...