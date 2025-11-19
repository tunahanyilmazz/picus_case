import json
import os
import boto3

DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "picus_data")
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

def delete_item(event, context):
    """
    DELETE /picus/{key} endpoint: Deletes the given key from the DynamoDB table.
    """
    try:
        # Extract the key from the path parameters
        key = event['pathParameters']['key']
    except (TypeError, KeyError):
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing key path parameter'})
        }

    try:
        response = table.delete_item(
            Key={'object_id': key},
            # Return values: ALL_OLD means it will return the item attributes
            # if the item was successfully deleted.
            ReturnValues='ALL_OLD' 
        )

        if 'Attributes' in response:
            return {
                'statusCode': 200,
                'body': json.dumps({'message': f'Item with key "{key}" deleted successfully'})
            }
        else:
            # Item was not found
            return {
                'statusCode': 404,
                'body': json.dumps({'error': f'Item with key "{key}" not found'})
            }

    except Exception as e:
        print(f"Error deleting item: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Could not delete item'})
        }