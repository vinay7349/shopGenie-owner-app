package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.example.data.repository.ProductRepository
import com.example.ui.components.MetricSummaryCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalesAnalyticsScreen(
    onNavigateBack: () -> Unit
) {
    var selectedPeriod by remember { mutableStateOf("TODAY") } // TODAY, WEEK, MONTH

    val products = ProductRepository.getAllProducts()
    val totalSKUs = products.size
    val totalInventoryValue = products.sumOf { it.pricePerUnit * it.quantity }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Sales & Retail Analytics", fontWeight = FontWeight.Bold)
                        Text(
                            "Live business intelligence report",
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
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Period Filter Chips
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    FilterChip(
                        selected = selectedPeriod == "TODAY",
                        onClick = { selectedPeriod = "TODAY" },
                        label = { Text("Today's Summary") },
                        shape = RoundedCornerShape(8.dp)
                    )
                    FilterChip(
                        selected = selectedPeriod == "WEEK",
                        onClick = { selectedPeriod = "WEEK" },
                        label = { Text("This Week") },
                        shape = RoundedCornerShape(8.dp)
                    )
                    FilterChip(
                        selected = selectedPeriod == "MONTH",
                        onClick = { selectedPeriod = "MONTH" },
                        label = { Text("This Month") },
                        shape = RoundedCornerShape(8.dp)
                    )
                }
            }

            // Key Revenue KPIs Grid
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        MetricSummaryCard(
                            title = "Gross Revenue",
                            value = "₹18,450",
                            icon = Icons.Default.CurrencyRupee,
                            iconTint = Color(0xFF006C4C),
                            iconBg = Color(0xFFD1FAE5),
                            trendText = "+14.2%",
                            modifier = Modifier.weight(1f)
                        )

                        MetricSummaryCard(
                            title = "Bills / Invoices",
                            value = "42 Orders",
                            icon = Icons.Default.ReceiptLong,
                            iconTint = Color(0xFF0284C7),
                            iconBg = Color(0xFFE0F2FE),
                            trendText = "Normal",
                            modifier = Modifier.weight(1f)
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        MetricSummaryCard(
                            title = "Avg Ticket Size",
                            value = "₹439.28",
                            icon = Icons.Default.ShoppingCart,
                            iconTint = Color(0xFFD97706),
                            iconBg = Color(0xFFFFE0B2),
                            trendText = "+5.8%",
                            modifier = Modifier.weight(1f)
                        )

                        MetricSummaryCard(
                            title = "Est. Gross Margin",
                            value = "18.5%",
                            icon = Icons.Default.TrendingUp,
                            iconTint = Color(0xFF7C3AED),
                            iconBg = Color(0xFFEDE9FE),
                            trendText = "Healthy",
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }

            // Payment Split Breakdown Card
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Payment Settlement Split",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                        Spacer(modifier = Modifier.height(14.dp))

                        PaymentSplitRow(title = "UPI / QR Code", amount = "₹11,800", percent = 64, color = Color(0xFF006C4C))
                        Spacer(modifier = Modifier.height(10.dp))
                        PaymentSplitRow(title = "Cash Tendered", amount = "₹5,400", percent = 29, color = Color(0xFFD97706))
                        Spacer(modifier = Modifier.height(10.dp))
                        PaymentSplitRow(title = "Debit / Credit Card", amount = "₹1,250", percent = 7, color = Color(0xFF0284C7))
                    }
                }
            }

            // Top Selling Products Breakdown
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Top Velocity Items",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Text(
                                text = "$totalSKUs Active SKUs",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        val topItems = listOf(
                            Triple("Aashirvaad Shudh Chakki Atta 5kg", "12 units sold", "₹3,000"),
                            Triple("Fortune Sunlite Sunflower Oil 1L", "18 units sold", "₹2,610"),
                            Triple("Premium Sugar (Loose)", "45.5 kg sold", "₹2,002"),
                            Triple("Moong Dal Whole", "16.0 kg sold", "₹1,920"),
                            Triple("Parle-G Gold Biscuits 250g", "40 units sold", "₹1,000")
                        )

                        topItems.forEachIndexed { idx, item ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Box(
                                        modifier = Modifier
                                            .size(28.dp)
                                            .clip(CircleShape)
                                            .background(MaterialTheme.colorScheme.surfaceVariant),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            "#${idx + 1}",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column {
                                        Text(item.first, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                        Text(item.second, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                                Text(item.third, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = MaterialTheme.colorScheme.primary)
                            }
                            if (idx < topItems.size - 1) {
                                HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PaymentSplitRow(title: String, amount: String, percent: Int, color: Color) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(title, fontSize = 13.sp, fontWeight = FontWeight.Medium)
            Text("$amount ($percent%)", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = color)
        }
        Spacer(modifier = Modifier.height(4.dp))
        LinearProgressIndicator(
            progress = { percent / 100f },
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp)),
            color = color,
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}
