# AGENTS.md — Shop Owner Flutter App (`flutter_app`)

## 1. Purpose & Architecture
ShopGenie Owner is a cross-platform Flutter application for independent retailers and Kirana store owners.
Features: Single-shop management, real-time inventory tracking, POS checkout with atomic stock decrement, worker permission management, and sales performance dashboard.
It communicates exclusively with the Unified Django REST Backend at `R:\shopgenie backend\shopgenie_unified\`.
**Direct database or Supabase access is strictly forbidden.**

## 2. Folder Structure
```
lib/
├── api_service.dart # Central HTTP REST client with JWT auth headers
├── models.dart      # Shop, User, Worker, Product, Invoice models
└── main.dart        # Main navigation, POS billing, inventory, workers, shop profile
```

## 3. Main Entry Points
- `lib/main.dart`: Root widget `ShopGenieApp`.

## 4. Commands to Run & Test
```powershell
# Analyze
flutter analyze

# Run unit tests
flutter test

# Run app
flutter run
```

## 5. API Configuration & Auth Flow
- Configured in `lib/api_service.dart`.
- Base URL defaults to `http://10.0.2.2:8000/api` for emulator, `http://127.0.0.1:8000/api` for desktop/web.
- Production uses HTTPS.
- Authentication uses JWT Bearer tokens passed in `Authorization: Bearer <token>` header.

## 6. Prohibited & Destructive Operations
- No hardcoded / fabricated sales statistics in production workflows.
- No client-side bypass of worker permissions or single-shop ownership.
- Never commit private signing keys or credentials.
