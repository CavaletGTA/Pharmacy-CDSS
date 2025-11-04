# Quick API Testing Script for Pharmacy CDSS
# Run this after starting the backend with docker-compose up

$baseUrl = "http://localhost:3000"
$apiUrl = "$baseUrl/api/v1"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Pharmacy CDSS - Quick API Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "[1/6] Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✓ Health Check PASSED" -ForegroundColor Green
    Write-Host "  Status: $($response.status)" -ForegroundColor Gray
    Write-Host "  Database: $($response.database)" -ForegroundColor Gray
    Write-Host "  Redis: $($response.redis)`n" -ForegroundColor Gray
} catch {
    Write-Host "✗ Health Check FAILED" -ForegroundColor Red
    Write-Host "  Error: $_`n" -ForegroundColor Red
    Write-Host "Make sure the server is running: docker-compose up`n" -ForegroundColor Yellow
    exit 1
}

# Test 2: Register User
Write-Host "[2/6] Registering test user..." -ForegroundColor Yellow
$registerBody = @{
    email = "test.pharmacist@pharmacy.ca"
    password = "SecurePassword123!"
    firstName = "Jane"
    lastName = "Smith"
    role = "pharmacist"
    pharmacyId = "550e8400-e29b-41d4-a716-446655440000"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$apiUrl/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "✓ User Registration PASSED" -ForegroundColor Green
    Write-Host "  User ID: $($response.data.user.userId)`n" -ForegroundColor Gray
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠ User already exists (OK)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Registration FAILED: $_`n" -ForegroundColor Red
    }
}

# Test 3: Login
Write-Host "[3/6] Logging in..." -ForegroundColor Yellow
$loginBody = @{
    email = "test.pharmacist@pharmacy.ca"
    password = "SecurePassword123!"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$apiUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $response.data.token
    Write-Host "✓ Login PASSED" -ForegroundColor Green
    Write-Host "  Token: $($token.Substring(0, 30))...`n" -ForegroundColor Gray
} catch {
    Write-Host "✗ Login FAILED: $_`n" -ForegroundColor Red
    exit 1
}

# Test 4: Get User Profile
Write-Host "[4/6] Getting user profile..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $response = Invoke-RestMethod -Uri "$apiUrl/auth/me" -Method Get -Headers $headers
    Write-Host "✓ Get User Profile PASSED" -ForegroundColor Green
    Write-Host "  Name: $($response.data.firstName) $($response.data.lastName)" -ForegroundColor Gray
    Write-Host "  Role: $($response.data.role)`n" -ForegroundColor Gray
} catch {
    Write-Host "✗ Get User Profile FAILED: $_`n" -ForegroundColor Red
}

# Test 5: Submit Prescription Check (CORE FEATURE!)
Write-Host "[5/6] Testing Prescription Check (Rules Engine)..." -ForegroundColor Yellow
$prescriptionCheck = @{
    prescription = @{
        din = "02242705"
        drugName = "Metformin 500mg"
        genericName = "Metformin HCl"
        strength = "500mg"
        dosageForm = "tablet"
        quantity = 90
        daysSupply = 30
        sigText = "Take 1 tablet by mouth twice daily with meals"
        sigStructured = @{
            dose = 1
            unit = "tablet"
            route = "oral"
            frequency = "twice daily"
            timing = "with meals"
        }
        isActive = $true
    }
    patientProfile = @{
        externalPatientId = "PT-TEST-001"
        demographics = @{
            firstName = "John"
            lastName = "TestPatient"
            dateOfBirth = "1960-05-15"
            ageYears = 64
            gender = "male"
            weightKg = 85
            heightCm = 175
        }
        medications = @(
            @{
                din = "02240907"
                drugName = "Gliclazide 30mg MR"
                strength = "30mg"
                sigText = "Take 1 tablet daily with breakfast"
                isActive = $true
            }
        )
        allergies = @(
            @{
                allergenName = "Penicillin"
                allergenType = "drug"
                reaction = "Rash, hives"
                severity = "moderate"
                isActive = $true
            }
        )
        conditions = @(
            @{
                conditionName = "Type 2 Diabetes Mellitus"
                conditionCode = "E11"
                diagnosisDate = "2018-03-15"
                isActive = $true
            }
        )
        labValues = @(
            @{
                testName = "Serum Creatinine"
                value = 1.2
                unit = "mg/dL"
                testDate = "2025-10-15"
                referenceRange = "0.6-1.2"
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$apiUrl/prescriptions/check" -Method Post -Body $prescriptionCheck -Headers $headers -ContentType "application/json"
    Write-Host "✓ Prescription Check PASSED" -ForegroundColor Green
    Write-Host "  Check ID: $($response.data.checkId)" -ForegroundColor Gray
    Write-Host "  Alerts Generated: $($response.data.alertsGenerated)" -ForegroundColor Gray
    Write-Host "  Processing Time: $($response.data.processingTimeMs)ms" -ForegroundColor Gray

    if ($response.data.alerts -and $response.data.alerts.Count -gt 0) {
        Write-Host "`n  Alerts Detected:" -ForegroundColor Cyan
        foreach ($alert in $response.data.alerts) {
            Write-Host "    - [$($alert.severity)] $($alert.title)" -ForegroundColor $(if ($alert.severity -eq "critical") {"Red"} elseif ($alert.severity -eq "significant") {"Yellow"} else {"Gray"})
        }
    }
    Write-Host ""
} catch {
    Write-Host "✗ Prescription Check FAILED: $_`n" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}

# Test 6: Get Alerts
Write-Host "[6/6] Getting alerts..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/alerts?limit=10" -Method Get -Headers $headers
    Write-Host "✓ Get Alerts PASSED" -ForegroundColor Green
    Write-Host "  Total Alerts: $($response.data.alerts.Count)" -ForegroundColor Gray
    Write-Host "  Total Count: $($response.data.total)`n" -ForegroundColor Gray
} catch {
    Write-Host "✗ Get Alerts FAILED: $_`n" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open test-api.http in VS Code with REST Client extension" -ForegroundColor Gray
Write-Host "  2. Or import to Postman for interactive testing" -ForegroundColor Gray
Write-Host "  3. Check the alerts in the database or via API`n" -ForegroundColor Gray
