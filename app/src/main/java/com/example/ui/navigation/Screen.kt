package com.example.ui.navigation

sealed class Screen {
    // 1. Splash Screen
    object Splash : Screen()

    // 2. Login Screen
    object Login : Screen()

    // 3. Registration Screen
    object Register : Screen()

    // 4. Home / Dashboard Screen
    object Home : Screen()

    // 5. Product List Screen
    object ProductList : Screen()

    // 6. Product Details Screen
    data class ProductDetail(val productId: Int) : Screen()

    // 7. Add / Register Product Screen
    data class AddProduct(val initialName: String? = null, val isLoose: Boolean = false) : Screen()

    // 8. Inventory Screen
    object Inventory : Screen()

    // 9. Cart Screen
    object Cart : Screen()

    // 10. Checkout Screen
    object Checkout : Screen()

    // 11. Invoice / Receipt Screen
    data class InvoiceReceipt(val invoiceId: Int) : Screen()

    // 12. Camera / AI Scan Screen
    object CameraScan : Screen()

    // 13. Loose Item / Plain-bag Selection Screen
    object LooseItemSelection : Screen()

    // 14. Weight Input Screen
    data class WeightInput(val productId: Int, val productName: String, val pricePerKg: Double) : Screen()

    // 15. Scan Result and Candidate-selection Screen
    data class ScanResult(val matchType: String, val productId: Int? = null, val candidateJson: String? = null) : Screen()

    // 16. Profile / Logout Screen
    object Profile : Screen()

    // 17. Navigation Hub (Direct Access to All Options)
    object NavigationHub : Screen()

    // 18. Sales Analytics & Revenue Reports
    object SalesAnalytics : Screen()

    // 19. Single Shop Management ("My Shop")
    object MyShop : Screen()
    object ManageShops : Screen() // Maintained for seamless backwards compatibility

    // 20. Worker Management (Shop Owner Only)
    object ManageWorkers : Screen()

    // 21. Worker Dashboard (Simplified Counter & Billing UI)
    object WorkerDashboard : Screen()

    // 20. Shop Discovery & Storefront Management
    object ShopDiscovery : Screen()

    // 21. Customer-Facing Storefront Preview
    object StorefrontPreview : Screen()

    // 22. Owner Identity Verification
    object IdentityVerification : Screen()

    // 23. Offers & Loyalty Programs
    object OffersLoyalty : Screen()

    // 24. Shop Operational Settings
    object ShopSettings : Screen()
}
