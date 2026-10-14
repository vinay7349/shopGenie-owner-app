package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import com.example.ui.components.ErrorBanner
import com.example.ui.components.LoadingStateIndicator
import com.example.ui.components.SellingBadge
import com.example.ui.components.StockBadge
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductDetailScreen(
    productId: Int,
    networkClient: NetworkClient,
    onNavigateBack: () -> Unit,
    onNavigateWeightInput: (productId: Int, productName: String, pricePerKg: Double) -> Unit
) {
    var product by remember { mutableStateOf<ProductDto?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    val coroutineScope = rememberCoroutineScope()

    fun loadDetail() {
        isLoading = true
        errorMessage = null
        coroutineScope.launch {
            try {
                val res = networkClient.apiService.getProductDetail(productId)
                if (res.isSuccessful && res.body() != null) {
                    product = res.body()
                    isLoading = false
                    return@launch
                }
            } catch (_: Exception) {
                // Fallback to local catalog
            }

            product = com.example.data.repository.ProductRepository.getProductById(productId)
            if (product != null) {
                isLoading = false
            } else {
                isLoading = false
                errorMessage = "Product with ID #$productId not found in store catalog."
            }
        }
    }

    fun deleteProduct() {
        coroutineScope.launch {
            com.example.data.repository.ProductRepository.deleteProduct(productId)
            try {
                networkClient.apiService.deleteProduct(productId)
            } catch (_: Exception) {}
            onNavigateBack()
        }
    }

    LaunchedEffect(productId) {
        loadDetail()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(product?.name ?: "Product Overview", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (networkClient.isOwner) {
                        IconButton(onClick = { showDeleteConfirm = true }) {
                            Icon(Icons.Default.DeleteOutline, contentDescription = "Delete Product", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }
            )
        },
        bottomBar = {
            if (product != null) {
                val p = product!!
                Surface(
                    color = MaterialTheme.colorScheme.surface,
                    tonalElevation = 6.dp,
                    shadowElevation = 8.dp
                ) {
                    Button(
                        onClick = {
                            if (p.sellingType == "KG") {
                                onNavigateWeightInput(p.id, p.name, p.pricePerUnit)
                            } else {
                                CartManager.addItem(p, 1.0)
                                onNavigateBack()
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                            .height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(Icons.Default.AddShoppingCart, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Add to Billing Cart", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    }
                }
            }
        }
    ) { padding ->
        if (showDeleteConfirm) {
            AlertDialog(
                onDismissRequest = { showDeleteConfirm = false },
                title = { Text("Delete Product") },
                text = { Text("Are you sure you want to remove '${product?.name}' from your store catalog?") },
                confirmButton = {
                    Button(
                        onClick = {
                            showDeleteConfirm = false
                            deleteProduct()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                    ) {
                        Text("Delete")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteConfirm = false }) {
                        Text("Cancel")
                    }
                }
            )
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when {
                isLoading -> LoadingStateIndicator(message = "Loading product information...")
                errorMessage != null -> ErrorBanner(errorMessage = errorMessage!!, onRetry = { loadDetail() })
                product != null -> {
                    val p = product!!
                    val profitMargin = if (p.costPrice != null && p.costPrice > 0) {
                        ((p.pricePerUnit - p.costPrice) / p.costPrice) * 100
                    } else null

                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp)
                            .verticalScroll(rememberScrollState()),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Header Card
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(18.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            border = CardDefaults.outlinedCardBorder()
                        ) {
                            Column(modifier = Modifier.padding(20.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Surface(
                                            color = MaterialTheme.colorScheme.surfaceVariant,
                                            shape = RoundedCornerShape(6.dp)
                                        ) {
                                            Text(
                                                text = p.category.uppercase(),
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                                            )
                                        }

                                        SellingBadge(sellingType = p.sellingType, isLoose = p.isLoose)
                                    }

                                    StockBadge(quantity = p.quantity, sellingType = p.sellingType)
                                }

                                Spacer(modifier = Modifier.height(12.dp))

                                Text(
                                    text = p.name,
                                    style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold)
                                )

                                Spacer(modifier = Modifier.height(14.dp))

                                Row(
                                    verticalAlignment = Alignment.Bottom,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Text(
                                        text = "₹${String.format("%.2f", p.pricePerUnit)}",
                                        style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.ExtraBold),
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = " / ${p.sellingType.lowercase()}",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        // Financial & Inventory Card
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            border = CardDefaults.outlinedCardBorder()
                        ) {
                            Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text("Cost & Margin Details", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 0.8.dp)

                                if (networkClient.isOwner) {
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                        Text("Wholesale Cost Price", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Text("₹${String.format("%.2f", p.costPrice ?: 0.0)} / ${p.sellingType}", fontWeight = FontWeight.SemiBold)
                                    }
                                }

                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("Retail Selling Price", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text("₹${String.format("%.2f", p.pricePerUnit)} / ${p.sellingType}", fontWeight = FontWeight.Bold)
                                }

                                if (networkClient.isOwner && profitMargin != null) {
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                        Text("Estimated Margin", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                        Text(
                                            "${String.format("%.1f", profitMargin)}%",
                                            color = Color(0xFF006C4C),
                                            fontWeight = FontWeight.Bold
                                        )
                                    }
                                }

                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("Current Stock", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text(
                                        text = p.formattedQuantity ?: "${p.quantity} ${p.sellingType}",
                                        fontWeight = FontWeight.Bold,
                                        color = if (p.quantity <= 5) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                                    )
                                }

                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("AI Vision Embedding", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text(
                                        text = if (p.featureVector != null) "Trained (${p.featureVector.size}d)" else "Not Enrolled",
                                        color = if (p.featureVector != null) Color(0xFF006C4C) else MaterialTheme.colorScheme.onSurfaceVariant,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(24.dp))
                    }
                }
            }
        }
    }
}
