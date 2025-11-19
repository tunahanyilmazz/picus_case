import os
import json
import uuid
from flask import Flask, request, jsonify
import boto3

# --- Configuration ---
# Use Boto3 for DynamoDB interaction
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "picus_data")
app = Flask(__name__)
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

@app.route('/picus/list', methods=['GET'])
def list_items():
    """a. GET /picus/list: Returns all items in the DynamoDB table."""
    try:
        response = table.scan()
        return jsonify(response.get('Items', [])), 200
    except Exception as e:
        app.logger.error(f"Error listing items: {e}")
        return jsonify({"error": "Could not list items"}), 500

@app.route('/picus/put', methods=['POST'])
def put_item():
    """b. POST /picus/put: Saves given JSON data and returns the object_id."""
    try:
        data = request.get_json(force=True)
    except Exception:
        return jsonify({"error": "Invalid JSON body"}), 400

    if not data:
        return jsonify({"error": "Request body cannot be empty"}), 400

    # Generate a unique ID
    object_id = str(uuid.uuid4())
    
    # Add the primary key to the data
    item = {"object_id": object_id}
    item.update(data)
    
    try:
        table.put_item(Item=item)
        return jsonify({"object_id": object_id}), 201
    except Exception as e:
        app.logger.error(f"Error putting item: {e}")
        return jsonify({"error": "Could not save item"}), 500

@app.route('/picus/get/<key>', methods=['GET'])
def get_item(key):
    """c. GET /picus/get/{key}: Returns the object of the given key."""
    try:
        response = table.get_item(Key={'object_id': key})
        item = response.get('Item')
        
        if item:
            return jsonify(item), 200
        else:
            return jsonify({"error": f"Item with key '{key}' not found"}), 404
    except Exception as e:
        app.logger.error(f"Error getting item: {e}")
        return jsonify({"error": "Could not retrieve item"}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for ECS."""
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # When running locally, it's safer to not rely on the OS environment for the port.
    port = int(os.environ.get('PORT', 8080))
    app.run(debug=True, host='0.0.0.0', port=port)