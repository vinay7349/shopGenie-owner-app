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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.api.NetworkClient
import com.example.data.models.ProductDto
import com.example.ui.cart.CartManager
import com.example.ui.components.EmptyStateCard
import com.example.ui.components.ErrorBanner
import com.example.ui.components.LoadingStateIndicator
import com.example.ui.components.SellingBadge
import com.example.ui.components.StockBadge
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductListScreen(
    networkClient: NetworkClient,
    onNavigateBack: () -> Unit,
    onNavigateDetail: (productId: Int) -> Unit,
    onNavigateAdd: () -> Unit,
    onNavigateWeightInput: (productId: Int, productName: String, pricePerKg: Double) -> Unit
) {
    var products by remember { mutableStateOf<List<ProductDto>>(emptyList()) }
    var searchQuery by remember { mutableStateOf("") }
    var selectedFilter by remember { mutableStateOf("ALL") } // ALL, UNIT, KG, LOOSE
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var addedSnackMessage by remember { mutableStateOf<String?>(null) }

    val coroutineScope = rememberCoroutineScope()

    fun loadProducts() {
        isLoading = true
        errorMessage = null
        coroutineScope.launch {
            try {
                val res = networkClient.apiService.getProducts()
                if (res.isSuccessful && !res.body().isNullOrEmpty()) {
                    com.example.data.repository.ProductRepository.syncFromBackend(res.body()!!)
                }
            } catch (_: Exception) {
                // Offline fallback handled by ProductRepository
            }
            products = com.example.data.repository.ProductRepository.getAllProducts()
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        loadProducts()
    }

    val filteredProducts = products.filter {
        val matchesSearch = it.name.contains(searchQuery, ignoreCase = true) ||
                it.category.contains(searchQuery, ignoreCase = true)
        val matchesFilter = when (selectedFilter) {
            "UNIT" -> it.sellingType == "UNIT"
            "KG" -> it.sellingType == "KG"
            "LOOSE" -> it.isLoose
            else -> true
        }
        matchesSearch && matchesFilter
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Product Catalog", fontWeight = FontWeight.Bold)
                        Text(
                            "${products.size} Items in inventory",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { loadProducts() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        },
        floatingActionButton = {
            if (networkClient.isOwner) {
                ExtendedFloatingActionButton(
                    onClick = onNavigateAdd,
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = Color.White,
                    shape = RoundedCornerShape(16.dp),
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("Add Product", fontWeight = FontWeight.Bold) }
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                placeholder = { Text("Search by product name or category...") },
                leadingIcon = {
                    Icon(
                        Icons.Default.Search,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear")
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline
                )
            )

            // Category Filter Chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedFilter == "ALL",
                    onClick = { selectedFilter = "ALL" },
                    label = { Text("All Items (${products.size})") },
                    shape = RoundedCornerShape(8.dp)
                )
                FilterChip(
                    selected = selectedFilter == "UNIT",
                    onClick = { selectedFilter = "UNIT" },
                    label = { Text("Packaged (Unit)") },
                    shape = RoundedCornerShape(8.dp)
                )
                FilterChip(
                    selected = selectedFilter == "KG",
                    onClick = { selectedFilter = "KG" },
                    label = { Text("By Weight (Kg)") },
                    shape = RoundedCornerShape(8.dp)
                )
                FilterChip(
                    selected = selectedFilter == "LOOSE",
                    onClick = { selectedFilter = "LOOSE" },
                    label = { Text("Loose Commodities") },
                    shape = RoundedCornerShape(8.dp)
                )
            }

            if (addedSnackMessage != null) {
                Surface(
                    color = Color(0xFFD1FAE5),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF006C4C), modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(addedSnackMessage!!, color = Color(0xFF006C4C), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            when {
                isLoading -> {
                    LoadingStateIndicator(message = "Loading store catalog...")
                }
                errorMessage != null -> {
                    ErrorBanner(errorMessage = errorMessage!!, onRetry = { loadProducts() })
                }
                filteredProducts.isEmpty() -> {
                    EmptyStateCard(
                        icon = Icons.Default.Inventory2,
                        title = "No Products Found",
                        description = if (searchQuery.isNotEmpty()) "No items match '$searchQuery'." else "You haven't added any products to your shop catalog yet.",
                        actionButtonText = "Add First Product",
                        onActionClick = onNavigateAdd
                    )
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 80.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        items(filteredProducts, key = { it.id }) { product ->
                            ModernProductCard(
                                product = product,
                                onClick = { onNavigateDetail(product.id) },
                                onAddToCart = {
                                    if (product.sellingType == "KG") {
                                        onNavigateWeightInput(product.id, product.name, product.pricePerUnit)
                                    } else {
                                        CartManager.addItem(product, 1.0)
                                        addedSnackMessage = "Added ${product.name} to bill"
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ModernProductCard(
    product: ProductDto,
    onClick: () -> Unit,
    onAddToCart: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
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
            // Category Icon Badge
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = when {
                        product.isLoose || product.sellingType == "KG" -> Icons.Default.Scale
                        product.category.contains("Snack", ignoreCase = true) -> Icons.Default.Fastfood
                        product.category.contains("Oil", ignoreCase = true) -> Icons.Default.Opacity
                        else -> Icons.Default.ShoppingBag
                    },
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = product.category.uppercase(),
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }

                    SellingBadge(sellingType = product.sellingType, isLoose = product.isLoose)
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = product.name,
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.Bottom) {
                            Text(
                                text = "₹${String.format("%.2f", product.pricePerUnit)}",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.ExtraBold),
                                color = MaterialTheme.colorScheme.primary
                            )
                            Text(
                                text = " / ${product.sellingType.lowercase()}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    StockBadge(
                        quantity = product.quantity,
                        sellingType = product.sellingType
                    )
                }
            }

            Spacer(modifier = Modifier.width(10.dp))

            // Quick Add Action Button (48dp touch target)
            FilledTonalIconButton(
                onClick = onAddToCart,
                modifier = Modifier.size(42.dp),
                shape = CircleShape,
                colors = IconButtonDefaults.filledTonalIconButtonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = Color.White
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add to bill",
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}
