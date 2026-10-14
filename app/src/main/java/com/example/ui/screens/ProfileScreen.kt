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
import com.example.data.models.UserDto
import com.example.ui.cart.CartManager
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    networkClient: NetworkClient,
    onNavigateBack: () -> Unit,
    onLogout: () -> Unit,
    onNavigateManageShops: () -> Unit = {},
    onNavigateMyShop: () -> Unit = onNavigateManageShops,
    onNavigateManageWorkers: () -> Unit = {},
    onNavigateDiscovery: () -> Unit = {},
    onNavigateVerification: () -> Unit = {},
    onNavigateSettings: () -> Unit = {},
    onNavigateOffers: () -> Unit = {}
) {
    val myShopState by com.example.data.repository.ShopManager.myShop.collectAsState()
    var user by remember { mutableStateOf<UserDto?>(null) }
    var serverUrl by remember { mutableStateOf(networkClient.baseUrl) }
    var esp32Url by remember { mutableStateOf(networkClient.esp32Url) }
    var isSavingSettings by remember { mutableStateOf(false) }
    var saveSuccessMessage by remember { mutableStateOf<String?>(null) }

    val currentThemeMode by com.example.ui.theme.ThemeManager.themeMode.collectAsState()
    val activeShop by com.example.data.repository.ShopManager.activeShop.collectAsState()

    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        try {
            val res = networkClient.apiService.getCurrentUser()
            if (res.isSuccessful && res.body() != null) {
                user = res.body()
            }
        } catch (_: Exception) {
            // User endpoint fallback
        }
    }

    fun saveConfig() {
        isSavingSettings = true
        networkClient.baseUrl = serverUrl
        networkClient.esp32Url = esp32Url
        isSavingSettings = false
        saveSuccessMessage = "Endpoint configuration saved!"
    }

    fun performLogout() {
        networkClient.clearSession()
        CartManager.clear()
        onLogout()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Store Settings & Profile", fontWeight = FontWeight.Bold) },
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
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // User & Store Identity Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(54.dp)
                            .clip(RoundedCornerShape(14.dp))
                            .background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Storefront,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = activeShop.name,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "Branch: ${activeShop.location}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "Merchant ID: @${user?.username ?: networkClient.currentUsername ?: "shopkeeper"}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            // Theme Mode Selector Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        text = "App Theme & Appearance",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )
                    Text(
                        text = "Select your preferred visual style across all screens and POS terminal interfaces.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        com.example.ui.theme.ThemeMode.values().forEach { mode ->
                            val isSelected = currentThemeMode == mode
                            val label = when (mode) {
                                com.example.ui.theme.ThemeMode.SYSTEM -> "System"
                                com.example.ui.theme.ThemeMode.LIGHT -> "Light"
                                com.example.ui.theme.ThemeMode.DARK -> "Dark"
                            }
                            val icon = when (mode) {
                                com.example.ui.theme.ThemeMode.SYSTEM -> Icons.Default.SettingsBrightness
                                com.example.ui.theme.ThemeMode.LIGHT -> Icons.Default.LightMode
                                com.example.ui.theme.ThemeMode.DARK -> Icons.Default.DarkMode
                            }

                            Button(
                                onClick = { com.example.ui.theme.ThemeManager.setThemeMode(mode) },
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(10.dp),
                                colors = if (isSelected) ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                                else ButtonDefaults.filledTonalButtonColors()
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(label, fontSize = 12.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                                }
                            }
                        }
                    }
                }
            }

            // Store Management Quick Shortcuts Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Store Configuration & Governance",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )

                    OutlinedButton(
                        onClick = onNavigateMyShop,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Store, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("My Shop (${activeShop.name})")
                    }

                    OutlinedButton(
                        onClick = onNavigateManageWorkers,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Groups, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Manage Shop Workers & Staff Access")
                    }

                    OutlinedButton(
                        onClick = onNavigateSettings,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Receipt, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("POS Tax, GST & Receipt Settings")
                    }

                    OutlinedButton(
                        onClick = onNavigateDiscovery,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Explore, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Discovery & Customer Visibility")
                    }

                    OutlinedButton(
                        onClick = onNavigateVerification,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.VerifiedUser, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Owner Identity Verification (${activeShop.verificationStatus})")
                    }

                    OutlinedButton(
                        onClick = onNavigateOffers,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Default.Loyalty, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Customer Loyalty & Promotional Codes")
                    }
                }
            }

            // Hardware & Network Configuration
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        text = "Hardware & API Connections",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )

                    Text(
                        text = "Configure your backend Django instance and external optical camera rig endpoints.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    OutlinedTextField(
                        value = serverUrl,
                        onValueChange = {
                            serverUrl = it
                            saveSuccessMessage = null
                        },
                        label = { Text("Django API Base URL") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )

                    OutlinedTextField(
                        value = esp32Url,
                        onValueChange = {
                            esp32Url = it
                            saveSuccessMessage = null
                        },
                        label = { Text("ESP32-CAM Stream URL") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )

                    if (saveSuccessMessage != null) {
                        Surface(
                            color = Color(0xFFD1FAE5),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = saveSuccessMessage!!,
                                color = Color(0xFF006C4C),
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.padding(10.dp)
                            )
                        }
                    }

                    Button(
                        onClick = { saveConfig() },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(Icons.Default.Save, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Save Configurations", fontWeight = FontWeight.SemiBold)
                    }
                }
            }

            // Session Logout Button
            OutlinedButton(
                onClick = { performLogout() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error)
            ) {
                Icon(Icons.Default.Logout, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Logout from ShopGenie", fontWeight = FontWeight.Bold)
            }
        }
    }
}
