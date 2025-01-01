import { SQS } from 'aws-sdk';
import { APIGatewayProxyEvent, APIGatewayProxyResult, Handler } from 'aws-lambda';

const sqs = new SQS();
const QUEUE_URL = process.env.QUEUE_URL || '';

/**
 * リクエストパラメータを受け取り、SQSにメッセージを送信する
 *
 * @param event
 * @returns
 */
export const handler: Handler = async (event) => {

  if (!QUEUE_URL) {
    console.log('Error: QUEUE_URL is not defined');
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'QUEUE_URL is not defined' }),
    };
  }

  // パラメータを出力
  console.log('Received event:', JSON.stringify(event.body, null, 2));
  console.log('input1:', JSON.stringify(event.input1, null, 2));
  console.log('input2:', JSON.stringify(event.input2, null, 2));
  console.log('QueueUrl:', QUEUE_URL);

  const messageBody = {
    input1: event.input1,
    input2: event.input2,
  }

  const params = {
    QueueUrl: QUEUE_URL,
    MessageBody: JSON.stringify(messageBody),
  };

  try {
    await sqs.sendMessage(params).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Message sent to SQS' }),
    };
  } catch (error) {
    console.log('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to send message to SQS', details: (error as any).message }),
    };
  }
};
