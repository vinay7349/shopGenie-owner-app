package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.api.NetworkClient
import com.example.data.models.ProductDto
import com.example.ui.cart.CartManager
import com.example.ui.components.MetricSummaryCard
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    networkClient: NetworkClient,
    onNavigateScan: () -> Unit,
    onNavigateProducts: () -> Unit,
    onNavigateInventory: () -> Unit,
    onNavigateCart: () -> Unit,
    onNavigateAddProduct: () -> Unit,
    onNavigateLooseSelection: () -> Unit,
    onNavigateProfile: () -> Unit,
    onNavigateHub: () -> Unit = {},
    onNavigateAnalytics: () -> Unit = {},
    onNavigateManageShops: () -> Unit = {},
    onNavigateMyShop: () -> Unit = onNavigateManageShops,
    onNavigateManageWorkers: () -> Unit = {},
    onNavigateDiscovery: () -> Unit = {},
    onNavigatePreview: () -> Unit = {},
    onNavigateVerification: () -> Unit = {},
    onNavigateOffers: () -> Unit = {},
    onNavigateSettings: () -> Unit = {}
) {
    val myShopState by com.example.data.repository.ShopManager.myShop.collectAsState()
    val activeShop = myShopState ?: com.example.data.repository.ShopManager.activeShop.collectAsState().value
    val username = networkClient.currentUsername ?: "shopowner"
    val cartCount = CartManager.itemCount
    val cartTotal = CartManager.totalAmount

    var products by remember { mutableStateOf<List<ProductDto>>(emptyList()) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        coroutineScope.launch {
            try {
                val res = networkClient.apiService.getProducts()
                if (res.isSuccessful && !res.body().isNullOrEmpty()) {
                    com.example.data.repository.ProductRepository.syncFromBackend(res.body()!!)
                }
            } catch (_: Exception) {}
            products = com.example.data.repository.ProductRepository.getAllProducts()
        }
    }

    val lowStockCount = products.count { it.quantity <= 5.0 }
    val totalStockValuation = products.sumOf { it.pricePerUnit * it.quantity }
    val todayRevenue = com.example.data.repository.ProductRepository.getTodayRevenue()
    val orderCount = com.example.data.repository.ProductRepository.getInvoices().size

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.clickable { onNavigateMyShop() }
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(MaterialTheme.colorScheme.primaryContainer),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.Storefront,
                                contentDescription = "My Shop",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(22.dp)
                            )
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = activeShop.name,
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    maxLines = 1
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Icon(
                                    Icons.Default.Verified,
                                    contentDescription = "Verified Owner Store",
                                    tint = Color(0xFF16A34A),
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = activeShop.location,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 1
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                // Status chip
                                Surface(
                                    color = if (activeShop.isVerified) Color(0xFFDCFCE7) else Color(0xFFFEF3C7),
                                    shape = RoundedCornerShape(4.dp)
                                ) {
                                    Text(
                                        text = activeShop.verificationStatus.uppercase(),
                                        fontSize = 8.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (activeShop.isVerified) Color(0xFF16A34A) else Color(0xFFD97706),
                                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                                    )
                                }
                            }
                        }
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateHub) {
                        Icon(Icons.Default.Apps, contentDescription = "All Screens Hub", tint = MaterialTheme.colorScheme.primary)
                    }
                    IconButton(onClick = onNavigateProfile) {
                        Icon(Icons.Default.AccountCircle, contentDescription = "Profile", tint = MaterialTheme.colorScheme.onSurface)
                    }
                }
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 6.dp
            ) {
                NavigationBarItem(
                    selected = true,
                    onClick = { /* Already Home */ },
                    icon = { Icon(Icons.Default.Dashboard, contentDescription = "Dashboard") },
                    label = { Text("Dashboard") }
                )
                NavigationBarItem(
                    selected = false,
                    onClick = onNavigateProducts,
                    icon = { Icon(Icons.Default.Inventory2, contentDescription = "Catalog") },
                    label = { Text("Catalog") }
                )
                NavigationBarItem(
                    selected = false,
                    onClick = onNavigateScan,
                    icon = {
                        BadgedBox(badge = {
                            Badge(containerColor = MaterialTheme.colorScheme.secondary) { Text("AI") }
                        }) {
                            Icon(Icons.Default.QrCodeScanner, contentDescription = "AI Scanner")
                        }
                    },
                    label = { Text("Scan") }
                )
                NavigationBarItem(
                    selected = false,
                    onClick = onNavigateCart,
                    icon = {
                        BadgedBox(badge = {
                            if (cartCount > 0) {
                                Badge(containerColor = MaterialTheme.colorScheme.primary) { Text("$cartCount") }
                            }
                        }) {
                            Icon(Icons.Default.ShoppingCart, contentDescription = "Cart")
                        }
                    },
                    label = { Text("Bill") }
                )
                NavigationBarItem(
                    selected = false,
                    onClick = onNavigateHub,
                    icon = { Icon(Icons.Default.Apps, contentDescription = "All Options") },
                    label = { Text("All") }
                )
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Active Cart Banner (When cart has items)
            if (cartCount > 0) {
                item {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onNavigateCart() },
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
                        shape = RoundedCornerShape(16.dp),
                        border = CardDefaults.outlinedCardBorder()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(MaterialTheme.colorScheme.secondary),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        Icons.Default.ShoppingCart,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(
                                        text = "Active Bill: $cartCount item${if (cartCount > 1) "s" else ""}",
                                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                                        color = MaterialTheme.colorScheme.onSecondaryContainer
                                    )
                                    Text(
                                        text = "Subtotal: ₹${String.format("%.2f", cartTotal)}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSecondaryContainer
                                    )
                                }
                            }
                            Button(
                                onClick = onNavigateCart,
                                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary),
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text("Checkout", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            // All Screens Hub Quick Access Strip
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onNavigateHub() },
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    shape = RoundedCornerShape(16.dp),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(Color(0xFFEDE9FE)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Apps, contentDescription = null, tint = Color(0xFF7C3AED), modifier = Modifier.size(20.dp))
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text(
                                    "All Screen Options Hub",
                                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                                )
                                Text(
                                    "Jump directly into any of the 13+ screens",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    }
                }
            }

            // HosaFlow-Inspired Hero Banner: AI Visual POS Terminal
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onNavigateScan() },
                    shape = RoundedCornerShape(20.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                Brush.horizontalGradient(
                                    colors = listOf(
                                        Color(0xFF004D36),
                                        Color(0xFF006C4C),
                                        Color(0xFF00895E)
                                    )
                                )
                            )
                            .padding(20.dp)
                    ) {
                        Column {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Surface(
                                    color = Color.White.copy(alpha = 0.2f),
                                    shape = RoundedCornerShape(20.dp)
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(6.dp)
                                                .clip(CircleShape)
                                                .background(Color(0xFF8CF4C5))
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = "SMART VISION TERMINAL",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color.White
                                        )
                                    }
                                }

                                Icon(
                                    Icons.Default.AutoAwesome,
                                    contentDescription = null,
                                    tint = Color(0xFFFFDDB3),
                                    modifier = Modifier.size(24.dp)
                                )
                            }

                            Spacer(modifier = Modifier.height(14.dp))

                            Text(
                                text = "Instant Camera Checkout",
                                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = Color.White
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Point camera at branded packets or loose bags for 1-tap recognition",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.85f)
                            )

                            Spacer(modifier = Modifier.height(16.dp))

                            Button(
                                onClick = onNavigateScan,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = Color.White,
                                    contentColor = Color(0xFF006C4C)
                                ),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Icon(
                                    Icons.Default.CameraAlt,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Start AI Scan",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )
                            }
                        }
                    }
                }
            }

            // Key Retail Metrics Grid
            item {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Retail Overview",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = MaterialTheme.colorScheme.onBackground
                        )
                        Text(
                            text = "Today",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        MetricSummaryCard(
                            title = "Catalog Items",
                            value = "${products.size} SKUs",
                            icon = Icons.Default.Inventory2,
                            iconTint = Color(0xFF0284C7),
                            iconBg = Color(0xFFE0F2FE),
                            trendText = "Active",
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateProducts
                        )

                        MetricSummaryCard(
                            title = "Today's Sales",
                            value = if (todayRevenue > 0) "₹${String.format("%.0f", todayRevenue)}" else "₹1,450",
                            icon = Icons.Default.CurrencyRupee,
                            iconTint = Color(0xFF16A34A),
                            iconBg = Color(0xFFDCFCE7),
                            trendText = "$orderCount Orders",
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateAnalytics
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        MetricSummaryCard(
                            title = "Low Stock Alert",
                            value = "$lowStockCount Items",
                            subtitle = if (lowStockCount > 0) "Needs restock" else "Healthy",
                            icon = Icons.Default.Warning,
                            iconTint = if (lowStockCount > 0) Color(0xFFDC2626) else Color(0xFF16A34A),
                            iconBg = if (lowStockCount > 0) Color(0xFFFEE2E2) else Color(0xFFDCFCE7),
                            trendText = if (lowStockCount > 0) "Action" else "Good",
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateInventory
                        )

                        MetricSummaryCard(
                            title = "Customer Visits",
                            value = "142 Views",
                            subtitle = "Local discovery",
                            icon = Icons.Default.Visibility,
                            iconTint = Color(0xFF7C3AED),
                            iconBg = Color(0xFFEDE9FE),
                            trendText = "+18% wk",
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateDiscovery
                        )
                    }
                }
            }

            // Quick Operations & Shortcuts (All Requested Options)
            item {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Quick Actions & Management",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = MaterialTheme.colorScheme.onBackground
                        )
                        TextButton(onClick = onNavigateHub) {
                            Text("View All Options", fontWeight = FontWeight.Bold)
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Row 1: Manage Products & Inventory
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Manage Products",
                            subtitle = "Catalog & pricing",
                            icon = Icons.Default.Inventory2,
                            iconColor = Color(0xFF0284C7),
                            iconBg = Color(0xFFE0F2FE),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateProducts
                        )

                        ModernActionCard(
                            title = "Inventory Health",
                            subtitle = "Stock levels & restock",
                            icon = Icons.Default.Warehouse,
                            iconColor = Color(0xFF16A34A),
                            iconBg = Color(0xFFDCFCE7),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateInventory
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Row 2: Shop Settings & Shop Discovery Settings
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Shop Settings",
                            subtitle = "GST, receipt & contact",
                            icon = Icons.Default.Settings,
                            iconColor = Color(0xFF475569),
                            iconBg = Color(0xFFF1F5F9),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateSettings
                        )

                        ModernActionCard(
                            title = "Discovery Settings",
                            subtitle = "Public listing & hours",
                            icon = Icons.Default.Explore,
                            iconColor = Color(0xFF0284C7),
                            iconBg = Color(0xFFE0F2FE),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateDiscovery
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Row 3: Storefront & Links & Customer Preview
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Storefront Preview",
                            subtitle = "Customer live view",
                            icon = Icons.Default.Storefront,
                            iconColor = Color(0xFF006C4C),
                            iconBg = Color(0xFFD1FAE5),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigatePreview
                        )

                        ModernActionCard(
                            title = "My Shop",
                            subtitle = "Store profile & details",
                            icon = Icons.Default.Store,
                            iconColor = Color(0xFF0284C7),
                            iconBg = Color(0xFFE0F2FE),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateMyShop
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Row: Staff & Worker Management
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Manage Workers",
                            subtitle = "Assign staff & permissions",
                            icon = Icons.Default.Groups,
                            iconColor = Color(0xFF7C3AED),
                            iconBg = Color(0xFFEDE9FE),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateManageWorkers
                        )

                        ModernActionCard(
                            title = "Business Insights",
                            subtitle = "Sales & profit metrics",
                            icon = Icons.Default.TrendingUp,
                            iconColor = Color(0xFF006C4C),
                            iconBg = Color(0xFFD1FAE5),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateAnalytics
                        )
                    }

                    // Row 4: Offers and Loyalty & Business Insights
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Offers & Loyalty",
                            subtitle = "Coupons & discounts",
                            icon = Icons.Default.Loyalty,
                            iconColor = Color(0xFFDC2626),
                            iconBg = Color(0xFFFEE2E2),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateOffers
                        )

                        ModernActionCard(
                            title = "Business Insights",
                            subtitle = "Revenue & velocity charts",
                            icon = Icons.Default.TrendingUp,
                            iconColor = Color(0xFF006C4C),
                            iconBg = Color(0xFFD1FAE5),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateAnalytics
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Row 5: Owner Verification & Loose Commodity Weighing
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Owner Verification",
                            subtitle = activeShop.verificationStatus,
                            icon = Icons.Default.VerifiedUser,
                            iconColor = if (activeShop.isVerified) Color(0xFF16A34A) else Color(0xFFD97706),
                            iconBg = if (activeShop.isVerified) Color(0xFFDCFCE7) else Color(0xFFFEF3C7),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateVerification
                        )

                        ModernActionCard(
                            title = "Loose Weighing",
                            subtitle = "Sugar, Grains & Pulses",
                            icon = Icons.Default.Scale,
                            iconColor = Color(0xFFD97706),
                            iconBg = Color(0xFFFFE0B2),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateLooseSelection
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Row 6: Add Product & All Options Hub
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ModernActionCard(
                            title = "Add Product",
                            subtitle = "Register Unit or KG item",
                            icon = Icons.Default.AddBox,
                            iconColor = Color(0xFF4F46E5),
                            iconBg = Color(0xFFEEF2FF),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateAddProduct
                        )

                        ModernActionCard(
                            title = "All App Options Hub",
                            subtitle = "Direct access to 24+ screens",
                            icon = Icons.Default.Apps,
                            iconColor = Color(0xFF7C3AED),
                            iconBg = Color(0xFFEDE9FE),
                            modifier = Modifier.weight(1f),
                            onClick = onNavigateHub
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ModernActionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    iconColor: Color,
    iconBg: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = CardDefaults.outlinedCardBorder()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(iconBg),
                contentAlignment = Alignment.Center
            ) {
                Icon(imageVector = icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(24.dp))
            }
            Spacer(modifier = Modifier.height(14.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// Fallback sample catalog for offline preview
fun getSampleProducts(): List<ProductDto> {
    return listOf(
        ProductDto(id = 1, name = "Aashirvaad Shudh Chakki Atta 5kg", category = "Flour & Atta", sellingType = "UNIT", costPrice = 210.0, pricePerUnit = 250.0, quantity = 15.0, formattedQuantity = "15 units", isLoose = false),
        ProductDto(id = 2, name = "Fortune Sunlite Sunflower Oil 1L", category = "Oils & Ghee", sellingType = "UNIT", costPrice = 125.0, pricePerUnit = 145.0, quantity = 24.0, formattedQuantity = "24 units", isLoose = false),
        ProductDto(id = 3, name = "Premium Sugar (Loose)", category = "Groceries", sellingType = "KG", costPrice = 38.0, pricePerUnit = 44.0, quantity = 65.0, formattedQuantity = "65.000 kg", isLoose = true),
        ProductDto(id = 4, name = "Moong Dal Whole", category = "Grains & Pulses", sellingType = "KG", costPrice = 98.0, pricePerUnit = 120.0, quantity = 32.0, formattedQuantity = "32.000 kg", isLoose = true),
        ProductDto(id = 5, name = "Tata Salt Vacuum Evaporated 1kg", category = "Groceries", sellingType = "UNIT", costPrice = 22.0, pricePerUnit = 28.0, quantity = 4.0, formattedQuantity = "4 units", isLoose = false),
        ProductDto(id = 6, name = "Turmeric Powder Haldi 100g", category = "Spices", sellingType = "UNIT", costPrice = 25.0, pricePerUnit = 35.0, quantity = 3.0, formattedQuantity = "3 units", isLoose = false),
        ProductDto(id = 7, name = "Parle-G Gold Biscuits 250g", category = "Snacks", sellingType = "UNIT", costPrice = 20.0, pricePerUnit = 25.0, quantity = 50.0, formattedQuantity = "50 units", isLoose = false),
        ProductDto(id = 8, name = "Basmati Rice Royal 1kg", category = "Grains & Pulses", sellingType = "KG", costPrice = 85.0, pricePerUnit = 110.0, quantity = 25.0, formattedQuantity = "25.000 kg", isLoose = true)
    )
}
