# Picus Case Study - Technical Documentation

## Executive Summary

This project implements a production-ready REST API application on AWS infrastructure, demonstrating proficiency in cloud architecture, containerization, serverless computing, and DevOps practices. The solution serves all endpoints under a single domain using Application Load Balancer (ALB) with path-based routing, integrating both containerized (ECS Fargate) and serverless (Lambda) components.

**Key Achievement:** Unified API gateway serving 4 REST endpoints (3 on ECS, 1 on Lambda) with zero-downtime deployment, automated CI/CD, and least-privilege IAM security.

---

## Problem Statement & Requirements

### Business Requirements
1. Create a REST API with 4 endpoints for DynamoDB CRUD operations
2. Deploy endpoints using both containerized and serverless architectures
3. Serve all endpoints under a single domain/IP address
4. Implement automated CI/CD pipeline
5. Ensure high availability and zero-downtime deployments
6. Apply security best practices (least privilege IAM)

### Technical Requirements
- **DynamoDB Table:** `picus_data` with `object_id` as partition key (String)
- **Endpoints:**
  - `GET /picus/list` - List all items
  - `POST /picus/put` - Create item
  - `GET /picus/get/{key}` - Get item by key
  - `DELETE /picus/{key}` - Delete item by key
- **Deployment:** ECS for CRUD operations, Lambda for DELETE operation
- **Single Domain:** All endpoints accessible via one ALB DNS

---

## Solution Architecture

### High-Level Architecture

```
Internet
   │
   ▼
Application Load Balancer (ALB)
   │
   ├─── Listener Rule: Default (Priority: default)
   │    └─── Target Group: picus-ecs-tg
   │         └─── ECS Fargate Service (2 tasks)
   │              └─── Flask Application (Gunicorn)
   │                   ├─── GET /picus/list
   │                   ├─── POST /picus/put
   │                   ├─── GET /picus/get/{key}
   │                   └─── GET /health
   │
   └─── Listener Rule: DELETE /picus/* (Priority: 100)
        └─── Target Group: picus-lambda-tg
             └─── Lambda Function: picus-delete-function
                  └─── DELETE /picus/{key}
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Application** | Python 3.10, Flask 2.3.2 | REST API framework |
| **Container Runtime** | Docker, Gunicorn | Production WSGI server |
| **Compute (CRUD)** | AWS ECS Fargate | Container orchestration |
| **Compute (Delete)** | AWS Lambda | Serverless execution |
| **Database** | Amazon DynamoDB | NoSQL data store |
| **Load Balancing** | Application Load Balancer | Traffic routing |
| **CI/CD** | GitHub Actions | Automated deployment |
| **Deployment** | AWS CLI, JSON configs | Configuration-driven deployment (ECS: JSON configs, Lambda: AWS CLI) |

---

## Implementation Details

### 1. Application Development

#### Flask Application (`app.py`)
- **Framework:** Flask with Gunicorn WSGI server
- **Endpoints:**
  - `GET /picus/list` - DynamoDB Scan operation
  - `POST /picus/put` - DynamoDB PutItem with UUID generation
  - `GET /picus/get/{key}` - DynamoDB GetItem
  - `GET /health` - Health check (independent of DynamoDB)
- **Error Handling:** Comprehensive try-catch with appropriate HTTP status codes
- **Production Ready:** Gunicorn with 2 workers, 2 threads per worker

#### Lambda Function (`handler.py`)
- **Runtime:** Python 3.10
- **Handler:** `handler.delete_item`
- **Event Format Support:** Both ALB and API Gateway event formats
- **Logic:** DynamoDB DeleteItem with ReturnValues='ALL_OLD' for existence check

### 2. Infrastructure Setup

#### DynamoDB
- **Table:** `picus_data`
- **Partition Key:** `object_id` (String)
- **Billing Mode:** On-demand (PAY_PER_REQUEST)
- **Region:** eu-central-1

#### ECS Fargate
- **Cluster:** `picus-cluster`
- **Service:** `picus-flask-service`
- **Task Definition:** `picus-task-definition`
- **Configuration:**
  - Launch Type: FARGATE
  - CPU: 0.25 vCPU (256 units)
  - Memory: 0.5 GB (512 MB)
  - Desired Count: 2 (high availability)
  - Network: awsvpc with public subnets
- **Deployment Strategy:**
  - Maximum Percent: 200% (allows 2x during deployment)
  - Minimum Healthy Percent: 100% (ensures 1 healthy task always)
  - Circuit Breaker: Enabled with automatic rollback

#### Lambda Function
- **Function Name:** `picus-delete-function`
- **Runtime:** python3.10
- **Memory:** 256 MB
- **Timeout:** Default (3 seconds)
- **Integration:** ALB Lambda Target Group

#### Application Load Balancer
- **Type:** Application Load Balancer (Internet-facing)
- **Scheme:** Internet-facing
- **Listener:** HTTP (port 80)
- **Routing:**
  - Default rule → ECS Target Group
  - DELETE /picus/* rule → Lambda Target Group
- **Health Checks:** ECS tasks via `/health` endpoint

**ALB Setup:**
1. Create security group (allow HTTP port 80 from internet)
2. Create target groups:
   - ECS target group (IP type, port 8080, health check: `/health`)
   - Lambda target group (Lambda type)
3. Create ALB in public subnets
4. Create listener with default action (forward to ECS target group)
5. Add listener rule for DELETE requests (priority 100, forward to Lambda target group)

**ALB Lambda Integration:**
- Lambda function registered to Lambda target group
- Lambda permission added for ALB invocation (`elasticloadbalancing.amazonaws.com` as principal)
- Path-based routing: DELETE /picus/* → Lambda, others → ECS
- Single DNS name for all endpoints

**ALB Setup:**
- Security group: Allow HTTP (port 80) from internet
- Target groups: `picus-ecs-tg` (ECS), `picus-lambda-tg` (Lambda)
- Listener rules: Path-based routing with HTTP method conditions
- DNS: Single ALB DNS name for all endpoints

**ALB Lambda Integration:**
- Lambda target group created for DELETE endpoint
- Lambda permission added for ALB invocation
- Path pattern: `/picus/*` with HTTP method `DELETE`
- All endpoints accessible via single ALB DNS

### 3. IAM Security (Least Privilege)

All IAM policies follow the principle of least privilege. Custom policies are defined in the `policies/` directory:

- **`picus-ecs-policy.json`** - ECS cluster, service, and task definition management
- **`picus-lambda-policy.json`** - Lambda function deployment and invocation
- **`picus-alb-policy.json`** - Application Load Balancer configuration
- **`picus-ecr-policy.json`** - ECR repository access for Docker images
- **`picus-iam-policy.json`** - IAM role and policy management
- **`picus-cloudwatch-logs-policy.json`** - CloudWatch Logs access
- **`picus-ec2-readonly-policy.json`** - EC2 read-only for network discovery
- **`picus-sts-policy.json`** - STS GetCallerIdentity

#### IAM Roles Created

**1. ECS Task Execution Role (`ecsTaskExecutionRole`)**
- **Purpose:** ECR image pull, CloudWatch Logs write
- **Trust Policy:** `ecs-tasks.amazonaws.com`
- **Attached Policies:** `AmazonECSTaskExecutionRolePolicy`

**2. ECS Task Role (`ecsTaskRole`)**
- **Purpose:** DynamoDB access for Flask application
- **Trust Policy:** `ecs-tasks.amazonaws.com`
- **Inline Policy:** DynamoDB GetItem, PutItem, Scan

**3. Lambda Execution Role (`picus-lambda-role`)**
- **Purpose:** DynamoDB delete access, ALB invoke permission
- **Trust Policy:** `lambda.amazonaws.com`
- **Attached Policies:** `AWSLambdaBasicExecutionRole`
- **Inline Policy:** DynamoDB DeleteItem, GetItem

### 4. CI/CD Pipeline

#### GitHub Actions Workflow (`.github/workflows/deploy.yml`)

**Three Jobs:**

1. **Test Job**
   - Python 3.10 environment setup
   - Dependency installation
   - Import tests (`test_app.py`)

2. **Build and Deploy (ECS)**
   - Docker image build (linux/amd64 platform)
   - ECR push (both commit SHA and `latest` tags)
   - ECS task definition update
   - ECS service deployment with zero-downtime

3. **Deploy Lambda**
   - Lambda deployment package creation
   - IAM role creation/update (automated)
   - Lambda function create/update
   - Concurrent update handling with polling

**Key Features:**
- Automated IAM role creation for Lambda
- Platform-specific Docker builds
- Zero-downtime ECS deployments
- Error handling and retry logic

**GitHub Actions Setup:**
- Required secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- Secrets location: Repository Settings → Secrets and variables → Actions
- Workflow triggers: Automatic on push to `main` branch
- Manual trigger: Actions tab → Run workflow

**Setup Steps:**
1. Add AWS credentials as GitHub secrets
2. Push to `main` branch triggers automatic deployment
3. Test job runs on every push
4. Build and deploy jobs run only on `main` branch

---


## Security Implementation

### IAM Security (Least Privilege)

All IAM policies are defined in the `policies/` directory and follow the principle of least privilege:

- **Resource-Specific Permissions:** Each policy targets only required resources (specific ARNs)
- **Action-Level Restrictions:** Only necessary actions are allowed
- **Condition Keys:** PassRole operations restricted to specific services
- **No Wildcard Permissions:** Except for list operations where required

**Policy Files:**
- `policies/picus-ecs-policy.json` - ECS resources only
- `policies/picus-lambda-policy.json` - Lambda function only
- `policies/picus-alb-policy.json` - ALB resources only
- `policies/picus-ecr-policy.json` - ECR repository only
- `policies/picus-iam-policy.json` - Specific IAM roles
- `policies/picus-cloudwatch-logs-policy.json` - Log groups only
- `policies/picus-ec2-readonly-policy.json` - Read-only EC2 access
- `policies/picus-sts-policy.json` - STS GetCallerIdentity

**Role Separation:**
- Execution role (ECR, Logs) vs Task role (DynamoDB)
- Lambda role (DynamoDB delete only)
- No cross-service permissions

### Network Security

- **Security Groups:** Restrictive inbound rules
- **VPC Configuration:** Public subnets for Fargate tasks
- **ALB:** Internet-facing with security group restrictions

### Application Security

- **Error Handling:** No sensitive data in error messages
- **Input Validation:** JSON validation, key extraction
- **HTTP Status Codes:** Appropriate status codes for all scenarios


## Testing & Validation

Comprehensive testing strategy and validation procedures are documented in [`tests/TESTING.md`](tests/TESTING.md).

**Summary:**
- **Unit Tests:** Import validation (`test_app.py`)
- **Integration Tests:** All CRUD operations, ALB routing, Lambda integration
- **End-to-End Tests:** Complete workflow validation
- **CI/CD:** Automated testing in GitHub Actions

**All tests passed successfully.**

---

## Performance & Scalability

- **ECS:** 2 tasks (high availability), zero-downtime deployments, auto-scaling ready
- **Lambda:** 256 MB memory, automatic concurrency scaling
- **DynamoDB:** On-demand billing (auto-scaling), UUID partition key for even distribution
- **ALB:** Health checks (30s interval), separate target groups for ECS and Lambda

---

## Cost Optimization

- **Implemented:** Minimal ECS resources (0.25 vCPU, 0.5 GB), Lambda for DELETE operations, on-demand DynamoDB, single ALB
- **Future:** DynamoDB provisioned capacity, ECS auto-scaling, CloudWatch Logs retention, ECR lifecycle policies

---

## Monitoring & Observability

- **CloudWatch Logs:** `/ecs/picus-flask-app`, `/aws/lambda/picus-delete-function`
- **Health Checks:** ECS `/health` endpoint (30s), ALB target health, Lambda via ALB
- **Metrics:** ECS (CPU, memory, task count), Lambda (invocations, duration, errors), ALB (requests, response times), DynamoDB (capacity, throttles)

---

## Deployment Process

### Initial Setup (One-Time)

1. **DynamoDB Table Creation**
   ```bash
   aws dynamodb create-table \
     --table-name picus_data \
     --attribute-definitions AttributeName=object_id,AttributeType=S \
     --key-schema AttributeName=object_id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region eu-central-1
   ```

2. **IAM Roles Creation**
   - ECS Task Execution Role
   - ECS Task Role
   - Lambda Execution Role

3. **ECR Repository Creation**
   ```bash
   aws ecr create-repository --repository-name picus-flask-app --region eu-central-1
   ```

4. **ECS Infrastructure**
   - Cluster creation
   - Task definition registration
   - Service creation

5. **ALB Setup**
   - Create security group (allow HTTP port 80)
   - Create target groups (ECS and Lambda)
   - Create load balancer with public subnets
   - Create listener with default rule (ECS)
   - Create listener rule for DELETE /picus/* (Lambda)
   - Register Lambda function to Lambda target group
   - Add Lambda permission for ALB invocation

### Automated Deployment (CI/CD)

**Trigger:** Push to `main` branch

**Process:**
1. Code checkout
2. Test execution
3. Docker image build and push to ECR
4. ECS task definition update
5. ECS service update (zero-downtime)
6. Lambda function update

**Deployment Time:** ~5-10 minutes

---

## API Documentation

For detailed API documentation, see [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md).

**Summary:**
- **Base URL:** `http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com`
- **Endpoints:** 
  - `GET /picus/list` - List all items
  - `POST /picus/put` - Create new item
  - `GET /picus/get/{key}` - Get item
  - `DELETE /picus/{key}` - Delete item
  - `GET /health` - Health check

---

## Configuration Files

### Deployment Configuration

1. **`ecs-task-definition.json`**
   - Task definition with container configuration
   - Resource allocation (CPU, memory)
   - Environment variables
   - Logging configuration
   - Health check definition

2. **`ecs-service-config.json`**
   - Service configuration
   - Network settings (subnets, security groups)
   - Deployment strategy
   - Load balancer configuration

3. **Lambda Deployment (AWS CLI)**
   - Lambda function deployed via AWS CLI in CI/CD pipeline
   - IAM role created/updated automatically
   - Environment variables configured via AWS CLI

4. **IAM Policies (`policies/` directory)**
   - All least-privilege IAM policies are stored in the `policies/` directory
   - See Security Implementation section for details

---

## Best Practices Implemented

This project follows AWS best practices and case requirements:

- **Zero-Downtime Deployment:** ECS service configured with rolling updates (maximumPercent: 200%, minimumHealthyPercent: 100%), circuit breaker enabled for automatic rollback
- **Least Privilege IAM:** All policies follow principle of least privilege (see `policies/` directory)
- **Security:** Resource-level permissions, condition keys, no hardcoded credentials, minimal security group access
- **Reliability:** Health checks for all components, error handling, high availability (2 ECS tasks)
- **Scalability:** Stateless design, auto-scaling ready, load balancing, on-demand DynamoDB
- **Observability:** CloudWatch Logs integration, health check endpoints, structured logging
- **DevOps:** Automated CI/CD pipeline, configuration-driven deployment, version control



## Project Information 

- **Developer:** Tunahan Yilmaz
- **Region:** eu-central-1 (Frankfurt)
- **Account ID:** 824912998004
- **Completion Date:** 2025-11-20
- **Status:** ✅ Production Ready
