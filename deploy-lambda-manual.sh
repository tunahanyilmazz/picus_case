#!/bin/bash
# Manual Lambda deployment script using AWS CLI
# This script deploys the Python Lambda function without requiring Node.js/Serverless Framework

set -e

REGION="eu-central-1"
FUNCTION_NAME="picus-delete-function"
ROLE_NAME="picus-lambda-role"
HANDLER="handler.delete_item"
RUNTIME="python3.10"
TIMEOUT=30
MEMORY_SIZE=256

echo "🚀 Deploying Lambda function..."

# Install dependencies
echo "📦 Installing dependencies..."
pip install boto3 -t . --quiet

# Create deployment package
echo "📦 Creating deployment package..."
zip -r lambda-function.zip handler.py boto3* botocore* -x "*.pyc" -x "*__pycache__*" > /dev/null

# Check if IAM role exists, create if not
echo "🔐 Checking IAM role..."
if ! aws iam get-role --role-name $ROLE_NAME --region $REGION 2>/dev/null; then
  echo "Creating IAM role..."
  
  # Create trust policy
  cat > lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # Create role
  aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://lambda-trust-policy.json \
    --region $REGION

  # Attach basic Lambda execution policy
  aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
    --region $REGION

  # Add DynamoDB policy
  cat > lambda-dynamodb-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem"
      ],
      "Resource": "arn:aws:dynamodb:${REGION}:824912998004:table/picus_data"
    }
  ]
}
EOF

  aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name DynamoDBAccess \
    --policy-document file://lambda-dynamodb-policy.json \
    --region $REGION

  echo "⏳ Waiting for role to be ready..."
  sleep 10
fi

ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text --region $REGION)
echo "✅ Using role: $ROLE_ARN"

# Check if function exists
if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>/dev/null; then
  echo "📝 Updating existing function..."
  aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://lambda-function.zip \
    --region $REGION
    
  # Update environment variables
  aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment "Variables={DYNAMODB_TABLE_NAME=picus_data}" \
    --region $REGION
    
  echo "✅ Function updated!"
else
  echo "🆕 Creating new function..."
  aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime $RUNTIME \
    --role $ROLE_ARN \
    --handler $HANDLER \
    --zip-file fileb://lambda-function.zip \
    --timeout $TIMEOUT \
    --memory-size $MEMORY_SIZE \
    --environment "Variables={DYNAMODB_TABLE_NAME=picus_data}" \
    --region $REGION
    
  echo "✅ Function created!"
fi

# Cleanup
rm -f lambda-function.zip lambda-trust-policy.json lambda-dynamodb-policy.json
rm -rf boto3* botocore* jmespath* s3transfer* urllib3* dateutil* six.py*

echo "🎉 Lambda deployment complete!"

