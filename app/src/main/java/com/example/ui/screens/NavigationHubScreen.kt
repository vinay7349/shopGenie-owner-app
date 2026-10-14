package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.navigation.Screen

data class AppScreenOption(
    val title: String,
    val description: String,
    val category: String,
    val icon: ImageVector,
    val color: Color,
    val bg: Color,
    val screen: Screen
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NavigationHubScreen(
    onNavigateBack: () -> Unit,
    onNavigateTo: (Screen) -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedCategoryFilter by remember { mutableStateOf("ALL") }

    val allOptions = remember {
        listOf(
            // Overview & Dashboard
            AppScreenOption(
                title = "Store Dashboard",
                description = "Revenue KPI metrics, active bills, store terminal status & shortcuts",
                category = "Overview",
                icon = Icons.Default.Dashboard,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.Home
            ),
            // Multi-Store Management
            AppScreenOption(
                title = "My Shop (Single Ownership)",
                description = "Single-shop ownership model, edit address, category, hours & profile",
                category = "Store Management",
                icon = Icons.Default.Store,
                color = Color(0xFF0284C7),
                bg = Color(0xFFE0F2FE),
                screen = Screen.MyShop
            ),
            // Manage Workers
            AppScreenOption(
                title = "Manage Shop Workers",
                description = "Assign staff to shop, toggle active access, billing & invoice permissions",
                category = "Store Management",
                icon = Icons.Default.Groups,
                color = Color(0xFF7C3AED),
                bg = Color(0xFFEDE9FE),
                screen = Screen.ManageWorkers
            ),
            // Worker Dashboard
            AppScreenOption(
                title = "Worker POS Desk (Cashier)",
                description = "Simplified counter billing, catalog lookup, with hidden owner profit/costs",
                category = "Store Management",
                icon = Icons.Default.Badge,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.WorkerDashboard
            ),
            // Shop Discovery & Storefront
            AppScreenOption(
                title = "Shop Discovery Settings",
                description = "Listing status, public hours, bio, category, completeness score",
                category = "Store Management",
                icon = Icons.Default.Explore,
                color = Color(0xFF0284C7),
                bg = Color(0xFFE0F2FE),
                screen = Screen.ShopDiscovery
            ),
            // Customer Storefront Preview
            AppScreenOption(
                title = "Customer Storefront Preview",
                description = "Live simulation of customer storefront, branch inventory, share link",
                category = "Store Management",
                icon = Icons.Default.Storefront,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.StorefrontPreview
            ),
            // Owner Identity Verification
            AppScreenOption(
                title = "Owner Identity Verification",
                description = "Trust shield, document checklist, GSTIN, PAN & verification status",
                category = "Settings & Legal",
                icon = Icons.Default.VerifiedUser,
                color = Color(0xFF16A34A),
                bg = Color(0xFFDCFCE7),
                screen = Screen.IdentityVerification
            ),
            // Offers & Loyalty
            AppScreenOption(
                title = "Offers & Customer Loyalty",
                description = "Active discount coupons, loyalty points rate, launch promo codes",
                category = "Store Management",
                icon = Icons.Default.Loyalty,
                color = Color(0xFFDC2626),
                bg = Color(0xFFFEE2E2),
                screen = Screen.OffersLoyalty
            ),
            // Shop Operational Settings
            AppScreenOption(
                title = "Shop Operational Settings",
                description = "Tax/GST rate, thermal invoice serial prefix, receipt headers & notes",
                category = "Settings & Legal",
                icon = Icons.Default.Receipt,
                color = Color(0xFF475569),
                bg = Color(0xFFF1F5F9),
                screen = Screen.ShopSettings
            ),
            // Catalog & Inventory
            AppScreenOption(
                title = "Catalog & Products",
                description = "Searchable product list, price per unit/kg, wholesale cost & categories",
                category = "Inventory",
                icon = Icons.Default.Inventory2,
                color = Color(0xFF0284C7),
                bg = Color(0xFFE0F2FE),
                screen = Screen.ProductList
            ),
            AppScreenOption(
                title = "Add New Product",
                description = "Register Unit or KG item with cost & retail prices and stock count",
                category = "Inventory",
                icon = Icons.Default.AddBox,
                color = Color(0xFF4F46E5),
                bg = Color(0xFFEEF2FF),
                screen = Screen.AddProduct()
            ),
            AppScreenOption(
                title = "Stock & Inventory Health",
                description = "Stock level meters, reorder alerts (<5 units), and quick restock dialog",
                category = "Inventory",
                icon = Icons.Default.Warehouse,
                color = Color(0xFF16A34A),
                bg = Color(0xFFDCFCE7),
                screen = Screen.Inventory
            ),
            AppScreenOption(
                title = "Product Overview & SKU Details",
                description = "Inspect wholesale cost, retail price, margins & SKU stock breakdown",
                category = "Inventory",
                icon = Icons.Default.Info,
                color = Color(0xFF0284C7),
                bg = Color(0xFFE0F2FE),
                screen = Screen.ProductDetail(productId = 1)
            ),
            // POS & Weighing
            AppScreenOption(
                title = "Loose Commodities & Plain Bags",
                description = "Select unbranded sugar, grains, pulses for weight-based billing",
                category = "POS & Weighing",
                icon = Icons.Default.Scale,
                color = Color(0xFFD97706),
                bg = Color(0xFFFFE0B2),
                screen = Screen.LooseItemSelection
            ),
            AppScreenOption(
                title = "Smart Scale Weighing Readout",
                description = "Electronic digital scale simulation with tare, kg/g price calculator",
                category = "POS & Weighing",
                icon = Icons.Default.FitnessCenter,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.WeightInput(productId = 1, productName = "Sugar (Loose Grade A)", pricePerKg = 44.0)
            ),
            // Vision AI
            AppScreenOption(
                title = "AI Camera & ESP32 Scanner",
                description = "Visual object classification & optical recognition viewfinder with simulation",
                category = "Vision AI",
                icon = Icons.Default.CameraAlt,
                color = Color(0xFF7C3AED),
                bg = Color(0xFFEDE9FE),
                screen = Screen.CameraScan
            ),
            AppScreenOption(
                title = "AI Recognition Candidates",
                description = "Inspect vision confidence, similarity score & candidate confirmation",
                category = "Vision AI",
                icon = Icons.Default.CheckCircle,
                color = Color(0xFF7C3AED),
                bg = Color(0xFFEDE9FE),
                screen = Screen.ScanResult(matchType = "PRODUCT", productId = 1)
            ),
            // POS & Billing
            AppScreenOption(
                title = "Active POS Billing Cart",
                description = "Cart stepper controls, item counts, subtotal calculation and clear cart",
                category = "POS & Billing",
                icon = Icons.Default.ShoppingCart,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.Cart
            ),
            AppScreenOption(
                title = "Order Checkout & Payment",
                description = "Cash with change calculator, UPI QR, and Card payment settlement",
                category = "POS & Billing",
                icon = Icons.Default.Payment,
                color = Color(0xFFD97706),
                bg = Color(0xFFFFE0B2),
                screen = Screen.Checkout
            ),
            AppScreenOption(
                title = "Digital Thermal Receipt",
                description = "Itemized tax invoice with timestamps, totals & paid status",
                category = "POS & Billing",
                icon = Icons.Default.ReceiptLong,
                color = Color(0xFF0284C7),
                bg = Color(0xFFE0F2FE),
                screen = Screen.InvoiceReceipt(invoiceId = 101)
            ),
            // Analytics
            AppScreenOption(
                title = "Sales Analytics & Reports",
                description = "Daily revenue metrics, order velocity, margin breakdown & payment split",
                category = "Analytics",
                icon = Icons.Default.TrendingUp,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.SalesAnalytics
            ),
            // Settings & Profile
            AppScreenOption(
                title = "Profile & Appearance Themes",
                description = "Switch Light / Dark / System mode, backend endpoints, and merchant ID",
                category = "Settings & Legal",
                icon = Icons.Default.Palette,
                color = Color(0xFF475569),
                bg = Color(0xFFF1F5F9),
                screen = Screen.Profile
            ),
            // Authentication
            AppScreenOption(
                title = "Merchant Sign In",
                description = "HosaFlow-inspired login panel with Demo Auto-fill & JWT auth",
                category = "Account",
                icon = Icons.Default.Login,
                color = Color(0xFF006C4C),
                bg = Color(0xFFD1FAE5),
                screen = Screen.Login
            ),
            AppScreenOption(
                title = "Register Store",
                description = "Store registration with owner phone number, name & Kirana shop details",
                category = "Account",
                icon = Icons.Default.PersonAdd,
                color = Color(0xFF4F46E5),
                bg = Color(0xFFEEF2FF),
                screen = Screen.Register
            )
        )
    }

    val categories = listOf("ALL", "Store Management", "Inventory", "POS & Weighing", "POS & Billing", "Vision AI", "Analytics", "Settings & Legal", "Account")

    val filteredOptions = allOptions.filter {
        val matchesSearch = it.title.contains(searchQuery, ignoreCase = true) ||
                it.description.contains(searchQuery, ignoreCase = true) ||
                it.category.contains(searchQuery, ignoreCase = true)
        val matchesCategory = when (selectedCategoryFilter) {
            "ALL" -> true
            else -> it.category.equals(selectedCategoryFilter, ignoreCase = true)
        }
        matchesSearch && matchesCategory
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Navigation & Options Hub", fontWeight = FontWeight.Bold)
                        Text(
                            "Instant access to all ${allOptions.size} app options",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Search Input
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search by name, feature, or category...") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear")
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp)
            )

            // Category Filter Pills
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                categories.forEach { category ->
                    val isSelected = selectedCategoryFilter == category
                    FilterChip(
                        selected = isSelected,
                        onClick = { selectedCategoryFilter = category },
                        label = { Text(category, fontSize = 12.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primary,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                        )
                    )
                }
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(filteredOptions, key = { it.title }) { option ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onNavigateTo(option.screen) },
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        border = CardDefaults.outlinedCardBorder()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(option.bg),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = option.icon,
                                    contentDescription = null,
                                    tint = option.color,
                                    modifier = Modifier.size(24.dp)
                                )
                            }

                            Spacer(modifier = Modifier.width(14.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Text(
                                        text = option.title,
                                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Surface(
                                        color = MaterialTheme.colorScheme.surfaceVariant,
                                        shape = RoundedCornerShape(4.dp)
                                    ) {
                                        Text(
                                            text = option.category.uppercase(),
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                                Spacer(modifier = Modifier.height(3.dp))
                                Text(
                                    text = option.description,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 2
                                )
                            }

                            Spacer(modifier = Modifier.width(8.dp))

                            // Action button
                            FilledTonalButton(
                                onClick = { onNavigateTo(option.screen) },
                                shape = RoundedCornerShape(10.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Text("Enter", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.width(2.dp))
                                Icon(
                                    imageVector = Icons.Default.ChevronRight,
                                    contentDescription = "Open",
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
