.PHONY: bootstrap s3_bucket dynamodb_table export_config

PROJECT_NAME=axis-flask
PROJECT_DEVELOPER = ${USER}
REGION=us-east-1
CFG_FILENAME=backend_config.tf
BUCKET_NAME="terraform-tfstate-${PROJECT_NAME}"
LOCK_TABLE_NAME=terraform_locks

TF_WORKSPACE=$(shell terraform workspace show)
TF_PLAN_FILE=plans/plan-${TF_WORKSPACE}.tfplan

bootstrap: s3_bucket dynamodb_table export_config

s3_bucket:
	@aws s3api create-bucket \
		--region "${REGION}" \
		--acl private \
		--bucket "${BUCKET_NAME}"
	@aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled		

dynamodb_table:
	@aws dynamodb create-table \
		--region "${AWS_DEFAULT_REGION}" \
		--table-name ${LOCK_TABLE_NAME} \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

# certificate:
# 	aws acm request-certificate \
# 		--region us-east-1 \
# 		--domain-name "*.${PROJECT_DOMAIN}" \
# 		--subject-alternative-names "${PROJECT_DOMAIN}" \
# 		--validation-method DNS
		
export_config:
	@echo Saving backend config to ${CFG_FILENAME}...
	@echo "terraform {\n  backend \"s3\" {" > ${CFG_FILENAME}
	@echo "    bucket         = \"${BUCKET_NAME}\"" >> ${CFG_FILENAME}
	@echo "    key            = \"terraform.tfstate\"" >> ${CFG_FILENAME}
	@echo "    region         = \"${REGION}\"" >> ${CFG_FILENAME}
	@echo "    dynamodb_table = \"${LOCK_TABLE_NAME}\"" >> ${CFG_FILENAME}
	@echo "  }\n}" >> ${CFG_FILENAME}

init:
	@terraform get --update=true
	@terraform init
	#@terraform validate	

plan:
	terraform plan -var domain_name=${PROJECT_DOMAIN} -no-color -out ${TF_PLAN_FILE} | tee ${TF_PLAN_FILE}.plan.log

apply:
	terraform apply -no-color --auto-approve ${TF_PLAN_FILE} | tee ${TF_PLAN_FILE}.apply.log

destroy:
#	terraform plan -lock=false -no-color -destroy -out ${TF_PLAN_FILE} | tee ${TF_PLAN_FILE}.plan.log
#	terraform apply -lock=false -no-color --auto-approve ${TF_PLAN_FILE} | tee ${TF_PLAN_FILE}.destroy.log
	terraform plan -var domain_name=${PROJECT_DOMAIN}  -lock=true -no-color -destroy -out ${TF_PLAN_FILE} | tee ${TF_PLAN_FILE}.plan.log
	terraform apply  -lock=true -no-color --auto-approve ${TF_PLAN_FILE} | tee ${TF_PLAN_FILE}.destroy.log

release_lock:
	terraform force-unlock $(lockID)

graph:
	@terraform graph > graph.dot
	@cat graph.dot | docker run --rm -i attosol/dot2png > graph.png