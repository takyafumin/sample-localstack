#!/bin/bash

# 現在のディレクトリを保存
ROOT_DIR=$(pwd)

# S3バケットのCloudFormationスタックを作成
echo "Deploying S3 bucket stack..."
aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template-s3.yml --stack-name S3BucketCFnStack --capabilities CAPABILITY_NAMED_IAM

# S3バケット名を取得
S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name S3BucketCFnStack --query "Stacks[0].Outputs[?OutputKey=='S3BucketNameCFn'].OutputValue" --output text)

# Lambda関数のビルドとパッケージング
echo "Building and packaging Lambda functions..."
pushd $ROOT_DIR/lambdas/sender
npm install
npm run bundle
aws s3 cp index.zip s3://$S3_BUCKET_NAME/sender/index.zip
popd

pushd $ROOT_DIR/lambdas/receiver
npm install
npm run bundle
aws s3 cp index.zip s3://$S3_BUCKET_NAME/receiver/index.zip
popd

# テンプレートのアップロード
echo "Uploading templates to S3..."
aws s3 cp $ROOT_DIR/cloudformation/resources/s3.yml s3://$S3_BUCKET_NAME/cloudformation/resources/s3.yml
aws s3 cp $ROOT_DIR/cloudformation/resources/sqs.yml s3://$S3_BUCKET_NAME/cloudformation/resources/sqs.yml
aws s3 cp $ROOT_DIR/cloudformation/resources/lambda.yml s3://$S3_BUCKET_NAME/cloudformation/resources/lambda.yml
aws s3 cp $ROOT_DIR/cloudformation/resources/api-gateway.yml s3://$S3_BUCKET_NAME/cloudformation/resources/api-gateway.yml
aws s3 cp $ROOT_DIR/cloudformation/template.yml s3://$S3_BUCKET_NAME/cloudformation/template.yml

# 親テンプレートのCloudFormationスタックを作成
echo "Deploying parent stack..."
aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template.yml --stack-name ParentStack --capabilities CAPABILITY_NAMED_IAM --parameter-overrides S3BucketName=$S3_BUCKET_NAME LambdaS3BucketName=$S3_BUCKET_NAME LambdaS3BucketKeySender=sender/index.zip LambdaS3BucketKeyReceiver=receiver/index.zip

# API GatewayのURLを取得して表示
API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name ParentStack --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlProd'].OutputValue" --output text)
echo "API Gateway URL (Prod): $API_GATEWAY_URL"

API_GATEWAY_URL_DEV=$(aws cloudformation describe-stacks --stack-name ParentStack --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlDev'].OutputValue" --output text)
echo "API Gateway URL (Dev): $API_GATEWAY_URL_DEV"

echo "Deployment complete."
