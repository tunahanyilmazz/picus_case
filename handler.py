import json
import os
import boto3

DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "picus_data")
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

def delete_item(event, context):
    """
    DELETE /picus/{key} endpoint: Deletes the given key from the DynamoDB table.
    Supports both ALB and API Gateway event formats.
    """
    try:
        # ALB event format: path is in event['path']
        # API Gateway format: path is in event['pathParameters']
        if 'path' in event:
            # ALB format: /picus/{key}
            path = event['path']
            key = path.split('/')[-1]  # Extract key from /picus/{key}
        elif 'pathParameters' in event and event['pathParameters']:
            # API Gateway format
            key = event['pathParameters']['key']
        else:
            raise KeyError('No path or pathParameters found')
    except (TypeError, KeyError, IndexError):
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing key path parameter'}),
            'headers': {'Content-Type': 'application/json'}
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
                'body': json.dumps({'message': f'Item with key "{key}" deleted successfully'}),
                'headers': {'Content-Type': 'application/json'}
            }
        else:
            # Item was not found
            return {
                'statusCode': 404,
                'body': json.dumps({'error': f'Item with key "{key}" not found'}),
                'headers': {'Content-Type': 'application/json'}
            }

    except Exception as e:
        print(f"Error deleting item: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Could not delete item'}),
            'headers': {'Content-Type': 'application/json'}
        }