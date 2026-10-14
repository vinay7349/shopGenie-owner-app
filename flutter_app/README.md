# ShopGenie Flutter & Dart Application

This directory contains the cross-platform **Flutter & Dart** implementation of ShopGenie AI, fully mirrored from the native Android Jetpack Compose app and connected to the Django REST Framework backend.

## Architecture

- **`pubspec.yaml`**: Project manifest, dependencies (`http`, `provider`, `intl`, `camera`, Material 3).
- **`lib/models.dart`**: Complete Dart data models (`Shop`, `User`, `Worker`, `Product`, `InvoiceItem`) mapping 1:1 with the Django REST Framework API.
- **`lib/api_service.dart`**: REST client handling JWT token authentication, single-shop endpoints (`/api/shops/my_shop/`), worker management (`/api/workers/`), products, and atomic bill checkout.
- **`lib/main.dart`**: Material 3 UI implementing:
  - **Single-Shop Ownership**: "My Shop" view replaces multi-shop selectors; displays verification, address, hours, and worker counts.
  - **Role-Based Interfaces**: 
    - `SHOP_OWNER`: Dashboard with gross sales and net profit, Add Product, Inventory with cost price & margin visibility, Worker Management (activation toggle, permissions), and My Shop settings.
    - `SHOP_WORKER`: Simplified dashboard, POS checkout with camera scan simulation, product search with cost prices hidden, and profile view.
  - **Shared POS & Inventory**: Real-time product search, loose/packaged item handling, and atomic checkout.

## Running Locally

To run this Flutter app on your machine:

```bash
cd flutter_app
flutter pub get
flutter run
```
