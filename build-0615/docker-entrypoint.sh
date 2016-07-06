#!/bin/bash

#Exit immediately if a pipeline exits  with a non-zero status
set -e

#if [ -z "$TERRAFORM_REMOTE_FALSE" ]; then
    #defaults to s3
if [ -z "$TERRAFORM_REMOTE_BACKEND" ]; then
    TERRAFORM_REMOTE_BACKEND=s3
fi

if [ "$TERRAFORM_REMOTE_BACKEND" = 's3' ]; then
    if [[ -z "$AWS_ACCESS_KEY_ID" ]] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        if [ ! -f /root/.aws/credentials ] && [ ! -f /root/.boto ]; then
            if [[ -z "$AWS_ACCESS_KEY_ID" ]] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
                echo >&2 'error: missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY environment variables'
                exit 1
            fi
        fi
    fi

    if [[ -z "$TERRAFORM_REMOTE_CONFIG_BUCKET" ]] || [ -z "$TERRAFORM_REMOTE_CONFIG_KEY" ] || [ -z "$TERRAFORM_REMOTE_CONFIG_REGION" ]; then
        echo >&2 'error: missing TERRAFORM_REMOTE_CONFIG_BUCKET or TERRAFORM_REMOTE_CONFIG_KEY or TERRAFORM_REMOTE_CONFIG_REGION  environment variables'
        exit 1
    fi

    terraform remote config -backend=s3 -backend-config="bucket=$TERRAFORM_REMOTE_CONFIG_BUCKET" -backend-config="key=$TERRAFORM_REMOTE_CONFIG_KEY" -backend-config="region=$TERRAFORM_REMOTE_CONFIG_REGION"

else
    echo >&2 'error: backend not supported'
    exit 1
fi

terraform remote pull
terraform get
#fi

if [ "$1" = 'plan' ]; then
    if [ ! -d "plans" ]; then
        mkdir plans
    fi
    exec terraform plan -module-depth=-1 -out=plans/$(git rev-parse HEAD).out
fi

if [ "$1" = 'apply' ]; then
    exec terraform apply plans/$(git rev-parse HEAD).out
    rm plans/$(git rev-parse HEAD).out
fi
