package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import com.example.ui.components.EmptyStateCard
import com.example.ui.components.ErrorBanner
import com.example.ui.components.LoadingStateIndicator
import com.example.ui.components.StockBadge
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InventoryScreen(
    networkClient: NetworkClient,
    onNavigateBack: () -> Unit,
    onNavigateAddProduct: () -> Unit
) {
    var products by remember { mutableStateOf<List<ProductDto>>(emptyList()) }
    var selectedFilter by remember { mutableStateOf("ALL") } // ALL, LOW, GOOD
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val coroutineScope = rememberCoroutineScope()

    var editingProduct by remember { mutableStateOf<ProductDto?>(null) }
    var newQuantityInput by remember { mutableStateOf("") }

    fun loadInventory() {
        isLoading = true
        errorMessage = null
        coroutineScope.launch {
            try {
                val res = networkClient.apiService.getProducts()
                if (res.isSuccessful && !res.body().isNullOrEmpty()) {
                    com.example.data.repository.ProductRepository.syncFromBackend(res.body()!!)
                }
            } catch (_: Exception) {
                // Offline resilience handled by ProductRepository
            }
            products = com.example.data.repository.ProductRepository.getAllProducts()
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        loadInventory()
    }

    val totalItems = products.size
    val lowStockItems = products.filter { it.quantity <= 5.0 }
    val totalStockValue = products.sumOf { it.pricePerUnit * it.quantity }

    val displayList = when (selectedFilter) {
        "LOW" -> products.filter { it.quantity <= 5.0 }
        "GOOD" -> products.filter { it.quantity > 5.0 }
        else -> products
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Inventory & Stock Health", fontWeight = FontWeight.Bold)
                        Text(
                            "Real-time stock monitor",
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
                    IconButton(onClick = { loadInventory() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
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
            when {
                isLoading -> LoadingStateIndicator(message = "Calculating inventory health...")
                errorMessage != null -> ErrorBanner(errorMessage = errorMessage!!, onRetry = { loadInventory() })
                products.isEmpty() -> {
                    EmptyStateCard(
                        icon = Icons.Default.Warehouse,
                        title = "No Inventory Records",
                        description = "Add catalog products to monitor stock quantities and low-stock alerts.",
                        actionButtonText = "Add First Product",
                        onActionClick = onNavigateAddProduct
                    )
                }
                else -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        // 3 Key Stock Health Summary Cards
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Card(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(14.dp),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                border = CardDefaults.outlinedCardBorder()
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Text("Total SKUs", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text("$totalItems", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold))
                                }
                            }

                            Card(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(14.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = if (lowStockItems.isNotEmpty()) Color(0xFFFEF3C7) else MaterialTheme.colorScheme.surface
                                ),
                                border = CardDefaults.outlinedCardBorder()
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Text(
                                        "Low Stock",
                                        fontSize = 11.sp,
                                        color = if (lowStockItems.isNotEmpty()) Color(0xFFD97706) else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        "${lowStockItems.size}",
                                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                        color = if (lowStockItems.isNotEmpty()) Color(0xFFD97706) else MaterialTheme.colorScheme.onSurface
                                    )
                                }
                            }

                            Card(
                                modifier = Modifier.weight(1.2f),
                                shape = RoundedCornerShape(14.dp),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                border = CardDefaults.outlinedCardBorder()
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Text("Est. Valuation", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        "₹${String.format("%.0f", totalStockValue)}",
                                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Filter Chips
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            FilterChip(
                                selected = selectedFilter == "ALL",
                                onClick = { selectedFilter = "ALL" },
                                label = { Text("All ($totalItems)") },
                                shape = RoundedCornerShape(8.dp)
                            )
                            FilterChip(
                                selected = selectedFilter == "LOW",
                                onClick = { selectedFilter = "LOW" },
                                label = { Text("Low Stock (${lowStockItems.size})") },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = Color(0xFFFEF3C7),
                                    selectedLabelColor = Color(0xFFD97706)
                                ),
                                shape = RoundedCornerShape(8.dp)
                            )
                            FilterChip(
                                selected = selectedFilter == "GOOD",
                                onClick = { selectedFilter = "GOOD" },
                                label = { Text("Healthy Stock (${totalItems - lowStockItems.size})") },
                                shape = RoundedCornerShape(8.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            contentPadding = PaddingValues(bottom = 24.dp)
                        ) {
                            items(displayList, key = { it.id }) { p ->
                                val isLow = p.quantity <= 5.0
                                Card(
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                    shape = RoundedCornerShape(14.dp),
                                    border = CardDefaults.outlinedCardBorder()
                                ) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(14.dp)
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Column(modifier = Modifier.weight(1f)) {
                                                Text(
                                                    p.name,
                                                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                                                    color = MaterialTheme.colorScheme.onSurface
                                                )
                                                Spacer(modifier = Modifier.height(2.dp))
                                                Text(
                                                    text = "${p.category} • Cost: ₹${String.format("%.2f", p.costPrice ?: 0.0)} • Selling: ₹${String.format("%.2f", p.pricePerUnit)}",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
                                            }

                                            StockBadge(quantity = p.quantity, sellingType = p.sellingType)
                                        }

                                        Spacer(modifier = Modifier.height(10.dp))

                                        // Stock level meter bar
                                        val progress = (p.quantity / 50.0).coerceIn(0.05, 1.0).toFloat()
                                        LinearProgressIndicator(
                                            progress = { progress },
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .height(6.dp)
                                                .clip(RoundedCornerShape(3.dp)),
                                            color = if (isLow) Color(0xFFD97706) else MaterialTheme.colorScheme.primary,
                                            trackColor = MaterialTheme.colorScheme.surfaceVariant
                                        )

                                        Spacer(modifier = Modifier.height(6.dp))

                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text(
                                                text = "Stock: ${p.formattedQuantity ?: "${p.quantity} ${p.sellingType}"}",
                                                fontSize = 11.sp,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                            OutlinedButton(
                                                onClick = {
                                                    editingProduct = p
                                                    newQuantityInput = "${p.quantity}"
                                                },
                                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 2.dp),
                                                shape = RoundedCornerShape(8.dp),
                                                modifier = Modifier.height(30.dp)
                                            ) {
                                                Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(14.dp))
                                                Spacer(modifier = Modifier.width(4.dp))
                                                Text("Update Stock", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Quick Stock Adjustment Dialog
        editingProduct?.let { prod ->
            AlertDialog(
                onDismissRequest = { editingProduct = null },
                title = { Text("Update Stock Level", fontWeight = FontWeight.Bold) },
                text = {
                    Column {
                        Text(prod.name, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        Text("${prod.category} • Current: ${prod.formattedQuantity ?: "${prod.quantity} ${prod.sellingType}"}", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(modifier = Modifier.height(14.dp))
                        OutlinedTextField(
                            value = newQuantityInput,
                            onValueChange = { newQuantityInput = it },
                            label = { Text(if (prod.sellingType == "KG") "New Stock (kg)" else "New Stock (units)") },
                            singleLine = true,
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                },
                confirmButton = {
                    Button(
                        onClick = {
                            val newQty = newQuantityInput.toDoubleOrNull()
                            if (newQty != null && newQty >= 0) {
                                com.example.data.repository.ProductRepository.updateStock(prod.id, newQty)
                                loadInventory()
                            }
                            editingProduct = null
                        }
                    ) {
                        Text("Save Stock")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { editingProduct = null }) {
                        Text("Cancel")
                    }
                }
            )
        }
    }
}
