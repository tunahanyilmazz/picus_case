# IAM Policies - Least Privilege Configuration

This directory contains all IAM policies created for the Picus Case Study project. All policies follow the **principle of least privilege**, granting only the minimum permissions required for each service.

## Policy Files

### 1. `picus-ecs-policy.json`
**Purpose:** ECS cluster, service, and task definition management

**Permissions:**
- Create, describe, update ECS clusters and services
- Register, describe, list task definitions
- List and describe tasks
- Resource-specific: Only `picus-cluster`, `picus-flask-service`, `picus-task-definition`

### 2. `picus-lambda-policy.json`
**Purpose:** Lambda function deployment and invocation

**Permissions:**
- Create, get, update Lambda function
- Invoke function
- Add permissions for ALB integration
- Resource-specific: Only `picus-delete-function`

### 3. `picus-alb-policy.json`
**Purpose:** Application Load Balancer configuration

**Permissions:**
- Create, describe, modify load balancers
- Create, describe, modify target groups
- Register/deregister targets
- Create, describe, modify listeners and rules
- Resource-specific: Only `picus-*` resources

### 4. `picus-ecr-policy.json`
**Purpose:** ECR repository access for Docker images

**Permissions:**
- Get authorization token (for Docker login)
- Describe repositories
- List, describe images
- Batch get images (for pull)
- Put image, upload layers (for push)
- Resource-specific: Only `picus-flask-app` repository

### 5. `picus-iam-policy.json`
**Purpose:** IAM role and policy management

**Permissions:**
- Create, get, manage IAM roles (ecsTaskExecutionRole, ecsTaskRole, picus-lambda-role)
- Create, get, manage IAM policies (Picus* policies)
- Attach/detach user policies (self-management)
- PassRole with condition (only to ECS and Lambda services)
- Resource-specific: Only project-specific roles and policies

### 6. `picus-cloudwatch-logs-policy.json`
**Purpose:** CloudWatch Logs access

**Permissions:**
- Create log groups and streams
- Put log events
- Describe log groups and streams
- Get log events
- Resource-specific: Only `/ecs/picus-*` and `/aws/lambda/picus-*` log groups

### 7. `picus-ec2-readonly-policy.json`
**Purpose:** EC2 read-only access for network discovery

**Permissions:**
- Describe VPCs, subnets, security groups
- Describe availability zones
- Describe network interfaces
- Resource: All resources (read-only operations)

### 8. `picus-sts-policy.json`
**Purpose:** STS GetCallerIdentity

**Permissions:**
- GetCallerIdentity (for account ID verification)
- Resource: All resources

## Usage

### Creating Policies in AWS

```bash
# Example: Create ECS policy
aws iam create-policy \
  --policy-name PicusECSPolicy \
  --policy-document file://policies/picus-ecs-policy.json

# Attach to user
aws iam attach-user-policy \
  --user-name picus_user \
  --policy-arn arn:aws:iam::824912998004:policy/PicusECSPolicy
```

### Updating Policies

```bash
# Create new policy version
aws iam create-policy-version \
  --policy-arn arn:aws:iam::824912998004:policy/PicusECSPolicy \
  --policy-document file://policies/picus-ecs-policy.json \
  --set-as-default
```

## Security Best Practices

1. **Least Privilege:** Each policy grants only necessary permissions
2. **Resource-Specific:** Policies target specific ARNs, not wildcards
3. **Action-Level:** Only required actions are included
4. **Condition Keys:** PassRole operations restricted to specific services
5. **No Cross-Service:** Policies don't grant permissions across unrelated services

## Policy Size Limits

- **User Policy Limit:** 10 policies per user
- **Policy Size Limit:** 2048 bytes per policy
- **Statement Limit:** No hard limit, but size matters

## Notes

- All policies are designed for `eu-central-1` region
- Account ID: `824912998004`
- Replace account ID and region if deploying to different environment

