# Pharmacy CDSS - Testing Guide

Complete guide for testing the Pharmacy Clinical Decision Support System.

---

## Quick Start (3 Steps)

### Step 1: Start the System

```bash
# Option A: Using Docker (Recommended - Easiest)
cd C:\Users\meher\pharmacy-cdss
docker-compose up -d

# Wait 30 seconds for services to initialize
# Check status:
docker-compose ps
```

### Step 2: Verify System Health

```powershell
# PowerShell
curl http://localhost:3000/health

# Expected response:
# {
#   "status": "healthy",
#   "timestamp": "2025-11-03T...",
#   "database": "connected",
#   "redis": "connected"
# }
```

### Step 3: Run Quick Test

```powershell
# Run the automated test script
cd C:\Users\meher\pharmacy-cdss
.\test-quick.ps1
```

**That's it!** The script will test all major features.

---

## Detailed Testing Options

### Option 1: Automated PowerShell Script ⚡ (EASIEST)

```powershell
cd C:\Users\meher\pharmacy-cdss
.\test-quick.ps1
```

**Tests:**
- ✅ Health check
- ✅ User registration
- ✅ Login/authentication
- ✅ User profile retrieval
- ✅ **Prescription checking (Rules Engine)**
- ✅ Alert retrieval

---

### Option 2: VS Code REST Client 🎯 (INTERACTIVE)

1. **Install Extension:**
   - Open VS Code
   - Install "REST Client" extension by Huachao Mao

2. **Open Test File:**
   ```
   C:\Users\meher\pharmacy-cdss\test-api.http
   ```

3. **Click "Send Request"** above any `###` section

4. **Test the Core Feature:**
   - Scroll to "PRESCRIPTION CHECKING - MAIN FEATURE"
   - Click "Send Request" for test #4
   - See the rules engine detect drug therapy problems!

---

### Option 3: Postman 📮

1. **Import Collection:**
   - Open Postman
   - Import → File → Select `test-api.http`
   - Or manually create requests from the file

2. **Set Environment Variables:**
   ```
   baseUrl: http://localhost:3000
   apiVersion: v1
   authToken: (will be set after login)
   ```

3. **Test Workflow:**
   ```
   Register → Login → Save Token → Check Prescription
   ```

---

### Option 4: Manual cURL Commands 💻

#### 1. Health Check
```bash
curl http://localhost:3000/health
```

#### 2. Register User
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "pharmacist@test.ca",
    "password": "SecurePass123!",
    "firstName": "Test",
    "lastName": "Pharmacist",
    "role": "pharmacist",
    "pharmacyId": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

#### 3. Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "pharmacist@test.ca",
    "password": "SecurePass123!"
  }'
```

**Save the token from response!**

#### 4. Test Prescription Check (CORE FEATURE)
```bash
curl -X POST http://localhost:3000/api/v1/prescriptions/check \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "prescription": {
      "din": "02242705",
      "drugName": "Metformin 500mg",
      "strength": "500mg",
      "sigText": "Take 1 tablet twice daily"
    },
    "patientProfile": {
      "externalPatientId": "PT-001",
      "demographics": {
        "ageYears": 65,
        "gender": "male"
      },
      "medications": [],
      "allergies": [],
      "conditions": [
        {
          "conditionName": "Type 2 Diabetes",
          "isActive": true
        }
      ]
    }
  }'
```

---

## Testing Scenarios

### Scenario 1: Drug-Drug Interaction Detection

**Test:** Prescribe Warfarin to patient on Aspirin

```json
{
  "prescription": {
    "drugName": "Warfarin 5mg",
    "din": "02230814"
  },
  "patientProfile": {
    "medications": [
      {
        "drugName": "Aspirin 81mg",
        "din": "02247074",
        "isActive": true
      }
    ]
  }
}
```

**Expected:** CRITICAL alert for bleeding risk

---

### Scenario 2: Allergy Alert

**Test:** Prescribe Amoxicillin to penicillin-allergic patient

```json
{
  "prescription": {
    "drugName": "Amoxicillin 500mg",
    "din": "02243085"
  },
  "patientProfile": {
    "allergies": [
      {
        "allergenName": "Penicillin",
        "reaction": "Anaphylaxis",
        "severity": "severe",
        "isActive": true
      }
    ]
  }
}
```

**Expected:** CRITICAL allergy alert with cross-sensitivity warning

---

### Scenario 3: Dosage Validation

**Test:** High dose in elderly patient

```json
{
  "prescription": {
    "drugName": "Digoxin 0.25mg",
    "sigStructured": {
      "dose": 0.25,
      "unit": "mg",
      "frequency": "twice daily"
    }
  },
  "patientProfile": {
    "demographics": {
      "ageYears": 85,
      "weightKg": 55
    },
    "labValues": [
      {
        "testName": "Serum Creatinine",
        "value": 1.8
      }
    ]
  }
}
```

**Expected:** Dosage alerts for geriatric + renal adjustment

---

### Scenario 4: Duplicate Therapy

**Test:** Two drugs from same class

```json
{
  "prescription": {
    "drugName": "Ramipril 10mg",
    "din": "02246004"
  },
  "patientProfile": {
    "medications": [
      {
        "drugName": "Lisinopril 20mg",
        "din": "02068508",
        "isActive": true
      }
    ]
  }
}
```

**Expected:** Therapeutic duplication alert (both ACE inhibitors)

---

### Scenario 5: Therapy Gap

**Test:** Diabetic patient without ACE/ARB

```json
{
  "prescription": {
    "drugName": "Metformin 500mg"
  },
  "patientProfile": {
    "conditions": [
      {
        "conditionName": "Type 2 Diabetes Mellitus",
        "isActive": true
      }
    ],
    "medications": []
  }
}
```

**Expected:** Informational alert recommending ACE/ARB for cardio-renal protection

---

## Troubleshooting

### Issue: Connection Refused

**Solution:**
```bash
# Check if services are running
docker-compose ps

# Check logs
docker-compose logs backend

# Restart services
docker-compose restart
```

### Issue: Database Connection Error

**Solution:**
```bash
# Check database is ready
docker-compose logs postgres

# Wait for initialization
docker-compose up -d
sleep 30
```

### Issue: Authentication Failed

**Solution:**
```bash
# Check JWT_SECRET is set
docker-compose exec backend printenv | grep JWT

# Re-register user
curl -X POST http://localhost:3000/api/v1/auth/register ...
```

### Issue: No Alerts Generated

**Reason:** Drug database is not populated yet (needs real drug data)

**Current Behavior:** The rules engine logic is complete, but needs:
1. Drug interaction database populated
2. Dosing guidelines loaded
3. Health Canada advisories imported

**Workaround:** The API will process the request successfully, but may not generate alerts without drug database data.

---

## Manual Database Setup (Alternative to Docker)

If not using Docker:

### 1. Install PostgreSQL
```bash
# Download and install PostgreSQL 15+
# Create database
psql -U postgres
CREATE DATABASE pharmacy_cdss;
CREATE USER cdss_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE pharmacy_cdss TO cdss_user;
\q

# Load schema
psql -U cdss_user -d pharmacy_cdss -f database/schema.sql
```

### 2. Install Redis
```bash
# Windows: Download from https://redis.io/download
# Or use Chocolatey: choco install redis-64

# Start Redis
redis-server
```

### 3. Configure Backend
```bash
cd backend
cp .env.example .env

# Edit .env:
DATABASE_URL="postgresql://cdss_user:your_password@localhost:5432/pharmacy_cdss"
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-secret-key-here
```

### 4. Install Dependencies
```bash
npm install
```

### 5. Generate Prisma Client
```bash
npx prisma generate
```

### 6. Run Backend
```bash
npm run dev
# Backend runs on http://localhost:3000
```

---

## Performance Testing

### Load Testing (k6)

```bash
# Install k6: https://k6.io/docs/getting-started/installation/

# Create load test script
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const res = http.get('http://localhost:3000/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
}
EOF

# Run load test
k6 run load-test.js
```

---

## Database Inspection

### Using Prisma Studio
```bash
cd backend
npx prisma studio
# Opens GUI at http://localhost:5555
```

### Using psql
```bash
# Connect to database
docker-compose exec postgres psql -U cdss_user -d pharmacy_cdss

# View tables
\dt

# Query alerts
SELECT alert_id, alert_type, severity, title
FROM alerts
ORDER BY created_at DESC
LIMIT 10;

# Query prescription checks
SELECT check_id, alerts_generated, processing_time_ms
FROM prescription_checks
ORDER BY created_at DESC
LIMIT 10;
```

---

## Next Steps

1. **Populate Drug Database**
   - Import Canadian drug data
   - Load interaction database
   - Set up Health Canada advisory feed

2. **Add More Test Cases**
   - Create comprehensive test suite
   - Add unit tests for rules engine
   - Integration tests for API

3. **Deploy to Cloud**
   - AWS/Azure Canada region
   - Set up monitoring
   - Configure CI/CD pipeline

---

## Support

- **Documentation:** See README.md, ARCHITECTURE.md
- **API Endpoints:** `http://localhost:3000/api/v1` (when running)
- **Health Check:** `http://localhost:3000/health`
- **Logs:** `docker-compose logs -f backend`

---

**Happy Testing! 🧪**
