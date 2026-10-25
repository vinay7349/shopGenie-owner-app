# ShopGenie Platform — Stage 1 Audit Report

**Date:** 2025-10-25  
**Auditor:** Senior Flutter Engineer / Django REST Integration Engineer  
**Projects:**
- Owner App (Flutter): `R:\shopGiene owner\shopGenie-owner-app\flutter_app\`
- Unified Django Backend: `R:\shopgenie backend\shopgenie_unified\`

---

## 1. Project Overview & Git Status

### Owner Flutter App
- **Path:** `R:\shopGiene owner\shopGenie-owner-app\flutter_app\`
- **Branch:** `main`
- **Flutter/Dart:** Flutter 3.x / Dart 3.x (per `pubspec.yaml`)
- **State Management:** Provider + setState (no centralized state management)
- **Routing:** Bottom navigation bar in `main.dart` with 5 tabs for Owner, 3 for Worker
- **Auth:** JWT via `rest_framework_simplejwt` (access + refresh tokens)
- **Token Storage:** `flutter_secure_storage` (AES-256 via iOS Keychain / Android Keystore)
- **Git Status:** Clean working tree, no uncommitted changes

### Django Backend
- **Path:** `R:\shopgenie backend\shopgenie_unified\`
- **Branch:** `main`
- **Django:** 5.2.17
- **DRF:** 3.15.x
- **Auth:** `djangorestframework-simplejwt` (JWT)
- **Database:** PostgreSQL (configurable via env, SQLite fallback)
- **CORS:** `django-cors-headers` (allow-all in DEBUG)
- **Git Status:** Clean working tree, no uncommitted changes

---

## 2. Screen → API Map (Owner App)

| Screen | Endpoint | Method | Request Fields | Response Fields | Permission |
|--------|----------|--------|----------------|-----------------|------------|
| **Login** | `/api/auth/login/` | POST | `username`, `password` | `access`, `refresh`, `user{id,username,email,role}` | AllowAny |
| **Register Store** | `/api/auth/register/owner/` | POST | `username`, `email`, `password`, `shop_name` | `access`, `refresh`, `user{...}`, `shop{id,name,status}` | AllowAny |
| **Dashboard** | `/api/shops/dashboard/` | GET | — | `shop_id`, `shop_name`, `shop_status`, `total_products`, `available_products`, `low_stock_products`, `active_offers`, `total_invoices`, `total_sales`, `today_invoices`, `today_sales`, `active_workers`, `recent_invoices[]` | `IsShopOwner` |
| **My Shop (View)** | `/api/shops/my_shop/` | GET | — | `id`, `name`, `category`, `description`, `address`, `phone`, `business_hours`, `status`, `rating` | `IsShopOwner` |
| **My Shop (Edit)** | `/api/shops/my_shop/` | PATCH | `name`, `category`, `description`, `address`, `phone`, `business_hours` | Updated shop object | `IsShopOwner` |
| **Products List** | `/api/products/` | GET | `shop`, `category`, `search`, `ordering` | Paginated: `id`, `shop`, `name`, `category`, `description`, `mrp`, `selling_price`, `cost_price` (owner only), `stock_quantity`, `unit`, `image_url`, `status`, `brand`, `size` | `IsAuthenticatedOrReadOnly` (owner sees own; public sees published) |
| **Create Product** | `/api/products/` | POST | `shop`, `name`, `category`, `brand`, `size`, `description`, `mrp`, `selling_price`, `cost_price`, `stock_quantity`, `unit`, `image_url`, `status` | Created product | `IsShopOwner` / `IsShopWorker` |
| **Update Product** | `/api/products/{id}/` | PATCH | Same as create (partial) | Updated product | `IsShopOwner` / `IsShopWorker` |
| **Inventory (Stock Adj.)** | `/api/inventory/` | GET/POST | GET: —; POST: `product`, `delta`, `reason`, `note` | `id`, `product`, `delta`, `reason`, `note`, `created_at` | `IsAuthenticated` (owner/worker of same shop) |
| **Billing (Create Invoice)** | `/api/billing/invoices/` | POST | `idempotency_key`, `items[{product_id, quantity}]`, `payment_mode`, `customer_name`, `customer_phone` | `id`, `shop`, `idempotency_key`, `total_amount`, `status`, `created_at`, `items[]` | `IsShopOwner` / `IsShopWorker` (with `can_confirm_bills`) |
| **Invoice History** | `/api/billing/invoices/` | GET | — | List of invoices with `id`, `idempotency_key`, `total_amount`, `status`, `created_at` | `IsShopMember` (worker needs `can_view_invoices`) |
| **Invoice Detail** | `/api/billing/invoices/{id}/` | GET | — | Invoice with items: `product`, `product_name`, `quantity`, `unit_price`, `line_total` | `IsShopMember` |
| **Offers List** | `/api/offers/` | GET | `shop`, `is_active`, `scope`, `search` | Paginated: `id`, `shop`, `shop_name`, `title`, `description`, `discount_type`, `discount_value`, `scope`, `applicable_product`, `product_name`, `start_date`, `end_date`, `is_active`, `is_valid`, `created_at`, `updated_at` | AllowAny (list), `IsShopOwner` (write) |
| **Create Offer** | `/api/offers/` | POST | `title`, `description`, `discount_type`, `discount_value`, `scope`, `applicable_product`, `start_date`, `end_date`, `is_active` | Created offer | `IsShopOwner` |
| **Announcements List** | `/api/announcements/` | GET | `shop`, `status`, `search` | Paginated: `id`, `shop`, `shop_name`, `title`, `content`, `status`, `created_by`, `created_at`, `updated_at` | AllowAny (list), `IsShopOwner` (write) |
| **Workers List** | `/api/workers/` | GET | — | `id`, `username`, `email`, `first_name`, `last_name`, `is_worker_active`, `can_view_invoices`, `can_confirm_bills`, `date_joined` | `IsShopOwner` |
| **Create Worker** | `/api/workers/` | POST | `username`, `email`, `password`, `first_name`, `last_name`, `is_worker_active`, `can_view_invoices`, `can_confirm_bills` | Created worker | `IsShopOwner` |
| **Update Worker** | `/api/workers/{id}/` | PATCH | `first_name`, `last_name`, `is_worker_active`, `can_view_invoices`, `can_confirm_bills` | Updated worker | `IsShopOwner` |
| **Delete Worker** | `/api/workers/{id}/` | DELETE | — | 204 | `IsShopOwner` |
| **Notifications** | `/api/notifications/` | GET/POST | — | `id`, `recipient`, `title`, `message`, `notification_type`, `is_read`, `created_at` | `IsAuthenticated` |

---

## 3. Role / Permission Model (Verified Against Source)

### Backend User Model (`accounts/models.py`)
```python
class CustomUser(AbstractBaseUser, PermissionsMixin):
    Role: CUSTOMER | SHOP_OWNER | SHOP_WORKER
    is_worker_active: Boolean (default=True)
    can_view_invoices: Boolean (default=True)
    can_confirm_bills: Boolean (default=True)
    assigned_shop: FK to Shop (for workers)
    owned_shop: OneToOne (for owners)
```

### Permission Enforcement (Verified)
| Permission | Enforcement Point |
|------------|-------------------|
| `is_worker_active` | `user_effective_shop()` returns `None` if inactive; blocks all shop-scoped views |
| `can_view_invoices` | `InvoiceViewSet.list()` raises `PermissionDenied` for workers without it |
| `can_confirm_bills` | `InvoiceViewSet._require_billing_permission()` raises `PermissionDenied` |
| Owner-only actions | `IsShopOwner` permission class (checks `user.is_owner`) |
| Shop isolation | All shop-scoped views filter by `user.effective_shop` |

### Flutter App Role Handling
- **Login:** Role comes from backend response (`res['role']` or `res['user']['role']`)
- **Worker Mode Toggle:** EXISTS in `LoginScreen` (`_isWorkerMode` bool) — **VIOLATES** "Role comes from backend token/profile, not a local toggle"
- **UI Gating:** `currentUser.isOwner` / `currentUser.isWorker` used to show/hide tabs
- **No local privilege escalation** — but the toggle allows user to pretend to be worker

---

## 4. Billing Contract (Verified)

### Invoice Create Serializer (`billing/serializers.py` → `InvoiceCreateSerializer`)
**Request:**
```json
{
  "idempotency_key": "string (required, max 128)",
  "items": [
    { "product": 123, "quantity": "2.5" }
  ]
}
```

**Validation:**
- `items` non-empty list of dicts
- Each item: `product` (int, required), `quantity` (decimal string > 0)
- No duplicate product IDs in same invoice

### Invoice Creation Flow (`billing/views.py` → `InvoiceViewSet.create`)
1. Verify billing permission (owner OR worker with `can_confirm_bills`)
2. Get user's effective shop
3. Validate request with `InvoiceCreateSerializer`
4. **Idempotency:** Check `(shop, idempotency_key)` unique constraint
   - If exists with **same** canonical signature → return existing invoice (200 OK)
   - If exists with **different** signature → 409 Conflict
5. **Atomic transaction:**
   - Lock products with `select_for_update()`
   - Verify product belongs to shop, is `PUBLISHED`
   - Check stock >= quantity
   - Create `Invoice` + `InvoiceItem[]` + `StockAdjustment[]` (delta = -quantity)
   - Update `Product.stock_quantity` via `F()` expression
6. Return invoice with items

### Stock Decrement
- **Server-side only** via `StockAdjustment` + `Product.stock_quantity = F("stock_quantity") - quantity`
- Happens in same transaction as invoice creation
- Flutter app sends `quantity` only; backend uses `Product.selling_price` for totals

---

## 5. Product Image Support

### Backend
- **Model:** `Product.image_url` = `URLField(blank=True, default="")`
- **Serializer:** Included in both `ProductPublicSerializer` and `ProductOwnerSerializer`
- **Upload Endpoint:** **MISSING** — no multipart upload, no media handling, no signed URLs

### Flutter
- **Model:** `Product.imageUrl` (string)
- **UI:** Shows `Image.network()` with fallback icon
- **Create/Edit:** No image picker, no upload logic

---

## 6. Customer-App Readiness Map

| Feature | Backend Support | API Response Fields | Status |
|---------|----------------|---------------------|--------|
| Shop Profile (public) | `ShopViewSet.list/retrieve` (AllowAny) | `id`, `name`, `category`, `description`, `address`, `phone`, `business_hours`, `rating`, `status` | ✅ Implemented |
| Catalog (public) | `ProductViewSet` (public serializer) | `id`, `shop`, `store_id`, `store_name`, `name`, `category`, `brand`, `size`, `description`, `mrp`, `selling_price`, `price`, `stock_quantity`, `unit`, `image_url` | ✅ Implemented |
| Inventory (public) | **MISSING** — public serializer shows `stock_quantity` but no availability logic | `stock_quantity` exposed | ⚠️ Partial |
| Offers (public) | `OfferViewSet` (AllowAny, filters `is_active` + date range) | `title`, `discount_type`, `discount_value`, `scope`, `is_valid`, `start_date`, `end_date`, `product_name` | ✅ Implemented |
| Announcements (public) | `AnnouncementViewSet` (AllowAny, filters `status=PUBLISHED`) | `title`, `content`, `status`, `created_at` | ✅ Implemented |
| Publishing Status | `Shop.status`, `Product.status`, `Offer.is_active`, `Announcement.status` | Exposed in serializers | ✅ Implemented |
| Cost/Profit Privacy | `ProductPublicSerializer` excludes `cost_price` | ✅ Not exposed to public | ✅ Enforced |
| Worker Data Privacy | Worker endpoints require `IsShopOwner` | ✅ Not exposed to public | ✅ Enforced |

---

## 7. Issues Found

### A. Demo Mode / Mock Data (VIOLATES "Live data only")
| Location | Issue |
|----------|-------|
| `lib/widgets/demo_banner.dart` | `DemoBanner` widget shown in `main.dart` when `isDemo=true` |
| `lib/main.dart:128-135` | `ShopGenieApp(isDemo: true)` enables demo mode with hardcoded user/shop |
| `lib/main.dart:140-155` | `_handleEnterDemo()` creates fake `User` + `Shop` with `id: 999` |
| `lib/main.dart:160-175` | Default `currentUser` with fake shop data when no auth |
| `lib/screens/login_screen.dart:91-98` | Login fallback creates mock `Shop` if `getMyShop()` fails |

### B. Worker Role Toggle (VIOLATES "Role comes from backend")
| Location | Issue |
|----------|-------|
| `lib/screens/login_screen.dart:29` | `_isWorkerMode` bool toggles UI role |
| `lib/screens/login_screen.dart:104` | Login uses `_isWorkerMode ? 'SHOP_WORKER' : 'SHOP_OWNER'` instead of backend response |
| `lib/screens/login_screen.dart:504-522` | "Worker Login" / "Owner Login" button toggles mode |

### C. Voice Billing (Should be removed per rules)
| Location | Issue |
|----------|-------|
| Not found in current codebase | No Voice Billing code detected (good) |

### D. Duplicated HTTP Logic
- `ApiService` is central but `main.dart` also has `_confirmBill()` with duplicate idempotency logic (lines 600-650 in main.dart) — **should delegate to `ApiService.confirmBill()`**

### E. Broken Routes / Dead Buttons
| Screen | Issue |
|--------|-------|
| `main.dart` | `isDemo` mode bypasses all API calls — buttons work but hit mock data |
| `login_screen.dart` | Register dialog missing `shop_category`, `shop_phone` fields that backend accepts (though backend serializer only requires `shop_name`) |

---

## 8. flutter analyze Results (Owner App)

**44 issues** (0 errors, 44 warnings/infos):
- **Warnings (actionable):** 7 (unused fields, unnecessary `!`, unused elements)
- **Infos (deprecations):** 37 (`value` → `initialValue`, `activeColor` → `activeThumbColor`, `window` API, `BuildContext` across async gaps)

**No errors** — code compiles cleanly.

---

## 9. Django Check Results

**0 issues** — backend passes all system checks.

---

## 10. Stage-by-Stage Implementation Plan

| Stage | Focus | Key Deliverables |
|-------|-------|------------------|
| **1** | **Audit Complete** | This report + `BACKEND_GAPS.md` |
| **2** | **Auth & Session Hardening** | Remove demo mode, worker toggle; enforce backend-derived roles; secure token storage; session restore |
| **3** | **Dashboard Polish** | Real data only; loading/error/empty states; pull-to-refresh |
| **4** | **Shop Profile & Catalog** | CRUD with validation; image upload (requires backend gap); proper states |
| **5** | **Inventory & Stock Sync** | Real stock adjustments; customer-facing availability |
| **6** | **Offers & Announcements** | Full CRUD; publication workflow; customer visibility |
| **7** | **Billing & Invoice Integrity** | Idempotency UX; atomic stock deduction verification; error handling |
| **8** | **Worker Management** | Permissions enforcement; inactive worker blocking |
| **9** | **Customer App Polish** | (Read-only reference) Verify integration |
| **10** | **E2E Integration & Release** | Cross-app sync tests; security review; APK verification |

---

## 11. Next Steps

**Stop here.** No code changes made in this stage.  
Awaiting approval to proceed to Stage 2.