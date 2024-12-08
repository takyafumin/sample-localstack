import { SQSEvent, SQSHandler } from "aws-lambda";

/**
 * リクエストを受け付ける Lambda
 * @param event
 */
export const handler: SQSHandler = async (event: SQSEvent) => {
    console.log('Hello, world!');
    console.log("%o", event);
}
