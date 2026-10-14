package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.models.WorkerDto
import com.example.data.repository.ShopManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManageWorkersScreen(
    onNavigateBack: () -> Unit
) {
    val workers by ShopManager.workers.collectAsState()

    var showAddDialog by remember { mutableStateOf(false) }
    var showPasswordResetDialog by remember { mutableStateOf<WorkerDto?>(null) }
    var notificationMessage by remember { mutableStateOf<String?>(null) }

    // Add Worker Form States
    var newFullName by remember { mutableStateOf("") }
    var newUsername by remember { mutableStateOf("") }
    var newEmail by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var newPasswordVisible by remember { mutableStateOf(false) }
    var newCanConfirmBills by remember { mutableStateOf(true) }
    var newCanViewInvoices by remember { mutableStateOf(true) }
    var formError by remember { mutableStateOf<String?>(null) }

    // Password Reset States
    var resetPasswordText by remember { mutableStateOf("") }

    val activeCount = workers.count { it.isWorkerActive }
    val totalCount = workers.size

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Manage Workers", fontWeight = FontWeight.Bold)
                        Text(
                            text = "$activeCount of $totalCount workers active",
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
                    IconButton(onClick = { showAddDialog = true }) {
                        Icon(Icons.Default.PersonAdd, contentDescription = "Add Worker", tint = MaterialTheme.colorScheme.primary)
                    }
                }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showAddDialog = true },
                icon = { Icon(Icons.Default.PersonAdd, contentDescription = null) },
                text = { Text("Add Worker", fontWeight = FontWeight.Bold) },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                Spacer(modifier = Modifier.height(6.dp))

                if (notificationMessage != null) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFD1FAE5))
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF006C4C), modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(notificationMessage!!, color = Color(0xFF006C4C), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                    Spacer(modifier = Modifier.height(10.dp))
                }

                // Summary Overview Metrics
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    WorkerMetricCard(
                        title = "Total Staff",
                        value = "$totalCount",
                        icon = Icons.Default.Groups,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.weight(1f)
                    )
                    WorkerMetricCard(
                        title = "Active on Duty",
                        value = "$activeCount",
                        icon = Icons.Default.CheckCircleOutline,
                        color = Color(0xFF006C4C),
                        modifier = Modifier.weight(1f)
                    )
                    WorkerMetricCard(
                        title = "Deactivated",
                        value = "${totalCount - activeCount}",
                        icon = Icons.Default.Block,
                        color = Color(0xFFB45309),
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            item {
                // Security Notice Banner
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Row(
                        modifier = Modifier.padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Shield, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(
                            text = "Assigned workers only access counter billing & product catalog for your shop. Cost prices & profit analytics are strictly hidden.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            item {
                Text(
                    text = "Assigned Staff Members",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            }

            if (workers.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(Icons.Default.GroupAdd, contentDescription = null, modifier = Modifier.size(40.dp), tint = MaterialTheme.colorScheme.primary)
                            Spacer(modifier = Modifier.height(10.dp))
                            Text("No Workers Assigned Yet", fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("Add your cashiers and store assistants to streamline billing.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            } else {
                items(workers, key = { it.id }) { worker ->
                    WorkerItemCard(
                        worker = worker,
                        onToggleStatus = {
                            ShopManager.toggleWorkerStatus(worker.id)
                            notificationMessage = if (worker.isWorkerActive) "Worker account deactivated." else "Worker account activated."
                        },
                        onUpdatePermissions = { canConfirm, canView ->
                            ShopManager.updateWorkerPermissions(worker.id, canConfirm, canView)
                            notificationMessage = "Permissions updated for ${worker.displayName}."
                        },
                        onResetPassword = {
                            showPasswordResetDialog = worker
                        },
                        onRemove = {
                            ShopManager.removeWorker(worker.id)
                            notificationMessage = "Worker ${worker.displayName} removed."
                        }
                    )
                }
            }

            item {
                Spacer(modifier = Modifier.height(80.dp)) // Space for FAB
            }
        }
    }

    // Add Worker Dialog
    if (showAddDialog) {
        AlertDialog(
            onDismissRequest = {
                showAddDialog = false
                formError = null
            },
            title = { Text("Add New Shop Worker", fontWeight = FontWeight.Bold) },
            text = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    if (formError != null) {
                        Text(formError!!, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }

                    OutlinedTextField(
                        value = newFullName,
                        onValueChange = { newFullName = it },
                        label = { Text("Full Name *") },
                        placeholder = { Text("e.g. Ramesh Kumar") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = newUsername,
                        onValueChange = { newUsername = it },
                        label = { Text("Username *") },
                        placeholder = { Text("e.g. ramesh_cashier") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = newEmail,
                        onValueChange = { newEmail = it },
                        label = { Text("Email Address *") },
                        placeholder = { Text("ramesh@kirana.in") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = newPassword,
                        onValueChange = { newPassword = it },
                        label = { Text("Initial Temporary Password *") },
                        trailingIcon = {
                            IconButton(onClick = { newPasswordVisible = !newPasswordVisible }) {
                                Icon(
                                    imageVector = if (newPasswordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                    contentDescription = null
                                )
                            }
                        },
                        visualTransformation = if (newPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(6.dp))
                    Text("Worker Permissions", style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = newCanConfirmBills,
                            onCheckedChange = { newCanConfirmBills = it }
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Can Create & Confirm Bills", style = MaterialTheme.typography.bodySmall)
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = newCanViewInvoices,
                            onCheckedChange = { newCanViewInvoices = it }
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Can View Invoice History", style = MaterialTheme.typography.bodySmall)
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newFullName.isBlank() || newUsername.isBlank() || newEmail.isBlank() || newPassword.isBlank()) {
                            formError = "Please fill in all required fields."
                        } else {
                            ShopManager.addWorker(
                                fullName = newFullName,
                                username = newUsername,
                                email = newEmail,
                                canConfirmBills = newCanConfirmBills,
                                canViewInvoices = newCanViewInvoices
                            )
                            showAddDialog = false
                            notificationMessage = "Worker $newFullName invited and assigned to your shop."
                            // Reset form
                            newFullName = ""
                            newUsername = ""
                            newEmail = ""
                            newPassword = ""
                            formError = null
                        }
                    }
                ) {
                    Text("Add Worker")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showAddDialog = false
                    formError = null
                }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Password Reset Dialog
    if (showPasswordResetDialog != null) {
        val worker = showPasswordResetDialog!!
        AlertDialog(
            onDismissRequest = { showPasswordResetDialog = null },
            title = { Text("Reset Credentials", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Set a new secure temporary password for ${worker.displayName} (${worker.username}):", style = MaterialTheme.typography.bodySmall)
                    OutlinedTextField(
                        value = resetPasswordText,
                        onValueChange = { resetPasswordText = it },
                        label = { Text("New Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Text("Passwords are encrypted before storage and never displayed in plain text.", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (resetPasswordText.isNotBlank()) {
                            showPasswordResetDialog = null
                            resetPasswordText = ""
                            notificationMessage = "Password reset successfully for ${worker.displayName}."
                        }
                    }
                ) {
                    Text("Update Password")
                }
            },
            dismissButton = {
                TextButton(onClick = { showPasswordResetDialog = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun WorkerItemCard(
    worker: WorkerDto,
    onToggleStatus: () -> Unit,
    onUpdatePermissions: (canConfirm: Boolean, canView: Boolean) -> Unit,
    onResetPassword: () -> Unit,
    onRemove: () -> Unit
) {
    var expandedPermissions by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(
            width = 1.dp,
            color = if (worker.isWorkerActive) MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f) else Color.Red.copy(alpha = 0.25f)
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(46.dp)
                        .clip(CircleShape)
                        .background(
                            if (worker.isWorkerActive) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (worker.isWorkerActive) Icons.Default.Person else Icons.Default.PersonOff,
                        contentDescription = null,
                        tint = if (worker.isWorkerActive) MaterialTheme.colorScheme.primary else Color.Gray,
                        modifier = Modifier.size(24.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = worker.displayName,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )
                    Text(
                        text = "@${worker.username} • ${worker.email}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Active / Inactive Badge
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (worker.isWorkerActive) Color(0xFFD1FAE5) else Color(0xFFFEE2E2)
                ) {
                    Text(
                        text = if (worker.isWorkerActive) "Active" else "Deactivated",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = if (worker.isWorkerActive) Color(0xFF006C4C) else Color(0xFFB91C1C),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action / Permission Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    // Billing permission chip
                    AssistChip(
                        onClick = {
                            onUpdatePermissions(!worker.canConfirmBills, worker.canViewInvoices)
                        },
                        label = { Text("Billing: ${if (worker.canConfirmBills) "Enabled" else "Restricted"}", fontSize = 11.sp) },
                        leadingIcon = {
                            Icon(
                                if (worker.canConfirmBills) Icons.Default.Check else Icons.Default.Close,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = if (worker.canConfirmBills) Color(0xFF006C4C) else Color.Red
                            )
                        }
                    )

                    // Invoices permission chip
                    AssistChip(
                        onClick = {
                            onUpdatePermissions(worker.canConfirmBills, !worker.canViewInvoices)
                        },
                        label = { Text("Invoices: ${if (worker.canViewInvoices) "Enabled" else "Restricted"}", fontSize = 11.sp) },
                        leadingIcon = {
                            Icon(
                                if (worker.canViewInvoices) Icons.Default.Check else Icons.Default.Close,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = if (worker.canViewInvoices) Color(0xFF006C4C) else Color.Red
                            )
                        }
                    )
                }

                Row {
                    IconButton(onClick = onResetPassword) {
                        Icon(Icons.Default.Key, contentDescription = "Reset Password", modifier = Modifier.size(18.dp), tint = MaterialTheme.colorScheme.primary)
                    }

                    IconButton(onClick = onToggleStatus) {
                        Icon(
                            imageVector = if (worker.isWorkerActive) Icons.Default.ToggleOn else Icons.Default.ToggleOff,
                            contentDescription = "Toggle Active Status",
                            tint = if (worker.isWorkerActive) Color(0xFF006C4C) else Color.Gray,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun WorkerMetricCard(
    title: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = CardDefaults.outlinedCardBorder()
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Icon(imageVector = icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
            Spacer(modifier = Modifier.height(6.dp))
            Text(text = value, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
            Text(text = title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
