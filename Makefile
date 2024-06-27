SHELL := /bin/bash

export AWS_PROFILE=souyang

example:
	@mkdir -p examples/${CASE}
	@cd examples/${CASE} \
		&& touch ${CASE}

test:
	@cd examples \
	&& terraform init -upgrade \
	&& terraform fmt -recursive \
	&& terraform apply -auto-approve \
	&& terraform output vpc_name \
	&& terraform destroy -auto-approve