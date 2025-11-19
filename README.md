# Picus Case Study - Flask DynamoDB Application

Bu proje, AWS servisleri kullanılarak geliştirilmiş bir Flask uygulamasıdır. Uygulama DynamoDB ile veri yönetimi yapar ve hem ECS hem de Lambda üzerinde çalışır.

## 📋 İçindekiler

- [Proje Yapısı](#proje-yapısı)
- [Gereksinimler](#gereksinimler)
- [AWS Yapılandırması](#aws-yapılandırması)
- [Endpoint'ler](#endpointler)
- [Kurulum ve Deployment](#kurulum-ve-deployment)
- [Mimari Açıklama](#mimari-açıklama)
- [CI/CD Pipeline](#cicd-pipeline)

## 📁 Proje Yapısı

```
picus_case/
├── app.py                      # Flask uygulaması (3 endpoint)
├── handler.py                  # Lambda fonksiyonu (DELETE endpoint)
├── serverless.yml              # Serverless Framework yapılandırması
├── Dockerfile                  # Docker image tanımı
├── requirements.txt            # Python bağımlılıkları
├── test_app.py                # Basit test dosyası
├── ecs-task-definition.json   # ECS task definition
├── ecs-service-config.json    # ECS service yapılandırması
├── iam-policies.md            # IAM role ve policy açıklamaları
└── .github/
    └── workflows/
        └── deploy.yml         # GitHub Actions CI/CD pipeline
```

## 🔧 Gereksinimler

### Yerel Geliştirme
- Python 3.10+
- pip
- Docker (opsiyonel, test için)
- AWS CLI (deployment için)
- Node.js 18+ (Serverless Framework için)

### AWS Servisleri
- AWS Account
- DynamoDB table: `picus_data` (partition key: `object_id` - String)
- ECR (Elastic Container Registry)
- ECS Cluster ve Service
- Application Load Balancer
- Lambda Function
- IAM Roles ve Policies

## 🏗️ AWS Yapılandırması

### 1. DynamoDB Table

DynamoDB'de `picus_data` adında bir tablo oluşturulmalıdır:

- **Table Name:** `picus_data`
- **Partition Key:** `object_id` (String)
- **Region:** `us-east-1` (veya tercih ettiğiniz region)

**AWS CLI ile oluşturma:**
```bash
aws dynamodb create-table \
  --table-name picus_data \
  --attribute-definitions AttributeName=object_id,AttributeType=S \
  --key-schema AttributeName=object_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. IAM Roles

Detaylı IAM yapılandırması için `iam-policies.md` dosyasına bakın.

**Gerekli Roller:**
- `ecsTaskExecutionRole`: ECS task'ların ECR'den image çekmesi için
- `ecsTaskRole`: Flask uygulamasının DynamoDB'ye erişmesi için
- Lambda Execution Role: Serverless Framework tarafından otomatik oluşturulur

### 3. ECS Infrastructure

**Gerekli AWS Kaynakları:**
- ECS Cluster: `picus-cluster`
- ECS Service: `picus-flask-service`
- ECR Repository: `picus-flask-app`
- Application Load Balancer
- Target Group
- VPC, Subnets, Security Groups

## 🌐 Endpoint'ler

Tüm endpoint'ler aynı domain/IP adresi altında servis edilir.

### Flask Uygulaması (ECS üzerinde)

#### 1. GET /picus/list
DynamoDB tablosundaki tüm item'ları listeler.

**Request:**
```bash
curl http://your-domain/picus/list
```

**Response:**
```json
[
  {
    "object_id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "Example",
    "data": "some data"
  }
]
```

#### 2. POST /picus/put
Yeni bir item'ı DynamoDB'ye kaydeder ve `object_id` döner.

**Request:**
```bash
curl -X POST http://your-domain/picus/put \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "value": 123}'
```

**Response:**
```json
{
  "object_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

#### 3. GET /picus/get/{key}
Belirtilen `object_id`'ye sahip item'ı getirir.

**Request:**
```bash
curl http://your-domain/picus/get/123e4567-e89b-12d3-a456-426614174000
```

**Response:**
```json
{
  "object_id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "Test",
  "value": 123
}
```

### Lambda Fonksiyonu (Serverless üzerinde)

#### 4. DELETE /picus/{key}
Belirtilen `object_id`'ye sahip item'ı DynamoDB'den siler.

**Request:**
```bash
curl -X DELETE http://lambda-api-gateway-url/picus/123e4567-e89b-12d3-a456-426614174000
```

**Response (Success):**
```json
{
  "message": "Item with key \"123e4567-e89b-12d3-a456-426614174000\" deleted successfully"
}
```

**Response (Not Found):**
```json
{
  "error": "Item with key \"123e4567-e89b-12d3-a456-426614174000\" not found"
}
```

## 🚀 Kurulum ve Deployment

### Yerel Geliştirme

1. **Repository'yi klonlayın:**
```bash
git clone <repository-url>
cd picus_case
```

2. **Virtual environment oluşturun:**
```bash
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

3. **Bağımlılıkları yükleyin:**
```bash
pip install -r requirements.txt
```

4. **Environment variable ayarlayın:**
```bash
export DYNAMODB_TABLE_NAME=picus_data
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

5. **Uygulamayı çalıştırın:**
```bash
python app.py
```

Uygulama `http://localhost:8080` adresinde çalışacaktır.

### Docker ile Test

```bash
# Docker image build et
docker build -t picus-flask-app .

# Container'ı çalıştır
docker run -p 8080:8080 \
  -e DYNAMODB_TABLE_NAME=picus_data \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  -e AWS_DEFAULT_REGION=us-east-1 \
  picus-flask-app
```

### Lambda Deployment (Serverless Framework)

1. **Serverless Framework'ü yükleyin:**
```bash
npm install -g serverless
```

2. **AWS credentials yapılandırın:**
```bash
aws configure
# veya
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

3. **Lambda fonksiyonunu deploy edin:**
```bash
sls deploy
```

Deployment sonrası API Gateway URL'i terminalde gösterilecektir.

### ECS Deployment

#### 1. ECR Repository Oluşturma

```bash
aws ecr create-repository --repository-name picus-flask-app --region us-east-1
```

#### 2. Docker Image Build ve Push

```bash
# ECR'ye login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Image build
docker build -t picus-flask-app .

# Tag
docker tag picus-flask-app:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/picus-flask-app:latest

# Push
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/picus-flask-app:latest
```

#### 3. ECS Cluster ve Service Oluşturma

**Task Definition:**
`ecs-task-definition.json` dosyasındaki `YOUR_ACCOUNT_ID` değerlerini değiştirin ve task definition'ı kaydedin:

```bash
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json
```

**Cluster:**
```bash
aws ecs create-cluster --cluster-name picus-cluster
```

**Service:**
`ecs-service-config.json` dosyasındaki subnet ve security group ID'lerini güncelleyin:

```bash
aws ecs create-service --cli-input-json file://ecs-service-config.json
```

#### 4. Load Balancer Yapılandırması

Application Load Balancer oluşturup ECS service'e bağlayın. Bu sayede tüm endpoint'ler tek bir domain/IP altında servis edilir.

**Not:** Lambda endpoint'i için API Gateway URL'ini ALB'ye yönlendirmek veya ALB'yi API Gateway'in önüne koymak gerekir. Alternatif olarak, Lambda fonksiyonunu da ALB üzerinden erişilebilir hale getirebilirsiniz.

## 🏛️ Mimari Açıklama

### Mimari Bileşenleri

1. **Flask Application (ECS Fargate)**
   - 3 REST endpoint (GET /list, POST /put, GET /get/{key})
   - Gunicorn WSGI server ile production-ready
   - DynamoDB ile veri işlemleri
   - Health check desteği

2. **Lambda Function (Serverless)**
   - DELETE /picus/{key} endpoint
   - API Gateway ile HTTP trigger
   - DynamoDB delete işlemi

3. **DynamoDB**
   - Veri saklama
   - Partition key: `object_id` (String)

4. **CI/CD Pipeline (GitHub Actions)**
   - Otomatik test
   - Docker image build
   - ECS deployment
   - Lambda deployment

### Zero-Downtime Deployment

ECS service yapılandırması zero-downtime deployment sağlar:

- **Deployment Configuration:**
  - `maximumPercent: 200`: Yeni task'lar başlatılırken eski task'lar çalışmaya devam eder
  - `minimumHealthyPercent: 100`: Her zaman en az 1 sağlıklı task çalışır
  - `deploymentCircuitBreaker`: Hata durumunda otomatik rollback

- **Load Balancer:**
  - Health check ile sağlıksız task'lar trafikten çıkarılır
  - Yeni task'lar hazır olana kadar eski task'lar trafiği alır

### IAM Güvenlik

- **Principle of Least Privilege:** Her role sadece ihtiyacı olan izinlere sahip
- **Task Execution Role:** Sadece ECR pull ve CloudWatch Logs
- **Task Role:** Sadece DynamoDB işlemleri (GetItem, PutItem, Scan)
- **Lambda Role:** Sadece DynamoDB DeleteItem ve GetItem

## 🔄 CI/CD Pipeline

GitHub Actions workflow'u şu adımları içerir:

1. **Test Job:**
   - Code checkout
   - Python environment setup
   - Dependencies install
   - Test execution

2. **Build and Deploy Job (ECS):**
   - AWS credentials configuration
   - ECR login
   - Docker image build ve push
   - ECS task definition update
   - ECS service deployment (zero-downtime)

3. **Deploy Lambda Job:**
   - Serverless Framework setup
   - Lambda function deployment

### GitHub Secrets Yapılandırması

Repository Settings > Secrets and variables > Actions bölümüne şu secret'ları ekleyin:

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

## 📝 Notlar

- Tüm endpoint'ler aynı domain/IP altında servis edilmelidir. Bu için ALB ve API Gateway'i birleştirmek veya Lambda'yı ALB üzerinden erişilebilir hale getirmek gerekir.
- Production ortamında environment variable'ları AWS Secrets Manager veya Parameter Store'dan alın.
- CloudWatch Logs ile log monitoring yapın.
- Cost optimization için DynamoDB'de on-demand billing yerine provisioned capacity kullanabilirsiniz (trafik öngörülebilirse).

## 🧪 Test

Basit test dosyası:
```bash
python test_app.py
```

Manuel test:
```bash
# List items
curl http://localhost:8080/picus/list

# Put item
curl -X POST http://localhost:8080/picus/put \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "value": 123}'

# Get item (object_id'yi yukarıdaki response'dan alın)
curl http://localhost:8080/picus/get/{object_id}

# Delete item (Lambda endpoint)
curl -X DELETE http://lambda-url/picus/{object_id}
```

## 📚 Kaynaklar

- [Flask Documentation](https://flask.palletsprojects.com/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [Serverless Framework Documentation](https://www.serverless.com/framework/docs)

## 👤 Geliştirici Notları

- `app.py`: Flask uygulaması, 3 endpoint içerir
- `handler.py`: Lambda fonksiyonu, DELETE endpoint
- `serverless.yml`: Serverless Framework yapılandırması, IAM policy'leri içerir
- `Dockerfile`: Production-ready Docker image, Gunicorn kullanır
- `.github/workflows/deploy.yml`: CI/CD pipeline tanımı
