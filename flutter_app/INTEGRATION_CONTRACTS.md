# ShopGenie Owner App - Integration Contracts Documentation

## 1. Authentication Contract (Backend: accounts app)

### Login
- **Endpoint**: `POST /api/auth/login/`
- **Request**: `{ "username": "string", "password": "string" }`
- **Response** (200):
  ```json
  {
    "access": "jwt-access-token",
    "refresh": "jwt-refresh-token",
    "user": {
      "id": 1,
      "username": "store_owner",
      "email": "owner@example.com",
      "role": "SHOP_OWNER"
    }
  }
  ```
- **Token Format**: JWT Bearer (SimpleJWT)
- **Auth Header**: `Authorization: Bearer <access_token>`

### Register Owner
- **Endpoint**: `POST /api/auth/register/owner/`
- **Request**: `{ "username": "string", "email": "string", "password": "string", "shop_name": "string" }`
- **Response** (201):
  ```json
  {
    "access": "jwt-access-token",
    "refresh": "jwt-refresh-token",
    "user": { "id": 1, "username": "store_owner", "email": "owner@example.com", "role": "SHOP_OWNER" },
    "shop": { "id": 1, "name": "My Kirana", "status": "DRAFT" }
  }
  ```

### User Roles
- `CUSTOMER` - Customer app users
- `SHOP_OWNER` - Owner app users (owner of a shop)
- `SHOP_WORKER` - Worker users assigned to a shop

### Shop Ownership
- `CustomUser.owned_shop` (OneToOne) → Shop owner relationship
- `CustomUser.assigned_shop` (ForeignKey) → Worker assignment to shop
- `Shop.owner` (OneToOne) → Back-reference to owner

---

## 2. Shop Profile & Publication Status

### Owner Endpoints (Requires SHOP_OWNER role)
- **GET /api/shops/my_shop/** - Get owner's shop (ShopOwnerSerializer)
- **PATCH /api/shops/my_shop/** - Update shop details
- **GET /api/shops/dashboard/** - Dashboard metrics

### Public Endpoints (Customer app)
- **GET /api/shops/** - List published shops (ShopPublicSerializer)
- **GET /api/shops/{id}/** - Get shop detail

### Shop Status Values
- `DRAFT` - Newly created, not visible to customers
- `PUBLISHED` - Visible to customers
- `SUSPENDED` - Hidden from customers

---

## 3. Products & Identifiers

### Owner Endpoints (Requires SHOP_OWNER role)
- **GET /api/products/** - List owner's products (paginated)
- **POST /api/products/** - Create product
- **PATCH /api/products/{id}/** - Update product

### Customer Endpoints (Public)
- **GET /api/products/?shop={id}** - Products for a shop
- **GET /api/products/?search={query}** - Search products

### Product Fields
- `id`, `name`, `barcode`, `category`
- `selling_price`, `cost_price`, `mrp`
- `stock_quantity`, `unit` (pc, kg, L)
- `is_loose_item`, `image_url`
- `status` (DRAFT, PUBLISHED, OUT_OF_STOCK)

---

## 4. Prices, Units, Stock Availability

- Prices stored as Decimal (max_digits=10, decimal_places=2)
- Units: free text (pc, kg, L, etc.)
- Stock tracked via `stock_quantity` (Decimal)
- Low stock threshold: ≤ 5 units (dashboard)

---

## 5. Inventory Changes

### Billing/Invoices (Atomic stock decrement)
- **POST /api/billing/invoices/** - Create invoice with idempotency key
- **Request**:
  ```json
  {
    "idempotency_key": "inv_123456",
    "payment_mode": "CASH|CARD|UPI",
    "customer_name": "Walk-in Customer",
    "customer_phone": "",
    "items": [{"product": 1, "quantity": 2, "unit_price": "140.00"}]
  }
  ```
- Backend decrements `Product.stock_quantity` atomically

---

## 6. Offers & Validity

### Owner Endpoints (Requires SHOP_OWNER role)
- **GET /api/offers/** - List owner's offers
- **POST /api/offers/** - Create offer
- **PATCH /api/offers/{id}/** - Update offer

### Customer Endpoints (Public)
- **GET /api/offers/?shop={id}** - Active offers for shop

### Offer Fields
- `discount_type`: PERCENTAGE | FIXED
- `discount_value`: Decimal
- `scope`: STORE_WIDE | PRODUCT_SPECIFIC
- `start_date`, `end_date` (DateTime)
- `is_active`: Boolean
- Validity: `is_active && start_date <= now <= end_date`

---

## 7. Announcements & Publication

### Owner Endpoints (Requires SHOP_OWNER role)
- **GET /api/announcements/** - List owner's announcements
- **POST /api/announcements/** - Create announcement
- **PATCH /api/announcements/{id}/** - Update

### Customer Endpoints (Public)
- **GET /api/announcements/?shop={id}** - Published announcements

### Announcement Status
- `DRAFT` - Not visible
- `PUBLISHED` - Visible to customers
- `ARCHIVED` - Hidden

---

## 8. Owner & Worker Permissions

### Worker Endpoints (Requires SHOP_OWNER role)
- **GET /api/workers/** - List workers for owner's shop
- **POST /api/workers/** - Create worker (creates CustomUser with SHOP_WORKER role)
- **PATCH /api/workers/{id}/** - Update worker permissions

### Worker Permissions
- `is_worker_active`: Boolean
- `can_view_invoices`: Boolean
- `can_confirm_bills`: Boolean

---

## 9. Invoices & Inventory Consistency

- **GET /api/billing/invoices/** - List invoices for owner's shop
- Invoice creation triggers atomic stock decrement
- Invoice status: `COMPLETED` | `CANCELLED` | `PENDING`

---

## 10. API Base URLs

| Environment | Owner App | Customer App | Backend |
|-------------|-----------|--------------|---------|
| Development (Desktop/Web) | `http://127.0.0.1:8000/api` | `http://10.0.2.2:8000/api` (Android emulator) / `http://127.0.0.1:8000/api` (other) | `http://127.0.0.1:8000` |
| Production | HTTPS | HTTPS | HTTPS |

---

## 11. Contract Compatibility Notes

### Current Owner App Issues to Fix (Future Stages)
1. **Register Owner**: Sends `role: 'OWNER'` but backend expects `SHOP_OWNER`
2. **Register Owner**: Sends full shop object but backend only needs `shop_name`
3. **Login Response Parsing**: Handles both `access` and `tokens.access` but backend only returns `access`

### Customer App Compatibility
- Uses same `/api/auth/login/` endpoint
- Expects `access` and `refresh` tokens
- Parses user role as `CUSTOMER` or `SHOP_OWNER`

---

## 12. File Locations

### Owner App
- `lib/api_service.dart` - HTTP client & API calls
- `lib/models.dart` - Data models
- `lib/screens/login_screen.dart` - Login UI
- `lib/theme/app_theme.dart` - Theme
- `lib/main.dart` - App entry & navigation

### Customer App
- `lib/services/auth_api_service.dart` - Auth HTTP client
- `lib/services/api_config.dart` - API configuration
- `lib/models/auth_models.dart` - Auth models
- `lib/providers/auth_provider.dart` - Auth state management

### Backend
- `accounts/views.py` - Login, RegisterCustomer, RegisterOwner
- `accounts/serializers.py` - Serializers for auth
- `accounts/models.py` - CustomUser, Shop models
- `shops/views.py` - ShopViewSet (my_shop, dashboard), OfferViewSet, AnnouncementViewSet
- `shops/serializers.py` - ShopPublicSerializer, ShopOwnerSerializer, OfferSerializer, AnnouncementSerializer
- `shops/urls.py` - Shop routes
- `shops/offer_urls.py` - Offer routes
- `shops/announcement_urls.py` - Announcement routes
- `workers/views.py` - WorkerViewSet
- `products/views.py` - ProductViewSet
- `billing/views.py` - InvoiceViewSet