package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.cart.CartManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeightInputScreen(
    productId: Int,
    productName: String,
    pricePerKg: Double,
    onNavigateBack: () -> Unit,
    onWeightConfirmed: () -> Unit
) {
    var weightInput by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val parsedWeight = weightInput.toDoubleOrNull() ?: 0.0
    val calculatedPrice = parsedWeight * pricePerKg

    fun addPreset(weight: Double) {
        val current = weightInput.toDoubleOrNull() ?: 0.0
        val updated = current + weight
        weightInput = String.format("%.3f", updated)
        errorMessage = null
    }

    fun confirmWeight() {
        if (parsedWeight <= 0.0) {
            errorMessage = "Please enter a valid positive weight in kilograms."
            return
        }

        CartManager.addItemDirect(
            productId = productId,
            name = productName,
            category = "Loose",
            sellingType = "KG",
            pricePerUnit = pricePerKg,
            quantity = parsedWeight,
            isLoose = true
        )
        onWeightConfirmed()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Smart Scale Weighing", fontWeight = FontWeight.Bold) },
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
                tonalElevation = 8.dp,
                shadowElevation = 12.dp
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Button(
                        onClick = { confirmWeight() },
                        enabled = parsedWeight > 0.0,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(Icons.Default.AddShoppingCart, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (parsedWeight > 0.0)
                                "Add to Bill • ₹${String.format("%.2f", calculatedPrice)}"
                            else
                                "Enter Weight to Proceed",
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp
                        )
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Product Information Banner
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                shape = RoundedCornerShape(16.dp),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFFFFE0B2)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.Scale, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(24.dp))
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = productName,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "Rate: ₹${String.format("%.2f", pricePerKg)} / kg",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            if (errorMessage != null) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
                ) {
                    Text(
                        text = errorMessage!!,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(12.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            // Electronic Scale Readout Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF0F241C)),
                shape = RoundedCornerShape(20.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "DIGITAL SCALE READOUT",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF8CF4C5)
                        )

                        Surface(
                            color = Color(0xFF1B3D30),
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = "STABLE • TARE 0.00",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF8CF4C5),
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Text(
                        text = if (parsedWeight > 0.0) String.format("%.3f", parsedWeight) else "0.000",
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF8CF4C5),
                        fontFamily = FontFamily.Monospace
                    )

                    Text(
                        text = "KILOGRAMS (KG)",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF8CF4C5).copy(alpha = 0.7f)
                    )

                    Spacer(modifier = Modifier.height(16.dp))
                    Divider(color = Color(0xFF1B3D30), thickness = 1.dp)
                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Calculated Price:",
                            color = Color.White.copy(alpha = 0.85f),
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            text = "₹${String.format("%.2f", calculatedPrice)}",
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFFFFDDB3)
                        )
                    }
                }
            }

            // Manual Weight Input Field
            OutlinedTextField(
                value = weightInput,
                onValueChange = {
                    weightInput = it
                    errorMessage = null
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Enter Weight Manually (e.g. 1.250)") },
                suffix = { Text("kg", fontWeight = FontWeight.Bold) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                shape = RoundedCornerShape(14.dp),
                trailingIcon = {
                    if (weightInput.isNotEmpty()) {
                        IconButton(onClick = { weightInput = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear")
                        }
                    }
                }
            )

            // Quick Preset Buttons Row
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Quick Weight Presets",
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.onBackground
                )
                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    SuggestionChip(
                        onClick = { addPreset(0.250) },
                        label = { Text("+250g") },
                        modifier = Modifier.weight(1f)
                    )
                    SuggestionChip(
                        onClick = { addPreset(0.500) },
                        label = { Text("+500g") },
                        modifier = Modifier.weight(1f)
                    )
                    SuggestionChip(
                        onClick = { addPreset(1.000) },
                        label = { Text("+1 kg") },
                        modifier = Modifier.weight(1f)
                    )
                    SuggestionChip(
                        onClick = { addPreset(2.000) },
                        label = { Text("+2 kg") },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}
