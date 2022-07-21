ECR_TAG := default
AWS_ECR_URL := 499777336806.dkr.ecr.us-east-1.amazonaws.com
DEPLOY_IMAGE := $(AWS_ECR_URL)/nginx:$(ECR_TAG)

.PHONY: help
help:  ## Print the help documentation
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: package
package:  ## Packages/Builds the image
	cd docker && docker build -t $(DEPLOY_IMAGE) -f Dockerfile .

.PHONY: publish
publish:  ## Publishes the image to ECR
	aws ecr get-login-password --region us-east-1 --profile pjaudiomv | docker login --username AWS --password-stdin $(AWS_ECR_URL)
	docker push ${DEPLOY_IMAGE}
	@echo "DOCKER TAG: " $(ECR_TAG)
