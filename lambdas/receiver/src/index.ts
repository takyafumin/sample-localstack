import { SQSEvent, SQSHandler } from "aws-lambda";

/**
 * リクエストを受け付ける Lambda
 * @param event
 */
export const handler: SQSHandler = async (event: SQSEvent) => {
    console.log('Hello, world!');
    for (const record of event.Records) {
        const body: any = JSON.parse(record.body);
        console.log("Message ID: ", record.messageId);
        console.log("Message Body: ", record.body);
        console.log("input1: ", body.input1);
        console.log("input2: ", body.input2);
    }
}
