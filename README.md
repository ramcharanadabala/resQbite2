# 🥗 ResQBite — Food Donation Platform

> **Rescue Food. Restore Lives.**
> Connect surplus food from donors with NGOs and orphanages — real-time, geo-aware, priority-driven.

---

## 🗂 Project Structure

```
resqbite/
├── backend/
│   ├── app/
│   │   ├── main.py                    # FastAPI app, middleware, routers
│   │   ├── core/
│   │   │   ├── config.py              # Pydantic Settings (env-based)
│   │   │   ├── database.py            # SQLAlchemy engine + session
│   │   │   ├── security.py            # JWT, password hashing, role deps
│   │   │   └── scheduler.py           # APScheduler: auto-expiry + NGO timer
│   │   ├── models/
│   │   │   ├── user.py                # User model (donor/ngo/orphanage/admin)
│   │   │   ├── food.py                # FoodListing model + status enums
│   │   │   ├── claim.py               # Claim model + OTP pickup
│   │   │   └── notification.py        # Notification model
│   │   ├── schemas/
│   │   │   └── schemas.py             # All Pydantic request/response schemas
│   │   ├── routers/
│   │   │   ├── auth.py                # Register, login, refresh, /me
│   │   │   ├── users.py               # User CRUD
│   │   │   ├── food.py                # Food listings + geo search + dashboard
│   │   │   ├── claims.py              # Claim lifecycle + OTP pickup
│   │   │   ├── notifications.py       # Notification read/list
│   │   │   └── admin.py               # Admin stats + full user/food/claim mgmt
│   │   ├── services/
│   │   │   └── notification_service.py # Mock notif dispatch (swap → Celery/SES)
│   │   └── utils/
│   │       └── geo.py                 # Haversine distance + radius filter
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   └── index.html                     # Full-featured SPA frontend
├── docker-compose.yml
└── .env.example
```

---

## ⚡ Quick Start

### 1. Clone & configure
```bash
git clone <repo>
cd resqbite
cp .env.example .env
# Edit .env with your MySQL credentials and secret key
```

### 2. Run with Docker Compose
```bash
docker-compose up --build
```

### 3. Run locally (dev)
```bash
# Start MySQL (or use existing instance)
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Set env vars
export DB_HOST=localhost DB_USER=root DB_PASSWORD=pass DB_NAME=resqbite

uvicorn app.main:app --reload
```

API available at: `http://localhost:8000`
Docs at: `http://localhost:8000/api/docs`
Frontend: Open `frontend/index.html` in browser

---

## 🔑 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `SECRET_KEY` | (change me!) | JWT signing secret |
| `DB_HOST` | localhost | MySQL host |
| `DB_PORT` | 3306 | MySQL port |
| `DB_USER` | root | MySQL user |
| `DB_PASSWORD` | password | MySQL password |
| `DB_NAME` | resqbite | Database name |
| `NGO_PRIORITY_WINDOW_MINUTES` | 30 | NGO exclusive claim window |
| `DEFAULT_SEARCH_RADIUS_KM` | 25.0 | Default geo search radius |
| `EXPIRY_CHECK_INTERVAL_SECONDS` | 60 | Scheduler check interval |

---

## 📡 API Reference

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Register (donor/ngo/orphanage) |
| POST | `/api/v1/auth/login` | Login → JWT tokens |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| GET | `/api/v1/auth/me` | Get current user |

### Food
| Method | Endpoint | Auth Role | Description |
|---|---|---|---|
| POST | `/api/v1/food/` | Donor | Create food listing |
| GET | `/api/v1/food/` | Any | List food (geo-filtered) |
| GET | `/api/v1/food/{id}` | Any | Food detail |
| PATCH | `/api/v1/food/{id}` | Donor | Update listing |
| DELETE | `/api/v1/food/{id}` | Donor/Admin | Remove listing |
| GET | `/api/v1/food/dashboard/summary` | Donor | Impact stats |

**Geo Search:** `GET /api/v1/food/?lat=17.44&lon=78.37&radius_km=10`

### Claims
| Method | Endpoint | Auth Role | Description |
|---|---|---|---|
| POST | `/api/v1/claims/` | NGO/Orphanage | Submit claim |
| GET | `/api/v1/claims/` | Any | My claims |
| PATCH | `/api/v1/claims/{id}/approve` | Donor | Approve + issue OTP |
| PATCH | `/api/v1/claims/{id}/reject` | Donor | Reject claim |
| POST | `/api/v1/claims/{id}/pickup` | NGO/Orphanage | Confirm pickup with OTP |

### Admin
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/admin/stats` | Platform-wide statistics |
| GET | `/api/v1/admin/users` | All users (filterable) |
| PATCH | `/api/v1/admin/users/{id}` | Update user status/role |
| GET | `/api/v1/admin/food` | All food listings |
| GET | `/api/v1/admin/claims` | All claims |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     FastAPI App                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │   Auth   │  │   Food   │  │  Claims  │  │ Admin  │  │
│  │  Router  │  │  Router  │  │  Router  │  │ Router │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘  │
│       └─────────────┴─────────────┴─────────────┘       │
│                         │                               │
│              ┌──────────┴──────────┐                    │
│              │   SQLAlchemy ORM    │                    │
│              └──────────┬──────────┘                    │
│                         │                               │
│         ┌───────────────┴───────────────┐               │
│         │           MySQL 8.0           │               │
│         └───────────────────────────────┘               │
│                                                         │
│    ┌────────────────────────────────────────────┐       │
│    │          APScheduler (Background)          │       │
│    │  • Auto-expire food every 60s              │       │
│    │  • NGO priority window check every 30s     │       │
│    └────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Priority Claim System

```
T+0min   Food Listed → Status: AVAILABLE, ngo_window_open=True
   ↓
T+0-30   Only NGOs can claim (orphanages get 403 with countdown)
   ↓
T+30     Scheduler: ngo_window_open=False (orphanages can now claim)
   ↓
Claim    Donor approves → pickup OTP issued → Status: CLAIMED
   ↓
Pickup   Claimer submits OTP → Status: PICKED → Donor notified
```

---

## 🔒 Security

- **JWT RS256** — configurable algorithm, short-lived access tokens (24h) + refresh (7d)
- **bcrypt** — password hashing with salt
- **Role-based access** — decorator factory `require_roles(*roles)` on all sensitive endpoints
- **Input validation** — Pydantic v2 strict validation on all requests
- **Rate limiting** — ready hooks in config (`MAX_FOOD_LISTINGS_PER_HOUR`)

---

## 🔔 Notification System

Currently **mock** (logs to console + stores in DB). Production swap:

```python
# In app/services/notification_service.py → _dispatch()

# Option A: Celery
celery_app.send_task("tasks.send_email", args=[user_email, title, message])

# Option B: AWS SES
boto3.client("ses").send_email(...)

# Option C: Firebase FCM
firebase_admin.messaging.send(message)
```

---

## 🗺 Geo Filtering

Uses **Haversine formula** (no external API needed):

```python
GET /api/v1/food/?lat=17.4485&lon=78.3772&radius_km=10

# Returns listings sorted by distance with distance_km field injected
```

For production map rendering, integrate **Leaflet.js** or **Mapbox GL** in the frontend.

---

## 🐳 Docker

```bash
# Full stack
docker-compose up --build

# API only
cd backend && docker build -t resqbite-api .
docker run -p 8000:8000 --env-file .env resqbite-api
```

---

## 🧪 Sample API Calls

```bash
# Register a donor
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"chef@example.com","full_name":"Ravi Kumar","password":"secure123","role":"donor"}'

# Login
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"chef@example.com","password":"secure123"}' | jq -r .access_token)

# List food near Hyderabad
curl "http://localhost:8000/api/v1/food/?lat=17.4485&lon=78.3772&radius_km=25" \
  -H "Authorization: Bearer $TOKEN"

# Admin stats
curl http://localhost:8000/api/v1/admin/stats \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```
