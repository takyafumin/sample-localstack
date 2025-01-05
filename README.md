# sample-aws-cloudformation-sqs-lambda

CloudFormation を使って SQS + Lambda の連携を試す

## 必要なもの

- awscli

## 環境情報

|    リソース    |                                         値                                          |
| -------------- | ----------------------------------------------------------------------------------- |
| S3 Bucket Name | sample-aws-sqs-lambda-functions                                                     |
| S3 Bucket URI  | s3://sample-aws-sqs-lambda-functions/sender                                         |
| S3 Bucket URI  | s3://sample-aws-sqs-lambda-functions/receiver                                       |
| SQS Queue Name | RequestQueue                                                                        |
| SQS URL        | http://sqs.ap-northeast-1.localhost.localstack.cloud:4566/000000000000/RequestQueue |

## 使い方

### AWS CLI のセットアップ

1. AWS CLIをインストールします。
    ```sh
    pip install awscli
    ```

2. AWS CLIを設定します。
    ```sh
    aws configure
    ```

### デプロイ手順

```bash
./run.sh init
```

### 実行方法

```bash
./run.sh test
```

### Lambda関数の更新手順

```bash
./run.sh update-lambda
```

### 破棄手順

```bash
./run.sh rm
```

## TIPS

### Lambda 関数のログを監視モードで確認する場合

```bash
# MySenderLambdaFunction (Lambda) のログの監視
aws logs tail /aws/lambda/MySenderLambdaFunction --follow

# MyReceiverLambdaFunction (Lambda) のログの監視
aws logs tail /aws/lambda/MyReceiverLambdaFunction --follow
```
