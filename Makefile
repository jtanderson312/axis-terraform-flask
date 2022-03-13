PROJECT_NAME = axis-flask
AWS_REGISTRY = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com

-include aws.env

.PHONY: up down build rm shell status logs clean prod_build

up:
	@docker-compose -f docker-compose.local.yml up -d
	@$(MAKE) status

down:
	@docker-compose -f docker-compose.local.yml down -v --remove-orphans

build: down
	@docker-compose -f docker-compose.local.yml  build

rm:
	@docker-compose -f docker-compose.local.yml  rm

shell.web: 
	docker-compose -f docker-compose.local.yml exec web /bin/sh

shell.worker: 
	docker-compose -f docker-compose.local.yml exec worker /bin/sh

shell.api:
	docker-compose -f docker-compose.local.yml exec  --user root api /bin/sh

status:
	@docker-compose -f docker-compose.local.yml ps

logs:
	@docker-compose -f docker-compose.local.yml logs --tail=100 -f
	# @docker-compose logs --tail=100 -f api

logs.api:
	@docker-compose -f docker-compose.local.yml logs --tail=100 -f api

logs.worker:
	@docker-compose -f docker-compose.local.yml logs --tail=100 -f worker

update.locks:
	@docker-compose -f docker-compose.local.yml cp api:/app/Pipfile.lock ./apps/api
	@docker-compose -f docker-compose.local.yml cp worker:/queue/Pipfile.lock ./apps/worker
	@docker-compose -f docker-compose.local.yml cp web:/usr/src/app/yarn.lock ./apps/web
	
clean:
	@docker container prune -f
	@docker image prune -f

dist-backend-build:
	@docker-compose -f docker-compose.prod.yml build 

dist-backend-deploy: dist-backend-build
	@eval `aws ecr get-login --no-include-email --region $(AWS_DEFAULT_REGION)`
	@docker tag axis-flask/api-prod:latest ${AWS_REGISTRY}/axis-flask-api:latest
	@docker tag axis-flask/worker-prod:latest ${AWS_REGISTRY}/axis-flask-worker:latest
	@docker push ${AWS_REGISTRY}/axis-flask-api:latest
	@docker push ${AWS_REGISTRY}/axis-flask-worker:latest
	@aws ecs update-service --region $(AWS_DEFAULT_REGION) --cluster $(AWS_CLUSTER_NAME) --service 'axis-flask-api'	
	@aws ecs update-service --region $(AWS_DEFAULT_REGION) --cluster $(AWS_CLUSTER_NAME) --service 'axis-flask-worker'	

dist-frontend-build:
	@cd apps/web && \
	rm -rf build/* && \
	yarn build

dist-frontend-deploy: dist-frontend-build
	@aws s3 sync apps/web/build/ s3://${AWS_FRONTEND_BUCKET} --delete
	aws cloudfront create-invalidation --distribution-id ${AWS_FRONTEND_DIST_ID} --paths '/*'

