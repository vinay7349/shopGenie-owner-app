# ShopGenie AI — Smart Retail Management & Billing System

ShopGenie is a comprehensive, production-grade retail management and POS billing platform specifically engineered for Kirana stores and independent retail businesses. The system combines a modern native Android application built with **Jetpack Compose (Material 3)**, a robust **Django REST Framework** backend with strict **Role-Based Access Control (RBAC)**, and a **Computer Vision Engine** for fast visual product recognition and weighing.

---

## Architecture Overview

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        ShopGenie System Overview                       │
└────────────────────────────────────────────────────────────────────────┘

    ┌───────────────────────────┐         ┌───────────────────────────┐
    │     Shop Owner Device     │         │    Shop Worker Device     │
    │  (Full Admin & Analytics) │         │  (Streamlined POS Billing)│
    └─────────────┬─────────────┘         └─────────────┬─────────────┘
                  │                                     │
                  │   Kotlin / Jetpack Compose (M3)     │
                  │   Retrofit 2 + Moshi + Flow         │
                  ▼                                     ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                Django REST Framework (Backend API)              │
    │  • Single-Shop Architecture & 1:1 Ownership Enforcement        │
    │  • RBAC: SHOP_OWNER vs. SHOP_WORKER Permissions                 │
    │  • Cost-Price Masking & Sensitive Data Protection               │
    │  • Atomic Transactions for Stock & Billing                      │
    └──────────────────┬───────────────────────────────┬──────────────┘
                       │                               │
                       ▼                               ▼
         ┌───────────────────────────┐   ┌───────────────────────────┐
         │    PostgreSQL / SQLite    │   │  Computer Vision Engine   │
         │ (Users, Shop, Inventory,  │   │  • PyTorch + MobileNetV3  │
         │      Invoices, Items)     │   │  • OpenCV Frame Matching  │
         └───────────────────────────┘   │  • ESP32-CAM Stream       │
                                         └───────────────────────────┘
```

---

## Core Features

### 1. Single-Shop Ownership Architecture
- **Strict Single-Shop Model:** Every authenticated Shop Owner account owns and manages exactly one active shop (`accounts.Shop`).
- **Clean "My Shop" Interface:** Replaces legacy multi-shop switching with a dedicated, focused store profile screen.
- **Storefront Configuration:** Manage shop name, category, contact information, business hours, and verification status.
- **Data Protection:** Backend and frontend prevent ordinary owners from creating duplicate shops or accessing other owners' stores.

### 2. Role-Based Access Control (RBAC)
- **`SHOP_OWNER` Account:**
  - Full store overview with real-time sales and gross profit analytics (`/api/billing/analytics/`).
  - Catalog and inventory management: add, edit, or adjust stock levels and cost prices.
  - Full access to manage workers and configure shop settings.
- **`SHOP_WORKER` Account:**
  - Tailored, distraction-free **Worker Dashboard**.
  - Camera-based visual billing, barcode scanning, and manual cart additions.
  - Catalog viewing with **backend-enforced cost-price masking** (cost prices are redacted at the serializer level).
  - Restricted access: workers cannot view profit reports, modify product purchase prices, or alter shop ownership settings.
  - Granular permissions: `can_confirm_bills` and `can_view_invoices` configured per worker.

### 3. Worker Management (Owner-Only)
- Create and invite workers assigned directly to the owner's shop.
- Toggle worker active/inactive status instantly (`is_worker_active`).
- Grant or revoke permissions (`can_confirm_bills`, `can_view_invoices`).
- Secure credential management: passwords hashed with PBKDF2/bcrypt; no plain-text secrets exposed.

### 4. Smart POS Billing & Loose Item Support
- **Multi-Item Billing:** Scan branded items with computer vision or select from the catalog.
- **Loose Items & Digital Scale Integration:** Calculate prices accurately based on per-kg weights (`WeightInputScreen`).
- **Atomic Checkout (`transaction.atomic()`):** Stock levels decrease only upon successful invoice confirmation. Prevents race conditions and inventory drift.
- **Instant Digital Invoices:** Real-time invoice generation with line items, tax breakdowns, and receipts.

### 5. Computer Vision Engine (`cv_engine/`)
- Powered by **PyTorch** and **MobileNetV3** with **OpenCV**.
- Produces 576-dimensional L2-normalized visual embeddings for cosine-similarity product matching.
- Supports both branded product classification and candidate suggestion for unbranded/loose bagged items.
- Interfaces with wireless **ESP32-CAM** video streams.

---

## Tech Stack

| Layer | Technologies |
|---|---|
| **Mobile Client** | Android (minSdk 24, targetSdk 36), Kotlin, Jetpack Compose, Material 3, ViewModel & StateFlow, Retrofit 2, Moshi, OkHttp 3/4, Coroutines |
| **Backend API** | Python 3, Django 5.x, Django REST Framework (DRF), SimpleJWT, django-cors-headers, python-dotenv |
| **Database** | PostgreSQL / SQLite with atomic transactions |
| **Vision & AI** | PyTorch, MobileNetV3 Large, OpenCV, NumPy, Pillow |

---

## Project Directory Structure

```text
ShopGenie/
├── app/                                    # Native Android Application
│   ├── src/main/
│   │   ├── java/com/example/
│   │   │   ├── MainActivity.kt            # Edge-to-edge entry point & navigation
│   │   │   ├── data/
│   │   │   │   ├── api/                   # Retrofit API Service & NetworkClient
│   │   │   │   ├── models/                # Moshi DTOs (Shop, User, Worker, Products)
│   │   │   │   └── repository/            # ShopManager & CartManager singletons
│   │   │   ├── ui/
│   │   │   │   ├── navigation/            # Screen routes (MyShop, ManageWorkers, etc.)
│   │   │   │   ├── screens/               # Compose screens:
│   │   │   │   │   ├── HomeScreen.kt             # Owner Dashboard
│   │   │   │   │   ├── WorkerDashboardScreen.kt  # Worker Dashboard
│   │   │   │   │   ├── MyShopScreen.kt           # Single-Shop Configuration
│   │   │   │   │   ├── ManageWorkersScreen.kt    # Worker CRUD & Permissions
│   │   │   │   │   ├── CameraScanScreen.kt       # CV Camera Scanner
│   │   │   │   │   ├── LooseItemSelectionScreen.kt
│   │   │   │   │   ├── WeightInputScreen.kt      # Per-KG Weight Entry
│   │   │   │   │   ├── CartScreen.kt             # Multi-item cart
│   │   │   │   │   ├── CheckoutScreen.kt         # Atomic checkout
│   │   │   │   │   ├── InvoiceReceiptScreen.kt   # Digital receipt
│   │   │   │   │   └── SalesAnalyticsScreen.kt   # Profit & sales reporting
│   │   │   │   └── theme/                 # Material 3 ColorScheme & Typography
│   │   └── res/                           # Drawables, mipmaps, strings.xml
│   └── build.gradle.kts                   # Android build configuration
│
├── shopgenie/
│   └── backend/                            # Django REST Framework Backend
│       ├── accounts/                      # Authentication, CustomUser, Shop, Workers
│       │   ├── models.py                  # Shop (1:1 with Owner), CustomUser with roles
│       │   ├── permissions.py             # IsShopOwner, IsShopWorker, IsActiveShopMember
│       │   ├── serializers.py             # ShopSerializer, WorkerSerializer, Login JWT
│       │   ├── views.py                   # MyShopView, WorkerListCreateView, UserProfile
│       │   └── urls.py                    # Auth & worker route definitions
│       ├── billing/                       # Invoices, Billing, and Analytics
│       │   ├── models.py                  # Invoice, InvoiceItem
│       │   ├── views.py                   # CheckoutAcceptView, AnalyticsView
│       │   └── serializers.py
│       ├── products/                      # Products & Catalog
│       │   ├── models.py                  # Product, Category
│       │   ├── serializers.py             # ProductSerializer (masks cost_price for workers)
│       │   └── views.py                   # ProductListCreateView, ProductMatchView
│       ├── vision/                        # Embedding & image matching views
│       ├── shopgenie/                     # Django core settings, WSGI, URLs
│       ├── manage.py
│       └── requirements.txt
│
├── cv_engine/                             # Computer Vision processing
│   └── cv_engine.py                       # MobileNetV3 feature extractor & matcher
│
├── .env.example                           # Configuration templates
└── README.md
```

---

## API Endpoints Reference

### Authentication & Profiles (`/api/auth/`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/auth/login/` | Public | Obtain JWT tokens and user metadata (role, permissions, shop info) |
| `POST` | `/api/auth/register/` | Public | Register a new Shop Owner account |
| `POST` | `/api/auth/token/refresh/` | Public | Refresh JWT access token |
| `GET` | `/api/auth/me/` | Authenticated | Fetch current user profile, role, and shop data |

### Single-Shop Management (`/api/auth/my-shop/`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/auth/my-shop/` | Owner / Worker | Fetch the authenticated user's shop details |
| `PATCH` | `/api/auth/my-shop/` | `SHOP_OWNER` | Update shop details (name, address, category, phone, hours) |

### Worker Management (`/api/auth/workers/`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/auth/workers/` | `SHOP_OWNER` | List all workers assigned to the owner's shop |
| `POST` | `/api/auth/workers/` | `SHOP_OWNER` | Create and assign a new worker account |
| `GET` | `/api/auth/workers/<id>/` | `SHOP_OWNER` | Retrieve specific worker details |
| `PATCH` | `/api/auth/workers/<id>/` | `SHOP_OWNER` | Update worker status (`is_worker_active`) or permissions |
| `DELETE`| `/api/auth/workers/<id>/` | `SHOP_OWNER` | Remove/decouple worker from the shop |

### Products & Inventory (`/api/products/`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/products/` | Shop Member | List shop products (`cost_price` masked for workers) |
| `POST` | `/api/products/` | `SHOP_OWNER` | Add a new product to inventory |
| `GET` | `/api/products/<id>/` | Shop Member | Get product details |
| `PUT/PATCH` | `/api/products/<id>/` | `SHOP_OWNER` | Update product, price, or stock count |
| `POST` | `/api/products/match/` | Shop Member | Computer Vision visual search against shop catalog |

### Billing & Analytics (`/api/billing/`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/billing/checkout/` | Authorized | Atomic checkout: creates invoice and decreases inventory |
| `GET` | `/api/billing/invoices/` | Authorized | List shop invoice history |
| `GET` | `/api/billing/invoices/<id>/` | Authorized | Get invoice details and line items |
| `GET` | `/api/billing/analytics/` | `SHOP_OWNER` | View store revenue, gross profit, and sales metrics |

---

## Setup & Getting Started

### Prerequisites
- **Android Development:** Android Studio Hedgehog or newer, JDK 17, Android SDK Platform 36.
- **Backend Development:** Python 3.10+, PostgreSQL (or SQLite for development).

### 1. Backend Setup (Django)

1. Navigate to the backend directory:
   ```bash
   cd shopgenie/backend
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables in a local `.env` file (see `.env.example`):
   ```env
   DEBUG=True
   SECRET_KEY=your-django-secret-key
   ALLOWED_HOSTS=*
   CORS_ALLOW_ALL_ORIGINS=True
   ```

5. Run database migrations:
   ```bash
   python manage.py migrate
   ```

6. Start the development server:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

### 2. Android App Setup

1. Open the project root in **Android Studio**.
2. Let Gradle sync project dependencies.
3. Configure the backend base URL in the app or via the in-app server address prompt on the login screen.
4. Build and install on an Android device or emulator:
   ```bash
   gradle assembleDebug
   ```

---

## Automated Verification & Tests

The project includes test verification suites for automated quality assurance:

- **Phase 1 Backend Verification:**
  ```bash
  python shopgenie/backend/run_phase1_tests.py
  ```
- **Phase 2 Computer Vision Engine Verification:**
  ```bash
  python shopgenie/run_phase2_tests.py
  ```
- **Android Unit & Robolectric Tests:**
  ```bash
  gradle :app:testDebugUnitTest
  ```

---

## Security Best Practices
- **No Plain-text Credentials:** Passwords are never returned in API responses or logs.
- **Strict Tenant Isolation:** All catalog, inventory, and billing queries are filtered strictly by the authenticated user's shop.
- **Zero-Trust Worker Boundaries:** Workers attempting to access owner endpoints receive HTTP 403 Forbidden responses.
- **Environment Confidentiality:** Production keys and database credentials must remain in `.env` and excluded from source control.
