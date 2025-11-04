# Pharmacy CDSS - PMS Integration Guide

## For Pharmacy IT Teams & System Administrators

This guide explains how to integrate the Pharmacy Clinical Decision Support System (CDSS) with existing Pharmacy Management Systems (PMS) such as Kroll, HealthWatch, PropelRx, and FillWare.

---

## Table of Contents

1. [Overview](#overview)
2. [Integration Methods](#integration-methods)
3. [Kroll Integration (Step-by-Step)](#kroll-integration)
4. [Embedded Widget Setup](#embedded-widget-setup)
5. [API Integration](#api-integration)
6. [Security & Compliance](#security--compliance)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### What This System Does

The Pharmacy CDSS is an **add-on module** that integrates with your existing PMS to provide real-time clinical decision support. It:

- ✅ Monitors new prescriptions as they're entered
- ✅ Automatically extracts patient profiles and medication histories
- ✅ Analyzes for 7 types of Drug Therapy Problems (DTPs)
- ✅ Displays color-coded alerts in your PMS interface
- ✅ **Does NOT replace** your PMS - it augments it

### Architecture

```
┌──────────────────────────────────────┐
│  Kroll PMS (Your Existing System)   │
│  - Pharmacists enter prescriptions  │
│  - Patient data stored here          │
└────────┬─────────────────────────────┘
         │
         │ ① Connector extracts data
         ▼
┌──────────────────────────────────────┐
│  CDSS Connector Middleware           │
│  - Monitors for new Rx               │
│  - Extracts patient profile          │
│  - Transforms to FHIR (optional)     │
└────────┬─────────────────────────────┘
         │
         │ ② HTTP API Call
         ▼
┌──────────────────────────────────────┐
│  CDSS Rules Engine API               │
│  - Checks 7 DTP types                │
│  - Generates alerts                  │
│  - Returns results <1 second         │
└────────┬─────────────────────────────┘
         │
         │ ③ Alerts displayed
         ▼
┌──────────────────────────────────────┐
│  Alert Display (Choose One)          │
│  A) Embedded iframe widget in Kroll  │
│  B) Separate desktop alert popup     │
│  C) Email/SMS notification           │
└──────────────────────────────────────┘
```

---

## Integration Methods

You have **3 integration options**:

### Method 1: Embedded Widget (Recommended)
- **Best for:** Seamless user experience
- **How:** iframe embedded in Kroll interface
- **User sees:** Alerts appear directly in Kroll's UI
- **Setup difficulty:** Medium
- **Requires:** Ability to customize Kroll UI (may need vendor support)

### Method 2: Standalone Desktop App
- **Best for:** Quick deployment without PMS modifications
- **How:** Separate window that monitors Kroll database
- **User sees:** Alert popup when new prescription entered
- **Setup difficulty:** Easy
- **Requires:** Read-only database access to Kroll

### Method 3: Full API Integration
- **Best for:** Advanced customization
- **How:** Direct API calls from Kroll (if Kroll supports plugins)
- **User sees:** Custom implementation
- **Setup difficulty:** Hard
- **Requires:** Kroll plugin development OR official API access

---

## Kroll Integration (Step-by-Step)

### Prerequisites

1. ✅ Kroll PMS installed and running
2. ✅ Database access credentials (read-only recommended)
3. ✅ Network connectivity between Kroll server and CDSS server
4. ✅ CDSS backend running on accessible server

### Option A: Embedded Widget Integration

#### Step 1: Deploy CDSS Backend

```bash
# On your CDSS server (e.g., pharmacy-cdss-server.local)
cd /opt/pharmacy-cdss/backend
npm install
npm run build
npm run start

# Verify running:
curl http://localhost:3000/health
# Expected: {"status":"healthy",...}
```

#### Step 2: Deploy CDSS Frontend

```bash
cd /opt/pharmacy-cdss/frontend
npm install
npm run build

# Serve via nginx or similar
# Frontend should be accessible at: http://pharmacy-cdss-server.local
```

#### Step 3: Configure Database Connection

Edit `backend/.env`:

```env
# Kroll Database (Read-Only)
KROLL_DB_URL=postgresql://readonly_user:password@kroll-db-server:5432/kroll_pharmacy

# CDSS API Settings
NODE_ENV=production
PORT=3000
CORS_ORIGIN=http://kroll-pms.pharmacy.local,http://pharmacy-cdss-server.local

# Security
JWT_SECRET=<generate-strong-random-key>
ENCRYPTION_KEY=<generate-32-character-key>
```

**Important:** Use a read-only database user for security:

```sql
-- Execute on Kroll database server
CREATE USER cdss_readonly WITH PASSWORD 'secure_password_here';
GRANT CONNECT ON DATABASE kroll_pharmacy TO cdss_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cdss_readonly;
```

#### Step 4: Start PMS Connector

Create connector startup script:

```javascript
// /opt/pharmacy-cdss/start-connector.js
const { PMSConnector } = require('./backend/dist/connectors/pms.connector');

const connector = new PMSConnector({
  pmsType: 'kroll',
  pharmacyId: 'YOUR_PHARMACY_ID',
  pollingIntervalMs: 30000, // Check every 30 seconds
  apiUrl: 'http://localhost:3000/api/v1',
  apiKey: 'YOUR_API_KEY'
});

connector.start();
console.log('CDSS Connector started - monitoring Kroll for new prescriptions...');
```

Run as a service:

```bash
# Using PM2 (process manager)
npm install -g pm2
pm2 start /opt/pharmacy-cdss/start-connector.js --name cdss-connector
pm2 save
pm2 startup
```

#### Step 5: Embed Widget in Kroll UI

**Option 5A: If Kroll allows UI customization:**

Add iframe to Kroll's prescription verification screen:

```html
<!-- Add to Kroll prescription screen template -->
<div id="cdss-alerts-container" style="width: 400px; height: 600px; border: 1px solid #ccc;">
  <iframe
    id="cdss-widget"
    src="http://pharmacy-cdss-server.local/widget?prescription_id=DYNAMIC_RX_ID"
    width="100%"
    height="100%"
    frameborder="0"
    sandbox="allow-scripts allow-same-origin"
  ></iframe>
</div>

<script>
// Update iframe URL when prescription changes
function updateCDSSWidget(prescriptionId) {
  const iframe = document.getElementById('cdss-widget');
  iframe.src = `http://pharmacy-cdss-server.local/widget?prescription_id=${prescriptionId}`;
}

// Call when pharmacist opens a prescription for verification
// (Hook into Kroll's prescription view event)
Kroll.on('prescription.opened', function(rxData) {
  updateCDSSWidget(rxData.prescriptionId);
});
</script>
```

**Option 5B: If Kroll doesn't allow customization:**

Contact Kroll support to request iframe integration capability, OR use standalone desktop app (Method 2).

---

### Option B: Standalone Monitor Desktop App

If you can't modify Kroll's UI, use a standalone monitoring app:

#### Step 1: Install Desktop Monitor

```bash
# Download pre-built desktop app
wget https://pharmacy-cdss.example.com/downloads/cdss-monitor-windows.exe

# OR build from source
cd /opt/pharmacy-cdss/desktop-monitor
npm install
npm run build:windows
```

#### Step 2: Configure Desktop Monitor

Edit `config.json`:

```json
{
  "krollDatabaseUrl": "postgresql://readonly_user:password@localhost:5432/kroll_pharmacy",
  "cdssApiUrl": "http://pharmacy-cdss-server.local:3000/api/v1",
  "pharmacyId": "PHARMACY_001",
  "pollingInterval": 30,
  "showDesktopNotifications": true,
  "playAudioAlerts": true
}
```

#### Step 3: Install on Pharmacist Workstations

1. Copy `cdss-monitor.exe` to each workstation
2. Add to Windows Startup folder for auto-start
3. Configure database connection via GUI

**User Experience:**
- Monitor runs in system tray
- When pharmacist enters new prescription in Kroll → Alert popup appears
- Pharmacist can view/dismiss alerts

---

## Embedded Widget Setup

### Widget URL Parameters

The embeddable widget accepts these URL parameters:

```
http://your-cdss-server.local/widget?prescription_id=RX12345&patient_id=PAT789
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `prescription_id` | Yes | Kroll prescription ID to check |
| `patient_id` | No | Patient ID (widget will fetch if not provided) |
| `theme` | No | `light` or `dark` (default: light) |
| `compact` | No | `true` for minimal UI (default: false) |

### Widget Communication (PostMessage API)

The widget can communicate with the parent Kroll window:

**Parent (Kroll) → Widget:**

```javascript
// Refresh alerts
const widget = document.getElementById('cdss-widget').contentWindow;
widget.postMessage({
  type: 'refresh_alerts'
}, 'http://pharmacy-cdss-server.local');

// Dismiss specific alert
widget.postMessage({
  type: 'dismiss_alert',
  data: { alertId: 'alert-123' }
}, 'http://pharmacy-cdss-server.local');
```

**Widget → Parent (Kroll):**

```javascript
// Listen for widget events in parent window
window.addEventListener('message', function(event) {
  if (event.data.source === 'pharmacy-cdss-widget') {
    const { type, data } = event.data;

    switch (type) {
      case 'alerts_loaded':
        console.log(`Loaded ${data.count} alerts, ${data.criticalCount} critical`);
        // Update Kroll UI badge/indicator
        updateAlertBadge(data.criticalCount);
        break;

      case 'alert_acknowledged':
        console.log(`Alert ${data.alertId} acknowledged`);
        // Log in Kroll audit trail
        Kroll.logIntervention(data.alertId);
        break;

      case 'error':
        console.error('Widget error:', data.message);
        break;
    }
  }
});
```

---

## API Integration

### Authentication

All API calls require an API key in the header:

```bash
curl -X POST http://your-cdss-server.local:3000/api/v1/prescriptions/check \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY_HERE" \
  -d '{...}'
```

**Get API Key:**
1. Contact CDSS administrator
2. OR generate via admin dashboard: http://your-cdss-server.local/admin/api-keys

### Check Prescription Endpoint

**Endpoint:** `POST /api/v1/prescriptions/check`

**Request:**

```json
{
  "prescription": {
    "drugName": "Warfarin",
    "drugDIN": "02230716",
    "strength": "5mg",
    "sig": "Take 1 tablet once daily as directed",
    "prescriber": "Dr. Williams"
  },
  "patientProfile": {
    "patientId": "KROLL_PAT_12345",
    "age": 74,
    "gender": "M",
    "allergies": ["Penicillin", "Sulfa drugs"],
    "currentMedications": [
      {
        "drugName": "Aspirin",
        "strength": "81mg",
        "directions": "Take 1 tablet daily"
      },
      {
        "drugName": "Metformin",
        "strength": "500mg",
        "directions": "Take 1 tablet twice daily"
      }
    ],
    "conditions": ["Type 2 Diabetes", "Hypertension"],
    "recentLabValues": [
      {
        "testName": "INR",
        "value": 2.3,
        "unit": "",
        "date": "2024-11-01"
      }
    ]
  }
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "alerts": [
      {
        "alertId": "alert-98765",
        "alertType": "INTERACTION",
        "severity": "CRITICAL",
        "priority": 1,
        "title": "⚠️ CRITICAL: Drug-Drug Interaction",
        "description": "Major interaction between Warfarin and Aspirin. Increased risk of bleeding.",
        "suggestedAction": "Contact prescriber. Consider alternative antiplatelet therapy or close INR monitoring.",
        "affectedMedications": ["Warfarin", "Aspirin"],
        "referenceSource": "Drug Interaction Database",
        "mechanism": "Both drugs affect coagulation through different mechanisms, significantly increasing bleeding risk"
      }
    ],
    "processingTimeMs": 347
  }
}
```

### HL7 FHIR Support

The system can accept FHIR R4 bundles:

**Endpoint:** `POST /api/v1/fhir/check`

**Request:**

```json
{
  "resourceType": "Bundle",
  "type": "collection",
  "entry": [
    {
      "resource": {
        "resourceType": "Patient",
        "id": "PAT123",
        "name": [{"family": "Smith", "given": ["John"]}],
        "birthDate": "1950-05-15"
      }
    },
    {
      "resource": {
        "resourceType": "MedicationRequest",
        "id": "RX456",
        "status": "active",
        "intent": "order",
        "medicationCodeableConcept": {
          "coding": [{
            "system": "http://health.canada.ca/drug-identification-number",
            "code": "02230716",
            "display": "Warfarin"
          }]
        }
      }
    }
  ]
}
```

---

## Security & Compliance

### PHIPA/PIPEDA Compliance

1. **Data Minimization:** Only collect necessary patient data
2. **Encryption:** All data encrypted in transit (TLS 1.2+) and at rest
3. **Access Control:** Role-based access, API key authentication
4. **Audit Logging:** All API calls and alert actions logged
5. **Data Residency:** Host in Canada (AWS Canada or Azure Canada)

### Network Security

**Firewall Rules:**

```bash
# Allow Kroll server to reach CDSS API
iptables -A INPUT -p tcp --dport 3000 -s kroll-server-ip -j ACCEPT

# Allow pharmacist workstations to reach widget
iptables -A INPUT -p tcp --dport 80 -s 192.168.1.0/24 -j ACCEPT
```

**Database Security:**

```sql
-- Read-only user with minimal privileges
GRANT SELECT ON patients, prescriptions, patient_medications, patient_allergies TO cdss_readonly;
-- DO NOT grant INSERT, UPDATE, DELETE
```

---

## Troubleshooting

### Widget not loading

**Symptom:** iframe shows blank or error
**Solutions:**
1. Check CORS settings in `backend/.env`: `CORS_ORIGIN` must include Kroll URL
2. Verify widget URL is correct: `http://your-server/widget?prescription_id=XXX`
3. Check browser console for errors (F12)
4. Verify CDSS backend is running: `curl http://your-server:3000/health`

### No alerts appearing

**Symptom:** Widget loads but shows "No issues detected" for all prescriptions
**Solutions:**
1. Check connector is running: `pm2 status cdss-connector`
2. Verify database connection: Check backend logs for SQL errors
3. Test API directly: `curl -X POST http://localhost:3000/api/v1/demo/check-prescription -H "Content-Type: application/json" -d '{"drugName":"Warfarin 5mg","currentMedications":["Aspirin 81mg"]}'`
4. Check Kroll table names match adapter queries (may need customization)

### Performance issues

**Symptom:** Alerts take >5 seconds to appear
**Solutions:**
1. Reduce polling interval if using polling mode
2. Add database indexes on Kroll tables being queried
3. Scale CDSS backend (add more server instances)
4. Enable Redis caching in `backend/.env`

### Database connection errors

**Symptom:** "Can't reach database server" errors
**Solutions:**
1. Verify Kroll database is accessible: `psql -h kroll-db-server -U cdss_readonly -d kroll_pharmacy`
2. Check firewall allows connection from CDSS server to Kroll DB
3. Verify credentials in `KROLL_DB_URL` environment variable
4. Ensure Kroll database allows remote connections (pg_hba.conf)

---

## Support

**Technical Support:**
- Email: support@pharmacy-cdss.example.com
- Phone: 1-800-XXX-XXXX
- Documentation: https://docs.pharmacy-cdss.example.com

**For Kroll-specific integration questions:**
- Contact Kroll support: https://www.syscreations.ca/blog/kroll-integration/
- Business case for Kroll API access: Required for official API integration

---

## Appendix: Sample Database Queries

### Get Patient Profile

```sql
-- Example Kroll schema (actual schema may vary)
SELECT
  p.patient_id,
  p.health_card_no,
  p.first_name,
  p.last_name,
  p.date_of_birth,
  p.gender
FROM patients p
WHERE p.patient_id = 'PAT123';
```

### Get Current Medications

```sql
SELECT
  m.drug_name,
  m.din,
  m.strength,
  r.directions,
  r.date_filled
FROM patient_medications m
JOIN prescription_refills r ON m.medication_id = r.medication_id
WHERE m.patient_id = 'PAT123' AND r.is_active = true;
```

### Get Allergies

```sql
SELECT
  allergen_name,
  allergy_type,
  reaction,
  severity
FROM patient_allergies
WHERE patient_id = 'PAT123' AND active = true;
```

**Note:** Actual Kroll table/column names may differ. Work with Kroll database documentation or Kroll support to map correct schema.

---

**End of Integration Guide**

For additional assistance, please contact the CDSS implementation team.
