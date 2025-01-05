# 現在のディレクトリを保存
ROOT_DIR=$(pwd)

# S3バケット名を取得する関数
get_s3_bucket_name() {
  aws cloudformation describe-stacks --stack-name S3BucketCFnStack --query "Stacks[0].Outputs[?OutputKey=='S3BucketNameCFn'].OutputValue" --output text
}

# CloudFormationスタックを構築する関数
deploy_stacks() {
  echo "Deploying S3 bucket stack..."
  aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template-s3.yml --stack-name S3BucketCFnStack --capabilities CAPABILITY_NAMED_IAM

  S3_BUCKET_NAME=$(get_s3_bucket_name)

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

  echo "Uploading templates to S3..."
  aws s3 cp $ROOT_DIR/cloudformation/resources/s3.yml s3://$S3_BUCKET_NAME/cloudformation/resources/s3.yml
  aws s3 cp $ROOT_DIR/cloudformation/resources/sqs.yml s3://$S3_BUCKET_NAME/cloudformation/resources/sqs.yml
  aws s3 cp $ROOT_DIR/cloudformation/resources/lambda.yml s3://$S3_BUCKET_NAME/cloudformation/resources/lambda.yml
  aws s3 cp $ROOT_DIR/cloudformation/resources/api-gateway.yml s3://$S3_BUCKET_NAME/cloudformation/resources/api-gateway.yml
  aws s3 cp $ROOT_DIR/cloudformation/template.yml s3://$S3_BUCKET_NAME/cloudformation/template.yml

  echo "Deploying parent stack..."
  aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template.yml --stack-name ParentStack --capabilities CAPABILITY_NAMED_IAM --parameter-overrides S3BucketName=$S3_BUCKET_NAME LambdaS3BucketName=$S3_BUCKET_NAME LambdaS3BucketKeySender=sender/index.zip LambdaS3BucketKeyReceiver=receiver/index.zip

  API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name ParentStack --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlProd'].OutputValue" --output text)
  echo "API Gateway URL (Prod): $API_GATEWAY_URL"

  API_GATEWAY_URL_DEV=$(aws cloudformation describe-stacks --stack-name ParentStack --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlDev'].OutputValue" --output text)
  echo "API Gateway URL (Dev): $API_GATEWAY_URL_DEV"

  echo "Deployment complete."
}

# CloudFormationスタックを破棄する関数
delete_stacks() {
  echo "Deleting CloudFormation stacks..."

  aws cloudformation delete-stack --stack-name ParentStack
  aws cloudformation wait stack-delete-complete --stack-name ParentStack

  aws cloudformation delete-stack --stack-name S3BucketCFnStack
  aws cloudformation wait stack-delete-complete --stack-name S3BucketCFnStack

  echo "Deletion complete."
}

# 動作確認のための関数
test_stacks() {
  API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name ParentStack --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlProd'].OutputValue" --output text)
  echo "Testing API Gateway URL (Prod): $API_GATEWAY_URL"

  if [ -z "$API_GATEWAY_URL" ]; then
    echo "API Gateway URL not found. Make sure the stack is deployed."
    exit 1
  fi

  RESPONSE=$(curl -s -X POST $API_GATEWAY_URL -H "Content-Type: application/json" -d '{"input1": 100, "input2": 200}')
  echo "Response from API Gateway: $RESPONSE"
}

# スクリプトの引数に応じて処理を実行
case "$1" in
  init)
    deploy_stacks
    ;;
  rm)
    delete_stacks
    ;;
  test)
    test_stacks
    ;;
  *)
    echo "Usage: $0 {init|rm|test}"
    exit 1
    ;;
esac