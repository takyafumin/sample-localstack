# sample-aws-cloudformation-sqs-lambda

CloudFormation を使って SQS + Lambda の連携を試す

## 必要なもの

- localstack
- awscli
- awscli-local

## 使い方

### デプロイ手順

1. S3バケットを作成します

```bash
# プロジェクトルートディレクトリで実行
awslocal cloudformation deploy --template-file ./cloudformation/s3.yml --stack-name S3BucketStack --capabilities CAPABILITY_IAM
```

2. Lambda 関数をビルドして S3 バケットにアップロードします

```bash
cd lambdas/receiver
npm install
npm run bundle
awslocal s3 cp index.zip s3://sample-aws-sqs-lambda-functions/receiver
```

3. Lambda関数をデプロイします

```bash
# プロジェクトルートディレクトリで実行
awslocal cloudformation deploy --template-file ./cloudformation/lambda.yml --stack-name MyLambdaStack --capabilities CAPABILITY_NAMED_IAM
```

4. Lambda関数を実行します

```bash
awslocal lambda invoke --function-name MyLambdaFunction --log-type Tail output.txt | jq -r '.LogResult' | base64 --decode && rm output.txt
```

### Lambda関数の更新手順

1. コードをビルドしてzipにします。

```bash
cd lambdas/receiver
npm run bundle
```

2. Lambda関数のコードをS3バケットに再アップロードします。

```bash
awslocal s3 cp index.zip s3://sample-aws-sqs-lambda-functions/receiver
```

3. Lambda関数を再デプロイします。

```bash
awslocal cloudformation deploy --template-file ./cloudformation/lambda.yml --stack-name MyLambdaStack --capabilities CAPABILITY_NAMED_IAM
```

### 破棄手順

```bash
# プロジェクトルートディレクトリで実行

# Lambda の破棄
awslocal cloudformation delete-stack --stack-name MyLambdaStack

# S3 の破棄
awslocal cloudformation delete-stack --stack-name S3BucketStack
```
