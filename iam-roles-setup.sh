#!/bin/bash

# IAM Role'leri Oluşturma Script'i
# Bu script ECS için gerekli IAM role'lerini oluşturur

set -e  # Hata durumunda dur

echo "🚀 IAM Role'leri oluşturuluyor..."

# 1. ECS Task Execution Role oluştur
echo "📝 ECS Task Execution Role oluşturuluyor..."
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://ecs-execution-trust-policy.json \
  --region eu-central-1 2>/dev/null || echo "⚠️  Role zaten mevcut, devam ediliyor..."

# AWS managed policy'yi attach et
echo "📎 AmazonECSTaskExecutionRolePolicy policy'si ekleniyor..."
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  --region eu-central-1

echo "✅ ECS Task Execution Role oluşturuldu!"

# 2. ECS Task Role oluştur
echo "📝 ECS Task Role oluşturuluyor..."
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document file://ecs-task-trust-policy.json \
  --region eu-central-1 2>/dev/null || echo "⚠️  Role zaten mevcut, devam ediliyor..."

# DynamoDB policy'sini ekle
echo "📎 DynamoDB policy'si ekleniyor..."
aws iam put-role-policy \
  --role-name ecsTaskRole \
  --policy-name DynamoDBAccess \
  --policy-document file://dynamodb-policy.json \
  --region eu-central-1

echo "✅ ECS Task Role oluşturuldu!"

# 3. Role'leri kontrol et
echo ""
echo "🔍 Role'ler kontrol ediliyor..."
echo ""
echo "ECS Task Execution Role:"
aws iam get-role --role-name ecsTaskExecutionRole --query 'Role.Arn' --output text
echo ""
echo "ECS Task Role:"
aws iam get-role --role-name ecsTaskRole --query 'Role.Arn' --output text

echo ""
echo "✅ Tüm IAM role'leri başarıyla oluşturuldu!"

