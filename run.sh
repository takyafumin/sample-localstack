# 現在のディレクトリを保存
ROOT_DIR=$(pwd)

# S3バケット名を取得
S3_BUCKET_NAME=sample-aws-sqs-lambda-functions-template

# ParentStackの定義
PARENT_STACK_NAME="SampleAwsSqsLambdaFunctionsStack"

# ----------------------------------------
# CloudFormationスタックを構築する関数
# ----------------------------------------
deploy_stacks() {
  # s3バケットのスタックをデプロイ
  echo "Deploying S3 bucket stack..."
  aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template-s3.yml \
    --stack-name S3BucketCFnStack \
    --parameter-overrides BucketName=$S3_BUCKET_NAME \
    --capabilities CAPABILITY_NAMED_IAM

  # Lambda関数のビルドとパッケージング
  echo "Building and packaging Lambda functions..."
  npm run build-sender
  npm run build-receiver

  # Lambda関数をS3にアップロード
  echo "Uploading Lambda functions to S3..."
  aws s3 cp lambdas/sender/index.zip s3://$S3_BUCKET_NAME/sender/index.zip
  aws s3 cp lambdas/receiver/index.zip s3://$S3_BUCKET_NAME/receiver/index.zip

  # テンプレートをS3にアップロード
  echo "Uploading templates to S3..."
  aws s3 cp cloudformation/template.yml s3://$S3_BUCKET_NAME/cloudformation/template.yml
  aws s3 cp cloudformation/resources/sqs.yml s3://$S3_BUCKET_NAME/cloudformation/resources/sqs.yml
  aws s3 cp cloudformation/resources/lambda.yml s3://$S3_BUCKET_NAME/cloudformation/resources/lambda.yml
  aws s3 cp cloudformation/resources/api-gateway.yml s3://$S3_BUCKET_NAME/cloudformation/resources/api-gateway.yml

  # スタックをデプロイ
  echo "Deploying parent stack..."
  aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template.yml \
    --stack-name $PARENT_STACK_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        LambdaS3BucketName=$S3_BUCKET_NAME \
        LambdaS3BucketKeySender=sender/index.zip \
        LambdaS3BucketKeyReceiver=receiver/index.zip

  API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name $PARENT_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlProd'].OutputValue" --output text)
  echo "API Gateway URL (Prod): $API_GATEWAY_URL"
  API_GATEWAY_URL_DEV=$(aws cloudformation describe-stacks --stack-name $PARENT_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlDev'].OutputValue" --output text)
  echo "API Gateway URL (Dev): $API_GATEWAY_URL_DEV"

  echo "Deployment complete."
}

# ----------------------------------------
# CloudFormationスタックを破棄する関数
# ----------------------------------------
delete_stacks() {
  echo "Deleting CloudFormation stacks..."

  # ParentStackを削除
  aws cloudformation delete-stack --stack-name $PARENT_STACK_NAME
  aws cloudformation wait stack-delete-complete --stack-name $PARENT_STACK_NAME

  # S3バケットの中身を削除
  echo "Deleting S3 bucket contents..."
  aws s3 rm s3://$S3_BUCKET_NAME --recursive

  # S3バケットのスタックを削除
  aws cloudformation delete-stack --stack-name S3BucketCFnStack
  aws cloudformation wait stack-delete-complete --stack-name S3BucketCFnStack

  echo "Deletion complete."
}

# ----------------------------------------
# Lambdaリソースを更新する関数
# ----------------------------------------
update_lambda_resources() {
  # Lambda関数のビルドとパッケージング
  echo "Building and packaging Lambda functions..."
  npm run build-sender
  npm run build-receiver

  # Lambda関数をS3にアップロード
  echo "Uploading Lambda functions to S3..."
  aws s3 cp lambdas/sender/index.zip s3://$S3_BUCKET_NAME/sender/index.zip
  aws s3 cp lambdas/receiver/index.zip s3://$S3_BUCKET_NAME/receiver/index.zip

  # スタックを更新
  echo "Updating parent stack..."
  aws cloudformation deploy --template-file $ROOT_DIR/cloudformation/template.yml \
    --stack-name $PARENT_STACK_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        LambdaS3BucketName=$S3_BUCKET_NAME \
        LambdaS3BucketKeySender=sender/index.zip \
        LambdaS3BucketKeyReceiver=receiver/index.zip

  echo "Lambda resources update complete."
}

# ----------------------------------------
# 動作確認のための関数
# ----------------------------------------
test_stacks() {
  API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name $PARENT_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrlProd'].OutputValue" --output text)
  echo "Testing API Gateway URL (Prod): $API_GATEWAY_URL"

  if [ -z "$API_GATEWAY_URL" ]; then
    echo "API Gateway URL not found. Make sure the stack is deployed."
    exit 1
  fi

  RESPONSE=$(curl -s -X POST $API_GATEWAY_URL -H "Content-Type: application/json" -d '{"input1": 100, "input2": 200}')
  echo "Response from API Gateway: $RESPONSE"
}

# ----------------------------------------
# スクリプトの引数に応じて処理を実行
# ----------------------------------------
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
  update-lambda)
    update_lambda_resources
    ;;
  *)
    echo "Usage: $0 {init|rm|test|update-lambda}"
    exit 1
    ;;
esac
