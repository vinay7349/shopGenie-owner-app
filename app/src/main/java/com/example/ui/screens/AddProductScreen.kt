package com.example.ui.screens

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.api.NetworkClient
import com.example.data.models.ProductCreateRequest
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddProductScreen(
    networkClient: NetworkClient,
    initialName: String? = null,
    initialIsLoose: Boolean = false,
    onNavigateBack: () -> Unit,
    onProductAdded: () -> Unit
) {
    var name by remember { mutableStateOf(initialName ?: "") }
    var category by remember { mutableStateOf("") }
    var sellingType by remember { mutableStateOf(if (initialIsLoose) "KG" else "UNIT") } // "UNIT" or "KG"
    var costPriceStr by remember { mutableStateOf("") }
    var sellingPriceStr by remember { mutableStateOf("") }
    var initialStockStr by remember { mutableStateOf("") }
    var isLoose by remember { mutableStateOf(initialIsLoose) }

    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val coroutineScope = rememberCoroutineScope()
    val commonCategories = listOf("Groceries", "Flour & Atta", "Grains & Pulses", "Spices", "Oils", "Snacks", "Beverages")

    fun submitProduct() {
        if (name.isBlank() || category.isBlank() || sellingPriceStr.isBlank()) {
            errorMessage = "Please enter product name, category, and selling price."
            return
        }

        val costPrice = costPriceStr.toDoubleOrNull() ?: 0.0
        val sellingPrice = sellingPriceStr.toDoubleOrNull()
        val initialStock = initialStockStr.toDoubleOrNull() ?: 0.0

        if (sellingPrice == null || sellingPrice <= 0.0) {
            errorMessage = "Please enter a valid positive selling price."
            return
        }

        isLoading = true
        errorMessage = null

        coroutineScope.launch {
            val req = ProductCreateRequest(
                name = name.trim(),
                category = category.trim(),
                sellingType = sellingType,
                costPrice = costPrice,
                pricePerUnit = sellingPrice,
                quantity = initialStock,
                isLoose = isLoose
            )

            // Persist to central repository immediately
            com.example.data.repository.ProductRepository.addProduct(req)

            // Sync with backend asynchronously
            try {
                networkClient.apiService.registerProduct(req)
            } catch (_: Exception) {
                // Keep local item saved if offline
            }

            isLoading = false
            onProductAdded()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Catalog Item", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        bottomBar = {
            Surface(
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 6.dp,
                shadowElevation = 8.dp
            ) {
                Button(
                    onClick = { submitProduct() },
                    enabled = !isLoading,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .height(52.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                    } else {
                        Icon(Icons.Default.Save, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Save & Add to Catalog", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(4.dp))

            if (errorMessage != null) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
                ) {
                    Text(
                        text = errorMessage!!,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(14.dp),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            // Selling Mode Selector Cards
            Column {
                Text("Product Selling Type", style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold))
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    FilterChip(
                        selected = sellingType == "UNIT",
                        onClick = {
                            sellingType = "UNIT"
                            isLoose = false
                        },
                        label = { Text("Packaged Unit (Box / Pkt)") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp)
                    )
                    FilterChip(
                        selected = sellingType == "KG",
                        onClick = {
                            sellingType = "KG"
                            isLoose = true
                        },
                        label = { Text("By Weight (Kg)") },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp)
                    )
                }
            }

            // Product Name
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Product Name *") },
                placeholder = { Text("e.g. Aashirvaad Atta 5kg") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                leadingIcon = { Icon(Icons.Default.Label, contentDescription = null) }
            )

            // Category with suggestion chips
            Column {
                OutlinedTextField(
                    value = category,
                    onValueChange = { category = it },
                    label = { Text("Category *") },
                    placeholder = { Text("e.g. Grains, Flour, Spices") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    leadingIcon = { Icon(Icons.Default.Category, contentDescription = null) }
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    commonCategories.forEach { cat ->
                        SuggestionChip(
                            onClick = { category = cat },
                            label = { Text(cat, fontSize = 11.sp) }
                        )
                    }
                }
            }

            // Pricing Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = costPriceStr,
                    onValueChange = { costPriceStr = it },
                    label = { Text("Cost Price") },
                    prefix = { Text("₹ ") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(12.dp)
                )

                OutlinedTextField(
                    value = sellingPriceStr,
                    onValueChange = { sellingPriceStr = it },
                    label = { Text("Selling Price *") },
                    prefix = { Text("₹ ") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(12.dp)
                )
            }

            // Initial Stock
            OutlinedTextField(
                value = initialStockStr,
                onValueChange = { initialStockStr = it },
                label = { Text("Initial Stock Quantity") },
                suffix = { Text(if (sellingType == "KG") "kg" else "units") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                shape = RoundedCornerShape(12.dp),
                leadingIcon = { Icon(Icons.Default.Inventory2, contentDescription = null) }
            )

            // Loose Plain Bag toggle (if applicable)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Loose Commodity / Plain Bag", fontWeight = FontWeight.SemiBold)
                    Text("Item is stored in unbranded transparent bags or jars", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Switch(checked = isLoose, onCheckedChange = { isLoose = it })
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
