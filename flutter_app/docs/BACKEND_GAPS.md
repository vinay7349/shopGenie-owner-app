# ShopGenie — Backend Gaps Document

**Purpose:** Track every missing backend capability that blocks a Flutter feature.  
**Rule:** Do NOT implement workarounds in Flutter. Log the gap here, wait for approval, then implement in Django.

---

## GAP-001: Product Image Upload
**Flutter Feature:** Owner creates/edits product with photo  
**Current State:** `Product.image_url` is a `URLField` — no upload endpoint, no media handling  
**Required Backend Change:**
- Add `Product.image` = `ImageField(upload_to="products/%Y/%m/", blank=True, null=True)`
- Add multipart upload endpoint: `POST /api/products/{id}/image/` or include in create/update
- Serve media via Django in DEBUG, CDN/S3 in production
- Return signed/absolute URL in serializer
**Flutter Impact:** Add image picker → multipart upload → show thumbnail

---

## GAP-002: Customer-Facing Stock Availability Logic
**Flutter Feature:** Customer sees "In Stock / Low Stock / Out of Stock" badges  
**Current State:** `ProductPublicSerializer` exposes `stock_quantity` but no computed availability  
**Required Backend Change:**
- Add `is_available` property to `Product` model: `stock_quantity > 0 and status == PUBLISHED and shop.status == PUBLISHED`
- Expose in `ProductPublicSerializer` as `available: true/false` and `availability_status: "IN_STOCK" | "LOW_STOCK" | "OUT_OF_STOCK"`
- Threshold configurable (e.g., `LOW_STOCK_THRESHOLD = 5`)
**Flutter Impact:** Show colored badges instead of raw numbers

---

## GAP-003: Shop Opening Hours / Real-Time Open Status
**Flutter Feature:** Customer sees "Open Now" / "Closed" indicator  
**Current State:** `Shop.business_hours` is free-text `CharField` — no parsing  
**Required Backend Change:**
- Replace `business_hours` with structured model:
  ```python
  class ShopHours(models.Model):
      shop = OneToOneField(Shop)
      monday_open = TimeField(null=True, blank=True)
      monday_close = TimeField(null=True, blank=True)
      # ... repeat for each day
      timezone = CharField(default="UTC")
  ```
- Add `is_open_now` property using timezone-aware comparison
- Expose in `ShopPublicSerializer`
**Flutter Impact:** Show green/red indicator with next open/close time

---

## GAP-004: Product Search Autocomplete / Suggestions
**Flutter Feature:** Type-ahead search in customer catalog  
**Current State:** `ProductViewSet` has `search_fields = ["name", "category"]` — full-text only  
**Required Backend Change:**
- Add `GET /api/products/suggestions/?q=` endpoint returning `["Apple", "Apple Juice", "Apples 1kg"]`
- Use PostgreSQL `trigram_similarity` or Redis for prefix matching
- Limit to 10 results, filter by shop status
**Flutter Impact:** Dropdown suggestions while typing

---

## GAP-005: Category Tree / Hierarchical Categories
**Flutter Feature:** Nested category filter (Groceries → Grains → Rice)  
**Current State:** `Product.category` is flat `CharField`  
**Required Backend Change:**
- Add `Category` model with `parent = FK(self, null=True)`
- Migrate existing flat categories to tree
- Add `category` FK to `Product` (replace `CharField`)
- Endpoint: `GET /api/categories/` returning tree
**Flutter Impact:** Expandable category sidebar

---

## GAP-006: Customer Wishlist / Favorites
**Flutter Feature:** Heart icon on products, "My Favorites" screen  
**Current State:** No model, no endpoint  
**Required Backend Change:**
- Add `Favorite` model: `user`, `product`, `created_at` (unique_together)
- Endpoints: `GET/POST/DELETE /api/favorites/`
- Include in `ProductPublicSerializer`: `is_favorited` (conditional on auth)
**Flutter Impact:** Toggle heart, persistent sync across devices

---

## GAP-007: Customer Order History (Read-Only)
**Flutter Feature:** Customer sees their past invoices  
**Current State:** `InvoiceViewSet` requires `IsShopMember` — customers cannot access  
**Required Backend Change:**
- Add `Invoice.customer = FK(CustomUser, null=True, related_name="customer_invoices")`
- On invoice creation, if `customer_phone` provided, link to customer (or create guest)
- New endpoint: `GET /api/customer/orders/` (permission: `IsCustomerOwner`)
- Serializer: same as owner but without shop-sensitive fields
**Flutter Impact:** "My Orders" tab in customer app

---

## GAP-008: Barcode / SKU Lookup
**Flutter Feature:** Scan barcode → find product instantly  
**Current State:** No barcode field on Product  
**Required Backend Change:**
- Add `Product.barcode = CharField(max_length=50, unique=True, null=True, blank=True, db_index=True)`
- Endpoint: `GET /api/products/by_barcode/{code}/` (AllowAny for published)
- Validate EAN-13/UPC format on write
**Flutter Impact:** Camera scan → API call → product detail

---

## GAP-009: Invoice PDF Generation
**Flutter Feature:** "Download Receipt" button  
**Current State:** Invoice data only — no PDF  
**Required Backend Change:**
- Add `GET /api/billing/invoices/{id}/pdf/`
- Use `weasyprint` or `reportlab` to render template
- Include: shop info, customer info, line items, totals, QR code with invoice ID
- Return `application/pdf` with `Content-Disposition: attachment`
**Flutter Impact:** Open in browser / share sheet

---

## GAP-010: Low Stock Webhook / Push Notification
**Flutter Feature:** Owner gets alert when stock ≤ threshold  
**Current State:** No event system  
**Required Backend Change:**
- Add `post_save` signal on `Product` → if `stock_quantity <= 5` and was > 5, create `Notification` for owner
- Or use Django Q / Celery for async push via FCM/APNs
- Expose `Notification` unread count in dashboard
**Flutter Impact:** Badge on inventory tab, push notification

---

## GAP-011: Multi-Shop Support for Owners
**Flutter Feature:** Owner manages multiple shops from one account  
**Current State:** `CustomUser.owned_shop` is `OneToOneField` — single shop only  
**Required Backend Change:**
- Change to `ManyToManyField` or `ForeignKey` on Shop with `related_name="owners"`
- Update `user_effective_shop()` to return list or require `shop_id` query param
- All shop-scoped views: filter by `shop_id` from request
**Flutter Impact:** Shop switcher in app bar

---

## GAP-012: Discount Coupons / Promo Codes
**Flutter Feature:** Customer enters coupon code at checkout  
**Current State:** Offers are automatic (date/active based) — no code entry  
**Required Backend Change:**
- Add `Coupon` model: `code`, `discount_type`, `discount_value`, `valid_from`, `valid_to`, `max_uses`, `used_count`, `min_order_value`, `applicable_shops/products`
- Endpoint: `POST /api/coupons/validate/` with `{code, cart_total, shop_id}`
- Apply in `InvoiceViewSet.create` before totals
**Flutter Impact:** Coupon input field in billing screen

---

## GAP-013: Sales Analytics / Time-Series Data
**Flutter Feature:** Charts: daily/weekly/monthly sales, top products  
**Current State:** Dashboard returns only aggregates (today, total)  
**Required Backend Change:**
- Add `GET /api/shops/analytics/?period=daily|weekly|monthly&days=30`
- Return: `[{date, sales, orders, avg_order_value}]`
- Add `GET /api/shops/top_products/?limit=10&period=30d`
**Flutter Impact:** `fl_chart` line/bar charts on dashboard

---

## GAP-014: Customer App Authentication (Separate from Owner)
**Flutter Feature:** Customer login/register in customer app  
**Current State:** Backend has `RegisterCustomerView` + `LoginView` — works but customer app not verified  
**Required Backend Change:**
- Verify `Customer` role permissions don't leak owner endpoints
- Add `IsCustomer` permission if needed
- Ensure JWT `role` claim is respected by all endpoints
**Flutter Impact:** Customer app auth flow

---

## GAP-015: Product Reviews / Ratings
**Flutter Feature:** Stars + reviews on product detail  
**Current State:** `Shop.rating` exists but no product reviews  
**Required Backend Change:**
- Add `Review` model: `product`, `customer`, `rating` (1-5), `comment`, `created_at`
- Endpoints: `GET/POST /api/products/{id}/reviews/`
- Aggregate: `Product.average_rating`, `review_count` (cached fields)
- Expose in `ProductPublicSerializer`
**Flutter Impact:** Review list, star rating, write review dialog

---

## GAP-016: Returns / Refunds
**Flutter Feature:** "Return Item" flow  
**Current State:** Invoice is immutable once created  
**Required Backend Change:**
- Add `Return` model linked to `InvoiceItem`: `reason`, `quantity`, `status` (PENDING/APPROVED/REJECTED), `refund_amount`
- On approve: reverse stock adjustment, create refund invoice item
- Endpoint: `POST /api/returns/`, `PATCH /api/returns/{id}/`
**Flutter Impact:** Return request screen, status tracking

---

## GAP-017: Employee Shift / Attendance
**Flutter Feature:** Worker clock-in/out, shift schedule  
**Current State:** No time tracking  
**Required Backend Change:**
- Add `Shift` model: `worker`, `shop`, `start_time`, `end_time`, `break_minutes`
- Add `Attendance` model: `worker`, `date`, `clock_in`, `clock_out`, `status`
- Endpoints for clock in/out, shift list
**Flutter Impact:** Worker time card screen

---

## GAP-018: Supplier / Purchase Orders
**Flutter Feature:** Owner orders stock from suppliers  
**Current State:** Only manual stock adjustments  
**Required Backend Change:**
- Add `Supplier` model: `name`, `contact`, `phone`, `email`, `address`
- Add `PurchaseOrder` + `PurchaseOrderItem`: `supplier`, `product`, `ordered_qty`, `received_qty`, `unit_cost`, `status`
- On receive: create positive `StockAdjustment`
**Flutter Impact:** Supplier management, PO creation, receive screen

---

## GAP-019: GST / Tax Compliance (India)
**Flutter Feature:** GST-compliant invoices with HSN/SAC codes  
**Current State:** No tax fields  
**Required Backend Change:**
- Add `Product.hsn_code`, `gst_rate` (0/5/12/18/28%)
- Add `Invoice.cgst`, `sgst`, `igst`, `total_tax`
- Compute per-line tax in `InvoiceViewSet.create`
- PDF must show tax breakdown
**Flutter Impact:** Tax fields in product create, tax breakdown in billing

---

## GAP-020: Offline-First Sync / Conflict Resolution
**Flutter Feature:** App works offline, syncs when online  
**Current State:** All writes require online  
**Required Backend Change:**
- Add `last_synced_at` to models
- Implement conflict resolution: server-wins for prices/stock, client-wins for local drafts
- Batch sync endpoint: `POST /api/sync/` with client operations array
**Flutter Impact:** Local DB (Drift/SQLite) + sync engine

---

## Summary

| Priority | Gaps |
|----------|------|
| **Critical (Blocks Flutter MVP)** | GAP-001 (Image Upload), GAP-002 (Availability) |
| **High (Customer UX)** | GAP-003 (Hours), GAP-004 (Search), GAP-007 (Customer Orders) |
| **Medium (Business Features)** | GAP-005 (Categories), GAP-006 (Wishlist), GAP-008 (Barcode), GAP-009 (PDF) |
| **Low (Advanced)** | GAP-010 to GAP-020 |

**Next Action:** Approve Critical/High gaps for implementation in Django. Flutter will not implement workarounds.