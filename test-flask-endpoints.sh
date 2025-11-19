#!/bin/bash
# Flask Endpoints Test Script

CLUSTER="picus-cluster"
SERVICE="picus-flask-service"
REGION="eu-central-1"

echo "🧪 Testing Flask Endpoints"
echo ""

# Task'ları listele
echo "1️⃣ Getting running tasks..."
TASK_ARNS=$(aws ecs list-tasks \
  --cluster $CLUSTER \
  --service-name $SERVICE \
  --region $REGION \
  --query 'taskArns[]' \
  --output text)

if [ -z "$TASK_ARNS" ]; then
  echo "❌ No running tasks found!"
  exit 1
fi

# İlk task'ın detaylarını al
FIRST_TASK=$(echo $TASK_ARNS | awk '{print $1}')
echo "Using task: $FIRST_TASK"

# Task'ın network interface'ini bul (public IP için)
ENI_ID=$(aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $FIRST_TASK \
  --region $REGION \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

if [ -z "$ENI_ID" ]; then
  echo "❌ Could not find network interface"
  exit 1
fi

echo "Network Interface: $ENI_ID"

# Public IP'yi al
PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --region $REGION \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
  echo "⚠️  No public IP found. Task might be in private subnet."
  echo "You may need to use a Load Balancer or VPN to access."
  exit 1
fi

echo "✅ Public IP: $PUBLIC_IP"
echo ""

# Test endpoint'leri
BASE_URL="http://$PUBLIC_IP:8080"

echo "2️⃣ Testing GET /picus/list"
echo "Request: GET $BASE_URL/picus/list"
curl -s "$BASE_URL/picus/list" | python3 -m json.tool || echo "Failed"
echo ""

echo "3️⃣ Testing POST /picus/put"
echo "Request: POST $BASE_URL/picus/put"
RESPONSE=$(curl -s -X POST "$BASE_URL/picus/put" \
  -H "Content-Type: application/json" \
  -d '{"name": "test-item", "value": 123}')

echo "$RESPONSE" | python3 -m json.tool || echo "$RESPONSE"

# Object ID'yi çıkar
OBJECT_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['object_id'])" 2>/dev/null)

if [ -n "$OBJECT_ID" ]; then
  echo ""
  echo "✅ Created object_id: $OBJECT_ID"
  echo ""
  
  echo "4️⃣ Testing GET /picus/get/$OBJECT_ID"
  echo "Request: GET $BASE_URL/picus/get/$OBJECT_ID"
  curl -s "$BASE_URL/picus/get/$OBJECT_ID" | python3 -m json.tool || echo "Failed"
  echo ""
else
  echo "⚠️  Could not extract object_id from response"
fi

echo ""
echo "✅ Test complete!"
echo ""
echo "Note: DELETE endpoint is tested via Lambda function"

