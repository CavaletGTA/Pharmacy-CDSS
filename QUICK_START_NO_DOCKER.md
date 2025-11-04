# Quick Start Without Docker

## Minimal Setup (5 Minutes)

### 1. Install Node.js
Download and install Node.js 18+ from: https://nodejs.org/

### 2. Install PostgreSQL
Download and install from: https://www.postgresql.org/download/windows/

During installation:
- Set password for postgres user
- Default port: 5432
- Note the installation path (usually `C:\Program Files\PostgreSQL\15`)

### 3. Create Database

Open PowerShell and run:

```powershell
# Navigate to PostgreSQL bin directory
cd "C:\Program Files\PostgreSQL\15\bin"

# Connect to PostgreSQL
.\psql.exe -U postgres

# In the psql prompt, run these commands:
CREATE DATABASE pharmacy_cdss;
CREATE USER cdss_user WITH PASSWORD 'cdss_password_123';
GRANT ALL PRIVILEGES ON DATABASE pharmacy_cdss TO cdss_user;
\q
```

### 4. Load Database Schema

```powershell
cd C:\Users\meher\pharmacy-cdss

# Load schema
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U cdss_user -d pharmacy_cdss -f database\schema.sql
```

### 5. Set Up Backend

```powershell
cd C:\Users\meher\pharmacy-cdss\backend

# Install dependencies
npm install

# Generate Prisma client
npx prisma generate

# The .env file is already created, just verify DATABASE_URL matches your password
```

Edit `backend\.env` and update the DATABASE_URL:
```
DATABASE_URL=postgresql://cdss_user:cdss_password_123@localhost:5432/pharmacy_cdss
```

### 6. Start the Backend

```powershell
npm run dev
```

You should see:
```
🚀 Pharmacy CDSS Backend Server
📡 Environment: development
🔌 Server running on port 3000
🗄️  Database: Connected
⚡ Redis: Skipped (optional)
```

### 7. Test It!

Open another PowerShell window:

```powershell
# Test health endpoint
curl http://localhost:3000/health

# Run the test script
cd C:\Users\meher\pharmacy-cdss
.\test-quick.ps1
```

---

## Troubleshooting

### Database Connection Error

**Error:** `Can't reach database server`

**Fix:**
1. Verify PostgreSQL is running:
   ```powershell
   Get-Service -Name postgresql*
   ```

2. If not running, start it:
   ```powershell
   Start-Service -Name "postgresql-x64-15"
   ```

3. Check connection:
   ```powershell
   & "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U cdss_user -d pharmacy_cdss
   ```

### Prisma Client Error

**Error:** `@prisma/client did not initialize yet`

**Fix:**
```powershell
cd backend
npx prisma generate
npm run dev
```

### Port Already in Use

**Error:** `Port 3000 is already in use`

**Fix:**
```powershell
# Find what's using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID with the number from above)
taskkill /PID <PID> /F

# Or change the port in backend\.env:
PORT=3001
```

---

## Without Redis (Optional)

Redis is optional for caching. If you don't install it, the backend will still work but:
- Cache operations will be skipped
- Slightly slower performance
- Still fully functional

To install Redis (optional):
1. Download from: https://github.com/microsoftarchive/redis/releases
2. Extract and run `redis-server.exe`
3. Or skip it - the app handles missing Redis gracefully

---

## Verify Everything Works

```powershell
# 1. Health check
curl http://localhost:3000/health

# 2. Register a user
curl -X POST http://localhost:3000/api/v1/auth/register `
  -H "Content-Type: application/json" `
  -d '{
    "email": "test@pharmacy.ca",
    "password": "Test123!",
    "firstName": "Test",
    "lastName": "User",
    "role": "pharmacist",
    "pharmacyId": "550e8400-e29b-41d4-a716-446655440000"
  }'

# 3. Run full test suite
.\test-quick.ps1
```

---

## Next Steps

1. ✅ Backend is running
2. ✅ Database is connected
3. ✅ API is testable

Now you can:
- Use the test-api.http file in VS Code
- Run the PowerShell test script
- Build the frontend
- Populate the drug database

---

**That's it! No Docker needed!** 🎉
