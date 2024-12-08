import { Handler } from "aws-lambda";

/**
 * リクエストを受け付ける Lambda
 * @param event
 */
export const handler:Handler = async (event: any) => {
    console.log('Hello, world!');
    console.log("%o", event);
}
