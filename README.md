# ShopGenie AI — Smart Retail Management & POS Billing System

ShopGenie is a production-grade retail management and POS billing platform specifically engineered for Kirana stores and independent retail businesses. The system combines:

1. **Flutter & Dart Cross-Platform App (`flutter_app/`)**: Full-featured mobile client built with **Flutter 3.x and Dart**, featuring Material 3 UI, role-based navigation for Shop Owners and Workers, single-shop profile management, and POS billing.
2. **Native Android App (`app/`)**: Native client built with **Jetpack Compose (Material 3)**, Retrofit 2, and Kotlin Coroutines, powering the live interactive preview.
3. **Django REST Framework Unified Backend (`R:\shopgenie backend\shopgenie_unified\`)**: Backend API with strict **Role-Based Access Control (RBAC)**, 1:1 Shop Ownership enforcement, worker management with permission toggles, cost-price masking for workers, and atomic stock transactions.
4. **Computer Vision Engine (`cv_engine/`)**: PyTorch MobileNetV3 + OpenCV pipeline producing 576-dimensional L2-normalized embeddings for instant visual product recognition.

---

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ShopGenie Architecture Overview                       │
└─────────────────────────────────────────────────────────────────────────────────┘

 ┌──────────────────────────────────────┐       ┌──────────────────────────────────────┐
 │      Flutter & Dart Client           │       │    Native Android Client             │
 │         (`flutter_app/`)             │       │            (`app/`)                  │
 │  • Cross-platform (Android/iOS/Web)  │       │  • Jetpack Compose (Material 3)      │
 │  • Material 3 UI & Responsive Design │       │  • Live In-Browser Streaming Preview │
 │  • Single-Shop & Worker RBAC UI      │       │  • Retrofit 2 + Moshi + Coroutines   │
 └──────────────────┬───────────────────┘       └──────────────────┬───────────────────┘
                    │                                              │
                    │         HTTP / JSON REST API with JWT        │
                    └───────────────────────┬──────────────────────┘
                                            ▼
 ┌─────────────────────────────────────────────────────────────────────────────────┐
 │                       Django REST Framework (Backend API)                       │
 │  • Single-Shop Rule: Each Shop Owner owns and manages exactly 1 active shop     │
 │  • Strict RBAC: SHOP_OWNER vs. SHOP_WORKER roles with backend enforcement       │
 │  • Worker Management: Invite/assign workers, toggle active status & permissions │
 │  • Cost-Price Masking: Workers cannot see cost prices or gross profit margins   │
 │  • Atomic Transactions: Stock deduction & invoice creation in 1 transaction     │
 └──────────────────────────┬───────────────────────────────┬──────────────────────┘
                            │                               │
                            ▼                               ▼
              ┌───────────────────────────┐   ┌───────────────────────────┐
              │    PostgreSQL / SQLite    │   │  Computer Vision Engine   │
              │ (Users, Shop, Workers,    │   │  • PyTorch + MobileNetV3  │
              │  Products, Invoices)      │   │  • OpenCV Cosine Match    │
              └───────────────────────────┘   │  • ESP32-CAM Stream       │
                                              └───────────────────────────┘
```

---

## Key Features

### 1. Single-Shop Ownership Model
- **1:1 Shop Ownership:** Every authenticated Shop Owner account owns and manages exactly one active shop (`accounts.Shop`).
- **Dedicated "My Shop" Interface:** Replaces legacy multi-shop switching with a focused, comprehensive store profile.
- **Storefront Details:** Configure shop name, category, contact information, business hours, and view verification status.
- **Security & Isolation:** Prevents ordinary owners from creating multiple shops or accessing another owner's shop data.

### 2. Dual Roles: Shop Owner vs. Shop Worker
- **`SHOP_OWNER` Account:**
  - Full analytics dashboard with real-time gross revenue, net profit, and order metrics (`/api/billing/analytics/`).
  - Catalog and inventory management: add, edit, or adjust stock levels, selling prices, and cost prices.
  - Worker management: invite, activate/deactivate, and configure worker privileges.
  - Shop configuration and operational settings.
- **`SHOP_WORKER` Account:**
  - Streamlined, distraction-free **Worker Dashboard**.
  - Camera-based visual billing, barcode scanning, and multi-item POS cart.
  - Catalog viewing with **backend-enforced cost-price masking** (cost prices and profit margins are completely omitted at serializer level).
  - Restricted access: cannot view profit reports, alter cost prices, adjust stock arbitrarily, or manage shop settings.
  - Granular permissions: `can_confirm_bills` and `can_view_invoices` configured per worker.

### 3. Worker Management (Owner-Only)
- Create and assign workers directly to the owner's shop via `/api/auth/workers/`.
- Toggle worker active/inactive status instantly (`is_worker_active`).
- Grant or revoke permissions (`can_confirm_bills`, `can_view_invoices`).
- Secure credential management: PBKDF2/bcrypt password hashing; no plain-text credentials exposed.

### 4. Smart POS Billing & Atomic Checkout
- **Multi-Item Billing:** Scan items via computer vision, barcode scanner, or catalog picker.
- **Loose Items & Digital Scale Integration:** Calculate prices accurately based on per-kg weights.
- **Atomic Checkout (`transaction.atomic()`):** Stock levels decrease only upon successful invoice confirmation. Prevents inventory drift and race conditions.
- **Real-Time Invoice Generation:** Line-item breakdown, tax calculation, and printable receipts.

### 5. Computer Vision Engine (`cv_engine/`)
- Powered by **PyTorch** and **MobileNetV3** with **OpenCV**.
- Produces 576-dimensional L2-normalized visual embeddings for cosine-similarity product matching.
- Supports branded product classification and candidate suggestion for unbranded/loose bagged items.

---

## Tech Stack

| Layer | Technologies |
|---|---|
| **Flutter App** | Dart 3.x, Flutter 3.x, Material 3, `http`, `intl`, `provider`, `camera` |
| **Native Android App** | Kotlin, Jetpack Compose (M3), ViewModel, StateFlow, Retrofit 2, Moshi, OkHttp, Coroutines |
| **Backend API** | Python 3.10+, Django 5.x, Django REST Framework (DRF), SimpleJWT, django-cors-headers |
| **Database** | PostgreSQL / SQLite with atomic transactions |
| **Vision & AI** | PyTorch, MobileNetV3 Large, OpenCV, NumPy, Pillow |

---

## Project Directory Structure

```text
ShopGenie/
├── flutter_app/                            # Cross-Platform Flutter & Dart Application
│   ├── pubspec.yaml                       # Flutter project manifest & dependencies
│   ├── README.md                          # Flutter app setup & run guide
│   └── lib/
│       ├── main.dart                      # Flutter app entry point, M3 theme, Owner & Worker UI
│       ├── models.dart                    # Dart models (Shop, User, Worker, Product, Invoice)
│       └── api_service.dart               # REST client for Django backend with JWT & RBAC
│
├── app/                                    # Native Android Application (Jetpack Compose)
│   ├── src/main/
│   │   ├── java/com/example/
│   │   │   ├── MainActivity.kt            # Edge-to-edge entry point & navigation
│   │   │   ├── data/
│   │   │   │   ├── api/                   # Retrofit API Service & NetworkClient
│   │   │   │   ├── models/                # Moshi DTOs (Shop, User, Worker, Products)
│   │   │   │   └── repository/            # ShopManager & CartManager singletons
│   │   │   ├── ui/
│   │   │   │   ├── navigation/            # Compose Navigation routes
│   │   │   │   ├── screens/               # Compose screens:
│   │   │   │   │   ├── HomeScreen.kt             # Owner Dashboard (Sales & Profit)
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

## Quickstart & Setup Guide

### 1. Running the Flutter & Dart Client

To run the Flutter app on Android, iOS, or Web:

```bash
cd flutter_app
flutter pub get
flutter run
```

Configure the backend endpoint in `flutter_app/lib/api_service.dart` (defaults to `http://10.0.2.2:8000/api` for the Android emulator, or `http://localhost:8000/api` for Web/Desktop).

### 2. Running the Django REST Backend

1. Navigate to the backend directory:
   ```bash
   cd "R:\shopgenie backend\shopgenie_unified"
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables (`.env`):
   ```env
   DEBUG=True
   SECRET_KEY=your-django-secret-key
   ALLOWED_HOSTS=*
   CORS_ALLOW_ALL_ORIGINS=True
   ```

5. Apply migrations:
   ```bash
   python manage.py migrate
   ```

6. Start the development server:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

### 3. Running the Native Android App

1. Open the project root in **Android Studio**.
2. Sync Gradle dependencies.
3. Build and launch:
   ```bash
   gradle assembleDebug
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

## Automated Verification & Tests

- **Phase 1 Backend Verification:**
  ```bash
  python manage.py test
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

## Security & Tenant Isolation
- **No Plain-text Credentials:** Passwords are never returned in API responses or logs.
- **Strict Tenant Isolation:** All catalog, inventory, and billing queries are filtered strictly by the authenticated user's shop.
- **Zero-Trust Worker Boundaries:** Workers attempting to access owner endpoints receive HTTP 403 Forbidden responses.
- **Environment Confidentiality:** Production keys and database credentials remain in `.env` and excluded from version control.
