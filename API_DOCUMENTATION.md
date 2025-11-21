# API Documentation

## Base URL

```
http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com
```

---

## Endpoints

### 1. GET /picus/list

Lists all items in the DynamoDB table.

**Request:**
```bash
curl http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com/picus/list
```

**Response (200):**
```json
[
  {
    "object_id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "Example",
    "value": "data"
  }
]
```

**Response (500):**
```json
{
  "error": "Could not list items"
}
```

---

### 2. POST /picus/put

Creates a new item. The `object_id` is automatically generated as a UUID.

**Request:**
```bash
curl -X POST http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com/picus/put \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "value": 123}'
```

**Response (201):**
```json
{
  "object_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

**Response (500):**
```json
{
  "error": "Could not save item"
}
```

---

### 3. GET /picus/get/{key}

Retrieves an item with the specified `object_id`.

**Request:**
```bash
curl http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com/picus/get/123e4567-e89b-12d3-a456-426614174000
```

**Response (200):**
```json
{
  "object_id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "Test",
  "value": 123
}
```

**Response (404):**
```json
{
  "error": "Item with key '123e4567-e89b-12d3-a456-426614174000' not found"
}
```

---

### 4. DELETE /picus/{key}

Deletes an item with the specified `object_id`.

**Request:**
```bash
curl -X DELETE http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com/picus/123e4567-e89b-12d3-a456-426614174000
```

**Response (200):**
```json
{
  "message": "Item with key \"123e4567-e89b-12d3-a456-426614174000\" deleted successfully"
}
```

**Response (404):**
```json
{
  "error": "Item with key \"123e4567-e89b-12d3-a456-426614174000\" not found"
}
```

**Response (400):**
```json
{
  "error": "Missing key path parameter"
}
```

---

### 5. GET /health

Health check endpoint. Used to verify the health status of ECS tasks. Does not depend on DynamoDB.

**Request:**
```bash
curl http://picus-alb-1673797137.eu-central-1.elb.amazonaws.com/health
```

**Response (200):**
```json
{
  "status": "healthy"
}
```

---

## Response Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (missing/invalid parameters) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Notes

- All endpoints are accessible under a single ALB DNS
- ECS endpoints (list, put, get) run on ECS Fargate
- DELETE endpoint runs on Lambda
- `object_id` is automatically generated in UUID format
- Health check endpoint does not depend on DynamoDB

---

**Last Updated:** 2025-11-20
