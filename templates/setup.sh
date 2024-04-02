#!/bin/bash

aws s3api create-bucket --bucket simetrik-tfbackend \
        --region us-east-2 \
        --create-bucket-configuration LocationConstraint=us-east-2

aws dynamodb create-table --table-name simetrik-tflockid \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10