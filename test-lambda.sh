#!/bin/bash
# Lambda Function Test Script

FUNCTION_NAME="picus-delete-function"
REGION="eu-central-1"

echo "🧪 Testing Lambda Function: $FUNCTION_NAME"
echo ""

# Test 1: Function bilgilerini kontrol et
echo "1️⃣ Checking function configuration..."
aws lambda get-function \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Configuration.[FunctionName,Runtime,Handler,LastModified]' \
  --output table

echo ""
echo "2️⃣ Testing Lambda function with sample event..."

# Test event oluştur (DELETE /picus/{key} için)
cat > test-event.json << 'EOF'
{
  "pathParameters": {
    "key": "test-key-123"
  },
  "httpMethod": "DELETE",
  "path": "/picus/test-key-123"
}
EOF

# Lambda'yı invoke et
echo "Invoking Lambda function..."
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload file://test-event.json \
  --region $REGION \
  response.json

echo ""
echo "Response:"
cat response.json | python3 -m json.tool

echo ""
echo "3️⃣ Checking CloudWatch Logs..."
echo "View logs with:"
echo "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow --region $REGION"

# Cleanup
rm -f test-event.json response.json

echo ""
echo "✅ Test complete!"

