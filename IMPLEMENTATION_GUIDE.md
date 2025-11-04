# Pharmacy CDSS Implementation Guide

## Progress Summary

### ✅ Completed Components

1. **System Architecture** (`ARCHITECTURE.md`)
   - Complete technology stack definition
   - Microservices architecture design
   - Security and compliance framework
   - Scalability considerations
   - Deployment strategy

2. **Database Schema** (`database/schema.sql` & `prisma/schema.prisma`)
   - Full relational database design
   - 20+ tables covering all entities
   - Audit logging structure
   - PHIPA/PIPEDA compliance features
   - Performance indexes

3. **Backend Foundation** (Partial)
   - Package.json with all dependencies
   - TypeScript configuration
   - Environment configuration
   - Type definitions
   - Server setup
   - Logger utility

## 🚧 Remaining Implementation Tasks

### Backend API (In Progress)

####Files Needed:

1. **src/utils/prisma.ts** - Prisma client singleton
2. **src/utils/redis.ts** - Redis client for caching
3. **src/middleware/auth.ts** - Authentication middleware
4. **src/middleware/errorHandler.ts** - Global error handling
5. **src/middleware/requestLogger.ts** - Request logging
6. **src/routes/index.ts** - Main router
7. **src/routes/prescription.routes.ts** - Prescription endpoints
8. **src/routes/alert.routes.ts** - Alert endpoints
9. **src/routes/intervention.routes.ts** - Intervention logging
10. **src/controllers/prescription.controller.ts** - Business logic
11. **src/services/rulesEngine.service.ts** - DTP detection engine
12. **src/services/nlp.service.ts** - SIG parsing
13. **src/services/drugDatabase.service.ts** - Drug knowledge base

### Rules Engine (Core Logic)

The rules engine is the heart of the system. Key components:

```typescript
// High-level structure
class RulesEngine {
  async analyzePrescription(profile, prescription): Promise<Alert[]> {
    const alerts = [];

    // 1. Check drug-drug interactions
    alerts.push(...await this.checkInteractions(profile, prescription));

    // 2. Check allergies
    alerts.push(...await this.checkAllergies(profile, prescription));

    // 3. Check dosage
    alerts.push(...await this.checkDosage(prescription, profile));

    // 4. Check duplications
    alerts.push(...await this.checkDuplicateTherapy(profile, prescription));

    // 5. Check therapy gaps
    alerts.push(...await this.checkTherapyGaps(profile));

    // 6. Check Health Canada advisories
    alerts.push(...await this.checkAdvisories(prescription));

    // 7. Check contraindications
    alerts.push(...await this.checkContraindications(profile, prescription));

    // Sort by severity and priority
    return alerts.sort((a, b) => a.priority - b.priority);
  }
}
```

### NLP Module

SIG parsing implementation approach:

```typescript
// Parse free-text prescription directions
class SIGParser {
  parse(sigText: string): SIGStructured {
    // 1. Tokenize text
    // 2. Extract dose (e.g., "one tablet", "5mg")
    // 3. Extract route (e.g., "by mouth", "PO")
    // 4. Extract frequency (e.g., "twice daily", "BID")
    // 5. Extract timing (e.g., "after meals", "at bedtime")
    // 6. Extract duration (e.g., "for 10 days")

    return {
      dose,
      doseUnit,
      route,
      frequency,
      timing,
      duration,
      durationUnit
    };
  }
}
```

### Frontend Dashboard

Tech stack: React + TypeScript + Material-UI

Key components:
1. **MedicationTimeline.tsx** - Visual timeline of patient meds
2. **AlertCard.tsx** - Individual alert display
3. **AlertList.tsx** - List of all alerts with filtering
4. **InterventionModal.tsx** - Log interventions
5. **PatientProfile.tsx** - Display patient info

### Integration Layer

Create adapters for each PMS:

```typescript
// Example Kroll adapter
class KrollAdapter implements PMSAdapter {
  async getPatientProfile(patientId: string): Promise<PatientProfile> {
    // Connect to Kroll API or DB
    // Extract patient data
    // Transform to our standard format
    // Return PatientProfile
  }

  async submitAlert(alert: Alert): Promise<void> {
    // Send alert back to Kroll system
  }
}
```

## 📋 API Endpoints to Implement

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/submit-profile` | Submit patient profile |
| POST | `/api/v1/submit-prescription` | Submit prescription for analysis |
| GET | `/api/v1/alerts/:profileId` | Get alerts for a profile |
| POST | `/api/v1/log-intervention` | Log pharmacist intervention |
| POST | `/api/v1/feedback` | Submit alert feedback |

### Auth Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/refresh` | Refresh JWT token |
| POST | `/api/v1/auth/logout` | Logout user |

### Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/pharmacies` | List pharmacies |
| POST | `/api/v1/admin/pharmacies` | Create pharmacy |
| GET | `/api/v1/admin/stats` | System statistics |
| GET | `/api/v1/admin/audit-logs` | Audit log access |

## 🔐 Security Implementation Checklist

- [ ] API key authentication for PMS systems
- [ ] JWT authentication for users
- [ ] Rate limiting per IP and per API key
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (Prisma ORM)
- [ ] XSS prevention
- [ ] CSRF tokens for state-changing operations
- [ ] Encryption at rest (database level)
- [ ] Encryption in transit (TLS 1.3)
- [ ] Audit logging for all PHI access
- [ ] Data minimization (only collect necessary data)
- [ ] Secure session management
- [ ] Password hashing (bcrypt)
- [ ] MFA support

## 🧪 Testing Strategy

### Unit Tests
- Test each rules engine function
- Test NLP parser
- Test utility functions
- Test data transformations

### Integration Tests
- Test API endpoints end-to-end
- Test database operations
- Test external API calls
- Test Redis caching

### Load Testing
- Simulate 1000 concurrent prescription checks
- Test response time under load
- Test database connection pooling
- Test Redis performance

### Security Testing
- OWASP top 10 vulnerability scanning
- Penetration testing
- API security testing
- Authentication bypass attempts

## 📊 Sample Data

Create sample data for testing:

```typescript
// Sample patient with multiple conditions
const samplePatient: PatientProfile = {
  externalPatientId: 'TEST001',
  demographics: {
    ageYears: 68,
    gender: 'male',
    weightKg: 85,
  },
  conditions: [
    { conditionName: 'Type 2 Diabetes', isActive: true },
    { conditionName: 'Hypertension', isActive: true },
    { conditionName: 'Chronic Kidney Disease Stage 3', isActive: true }
  ],
  allergies: [
    {
      allergenName: 'Penicillin',
      allergenType: 'drug',
      severity: 'severe',
      reaction: 'Anaphylaxis',
      isActive: true
    }
  ],
  medications: [
    {
      drugName: 'Metformin',
      din: '02230113',
      strength: '500mg',
      sigText: 'Take 1 tablet by mouth twice daily with meals',
      isActive: true,
      status: 'active'
    },
    {
      drugName: 'Ramipril',
      din: '02240806',
      strength: '10mg',
      sigText: 'Take 1 capsule once daily',
      isActive: true,
      status: 'active'
    },
    // Add more medications
  ],
  labValues: [
    {
      testName: 'Creatinine',
      value: 1.8,
      unit: 'mg/dL',
      testDate: new Date('2024-01-15')
    }
  ]
};
```

## 🚀 Deployment Guide

### Docker Deployment

```dockerfile
# Dockerfile for backend
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY prisma ./prisma/
RUN npx prisma generate

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: pharmacy_cdss
      POSTGRES_USER: cdss_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://cdss_user:${DB_PASSWORD}@postgres:5432/pharmacy_cdss
      REDIS_HOST: redis
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3001:3001"
    depends_on:
      - backend

volumes:
  postgres_data:
```

### Kubernetes (AWS EKS - Canada Region)

```yaml
# Basic deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pharmacy-cdss-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pharmacy-cdss-backend
  template:
    metadata:
      labels:
        app: pharmacy-cdss-backend
    spec:
      containers:
      - name: backend
        image: pharmacy-cdss-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: connection-string
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
```

## 🔄 CI/CD Pipeline

### GitHub Actions Example

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t pharmacy-cdss:${{ github.sha }} .
      - name: Push to ECR
        run: |
          aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin ${{ secrets.ECR_REGISTRY }}
          docker push pharmacy-cdss:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to EKS
        run: |
          kubectl set image deployment/pharmacy-cdss-backend backend=pharmacy-cdss:${{ github.sha }}
```

## 📖 Next Steps

1. **Complete Backend API** - Finish all route handlers and controllers
2. **Implement Rules Engine** - Core DTP detection logic
3. **Build Frontend Dashboard** - React application
4. **Create Integration Adapters** - Kroll, HealthWatch, etc.
5. **Populate Drug Database** - Import Canadian drug data
6. **Testing Suite** - Unit, integration, and E2E tests
7. **Documentation** - API docs, user guides, deployment docs
8. **Security Audit** - Third-party security assessment
9. **Pilot Deployment** - Test with 2-3 pharmacies
10. **Full Launch** - Roll out to all pharmacies

## 📞 Support & Resources

- **HL7 FHIR Canada**: https://fhir.infoway-inforoute.ca/
- **Health Canada DPD API**: https://health-products.canada.ca/api
- **RxVigilance**: https://www.vigilance.ca/
- **PHIPA Guidelines**: https://www.ipc.on.ca/health/
- **Kroll Integration**: Contact McKesson Canada

## 🎯 Success Metrics

Track these KPIs:
- Number of DTPs caught per day
- Alert override rate (target < 20%)
- Average response time (target < 1s)
- System uptime (target > 99.9%)
- User satisfaction score
- Number of interventions logged
- Prevented adverse drug events (estimated)

---

**Status**: Foundation complete, core implementation in progress
**Last Updated**: 2025-11-01
**Next Milestone**: Complete Rules Engine & API Endpoints
