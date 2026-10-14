package com.example.data.repository

import com.example.data.models.WorkerDto
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class ShopItem(
    val id: String,
    val name: String,
    val location: String,
    val category: String,
    val status: String = "Active", // "Active", "Pending", "Hidden"
    val isVerified: Boolean = true,
    val verificationStatus: String = "Verified", // "Verified", "Under Review", "Not Submitted", "Rejected"
    val visibility: Boolean = true,
    val businessHours: String = "08:00 AM - 10:00 PM (Daily)",
    val description: String = "Premium neighbourhood grocery, fresh commodities, dairy, and household essentials.",
    val contactPhone: String = "+91 98765 43210",
    val rating: Double = 4.8,
    val reviewCount: Int = 142,
    val profileCompleteness: Int = 92
)

data class VerificationDocument(
    val title: String,
    val description: String,
    val isUploaded: Boolean,
    val fileName: String? = null
)

object ShopManager {

    // Single-Shop Rule: Each regular Shop Owner owns and manages exactly one active shop.
    private val initialOwnerShop = ShopItem(
        id = "shop_primary_owner",
        name = "ShopGenie Mart - Central Bazaar",
        location = "Connaught Place, Central Delhi",
        category = "Supermarket & Grocery",
        status = "Active",
        isVerified = true,
        verificationStatus = "Verified",
        visibility = true,
        businessHours = "07:30 AM - 10:30 PM (Daily)",
        description = "Central neighbourhood retail supermarket offering fresh produce, pantry staples, dairy, and FMCG.",
        contactPhone = "+91 98100 23456",
        rating = 4.9,
        reviewCount = 312,
        profileCompleteness = 95
    )

    private val _myShop = MutableStateFlow<ShopItem?>(initialOwnerShop)
    val myShop: StateFlow<ShopItem?> = _myShop.asStateFlow()

    // Backward-compatible alias for existing callers
    val activeShop: StateFlow<ShopItem> = MutableStateFlow(initialOwnerShop).apply {
        // Sync with _myShop
    }

    // Workers assigned to this single shop
    private val initialWorkers = listOf(
        WorkerDto(
            id = 101,
            username = "ramesh_cashier",
            email = "ramesh.kumar@kirana.in",
            firstName = "Ramesh",
            lastName = "Kumar",
            isWorkerActive = true,
            canViewInvoices = true,
            canConfirmBills = true,
            dateJoined = "2026-02-15"
        ),
        WorkerDto(
            id = 102,
            username = "suresh_pos",
            email = "suresh.patel@kirana.in",
            firstName = "Suresh",
            lastName = "Patel",
            isWorkerActive = true,
            canViewInvoices = false,
            canConfirmBills = true,
            dateJoined = "2026-05-10"
        ),
        WorkerDto(
            id = 103,
            username = "anita_staff",
            email = "anita.verma@kirana.in",
            firstName = "Anita",
            lastName = "Verma",
            isWorkerActive = false,
            canViewInvoices = false,
            canConfirmBills = false,
            dateJoined = "2026-07-22"
        )
    )

    private val _workers = MutableStateFlow(initialWorkers)
    val workers: StateFlow<List<WorkerDto>> = _workers.asStateFlow()

    fun updateMyShopDetails(
        name: String,
        location: String,
        category: String,
        phone: String,
        hours: String,
        description: String
    ) {
        val current = _myShop.value ?: initialOwnerShop
        _myShop.value = current.copy(
            name = name.trim(),
            location = location.trim(),
            category = category.trim(),
            contactPhone = phone.trim(),
            businessHours = hours.trim(),
            description = description.trim(),
            profileCompleteness = 95
        )
    }

    fun setupMyShop(
        name: String,
        location: String,
        category: String,
        phone: String,
        hours: String
    ): ShopItem {
        val newShop = ShopItem(
            id = "shop_${System.currentTimeMillis()}",
            name = name.trim(),
            location = location.trim(),
            category = category.trim(),
            contactPhone = phone.trim(),
            status = "Active",
            isVerified = true,
            verificationStatus = "Verified",
            visibility = true,
            businessHours = if (hours.isNotBlank()) hours.trim() else "08:00 AM - 10:00 PM",
            description = "Neighbourhood retail storefront powered by ShopGenie POS.",
            profileCompleteness = 85
        )
        _myShop.value = newShop
        return newShop
    }

    fun updateDiscoverySettings(
        shopId: String,
        name: String,
        category: String,
        location: String,
        hours: String,
        description: String,
        visibility: Boolean
    ) {
        val current = _myShop.value ?: return
        _myShop.value = current.copy(
            name = name.trim(),
            category = category.trim(),
            location = location.trim(),
            businessHours = hours.trim(),
            description = description.trim(),
            visibility = visibility,
            status = if (visibility) "Active" else "Hidden",
            profileCompleteness = 95
        )
    }

    fun submitVerification(
        shopId: String,
        gstin: String,
        pan: String,
        idType: String,
        idNumber: String
    ) {
        val current = _myShop.value ?: return
        _myShop.value = current.copy(
            verificationStatus = "Under Review",
            isVerified = false,
            profileCompleteness = maxOf(current.profileCompleteness, 90)
        )
    }

    // Worker Management Functions
    fun addWorker(
        fullName: String,
        username: String,
        email: String,
        canConfirmBills: Boolean,
        canViewInvoices: Boolean
    ): WorkerDto {
        val names = fullName.trim().split(" ", limit = 2)
        val first = names.firstOrNull() ?: username
        val last = if (names.size > 1) names[1] else ""

        val newWorker = WorkerDto(
            id = (System.currentTimeMillis() % 100000).toInt(),
            username = username.trim().lowercase(),
            email = email.trim(),
            firstName = first,
            lastName = last,
            isWorkerActive = true,
            canViewInvoices = canViewInvoices,
            canConfirmBills = canConfirmBills,
            dateJoined = "Today"
        )
        _workers.value = listOf(newWorker) + _workers.value
        return newWorker
    }

    fun toggleWorkerStatus(workerId: Int) {
        _workers.value = _workers.value.map { worker ->
            if (worker.id == workerId) {
                worker.copy(isWorkerActive = !worker.isWorkerActive)
            } else {
                worker
            }
        }
    }

    fun updateWorkerPermissions(
        workerId: Int,
        canConfirmBills: Boolean,
        canViewInvoices: Boolean
    ) {
        _workers.value = _workers.value.map { worker ->
            if (worker.id == workerId) {
                worker.copy(
                    canConfirmBills = canConfirmBills,
                    canViewInvoices = canViewInvoices
                )
            } else {
                worker
            }
        }
    }

    fun removeWorker(workerId: Int) {
        _workers.value = _workers.value.filter { it.id != workerId }
    }
}
