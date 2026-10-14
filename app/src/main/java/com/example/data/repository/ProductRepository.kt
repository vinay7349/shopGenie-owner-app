package com.example.data.repository

import com.example.data.models.InvoiceDto
import com.example.data.models.InvoiceItemDto
import com.example.data.models.ProductCreateRequest
import com.example.data.models.ProductDto
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object ProductRepository {

    private val initialSampleProducts = listOf(
        ProductDto(
            id = 1,
            name = "Aashirvaad Shudh Chakki Atta 5kg",
            category = "Flour & Atta",
            sellingType = "UNIT",
            costPrice = 210.0,
            pricePerUnit = 250.0,
            quantity = 15.0,
            formattedQuantity = "15 units",
            isLoose = false
        ),
        ProductDto(
            id = 2,
            name = "Fortune Sunlite Sunflower Oil 1L",
            category = "Oils & Ghee",
            sellingType = "UNIT",
            costPrice = 125.0,
            pricePerUnit = 145.0,
            quantity = 24.0,
            formattedQuantity = "24 units",
            isLoose = false
        ),
        ProductDto(
            id = 3,
            name = "Premium Sugar (Loose)",
            category = "Groceries",
            sellingType = "KG",
            costPrice = 38.0,
            pricePerUnit = 44.0,
            quantity = 65.0,
            formattedQuantity = "65.000 kg",
            isLoose = true
        ),
        ProductDto(
            id = 4,
            name = "Moong Dal Whole",
            category = "Grains & Pulses",
            sellingType = "KG",
            costPrice = 98.0,
            pricePerUnit = 120.0,
            quantity = 32.0,
            formattedQuantity = "32.000 kg",
            isLoose = true
        ),
        ProductDto(
            id = 5,
            name = "Tata Salt Vacuum Evaporated 1kg",
            category = "Groceries",
            sellingType = "UNIT",
            costPrice = 22.0,
            pricePerUnit = 28.0,
            quantity = 4.0,
            formattedQuantity = "4 units",
            isLoose = false
        ),
        ProductDto(
            id = 6,
            name = "Turmeric Powder Haldi 100g",
            category = "Spices",
            sellingType = "UNIT",
            costPrice = 25.0,
            pricePerUnit = 35.0,
            quantity = 3.0,
            formattedQuantity = "3 units",
            isLoose = false
        ),
        ProductDto(
            id = 7,
            name = "Parle-G Gold Biscuits 250g",
            category = "Snacks",
            sellingType = "UNIT",
            costPrice = 20.0,
            pricePerUnit = 25.0,
            quantity = 50.0,
            formattedQuantity = "50 units",
            isLoose = false
        ),
        ProductDto(
            id = 8,
            name = "Basmati Rice Royal 1kg",
            category = "Grains & Pulses",
            sellingType = "KG",
            costPrice = 85.0,
            pricePerUnit = 110.0,
            quantity = 25.0,
            formattedQuantity = "25.000 kg",
            isLoose = true
        ),
        ProductDto(
            id = 9,
            name = "Toor Dal Yellow Desi",
            category = "Grains & Pulses",
            sellingType = "KG",
            costPrice = 130.0,
            pricePerUnit = 155.0,
            quantity = 18.0,
            formattedQuantity = "18.000 kg",
            isLoose = true
        ),
        ProductDto(
            id = 10,
            name = "Amul Butter Pasteurised 500g",
            category = "Dairy",
            sellingType = "UNIT",
            costPrice = 245.0,
            pricePerUnit = 275.0,
            quantity = 8.0,
            formattedQuantity = "8 units",
            isLoose = false
        )
    )

    private val _products = MutableStateFlow<List<ProductDto>>(initialSampleProducts)
    val productsFlow: StateFlow<List<ProductDto>> = _products.asStateFlow()

    private val _invoices = MutableStateFlow<Map<Int, InvoiceDto>>(emptyMap())
    private var nextInvoiceId = 101

    init {
        // Pre-seed an initial sample receipt
        val sampleInvoice = InvoiceDto(
            id = 101,
            status = "PAID",
            totalAmount = 439.0,
            createdAt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date()),
            items = listOf(
                InvoiceItemDto(id = 1, productName = "Aashirvaad Shudh Chakki Atta 5kg", quantity = 1.0, formattedQuantity = "1 unit", unitPrice = 250.0, totalPrice = 250.0),
                InvoiceItemDto(id = 2, productName = "Fortune Sunlite Sunflower Oil 1L", quantity = 1.0, formattedQuantity = "1 unit", unitPrice = 145.0, totalPrice = 145.0),
                InvoiceItemDto(id = 3, productName = "Premium Sugar (Loose)", quantity = 1.0, formattedQuantity = "1.000 kg", unitPrice = 44.0, totalPrice = 44.0)
            )
        )
        _invoices.value = mapOf(101 to sampleInvoice)
    }

    fun getAllProducts(): List<ProductDto> {
        return _products.value
    }

    fun getProductById(id: Int): ProductDto? {
        return _products.value.firstOrNull { it.id == id }
    }

    fun getLooseProducts(): List<ProductDto> {
        return _products.value.filter { it.isLoose || it.sellingType == "KG" }
    }

    fun addProduct(request: ProductCreateRequest): ProductDto {
        val nextId = (_products.value.maxOfOrNull { it.id } ?: 0) + 1
        val formatted = if (request.sellingType == "KG") {
            String.format("%.3f kg", request.quantity)
        } else {
            "${request.quantity.toInt()} units"
        }

        val newProduct = ProductDto(
            id = nextId,
            name = request.name,
            category = request.category,
            sellingType = request.sellingType,
            costPrice = request.costPrice,
            pricePerUnit = request.pricePerUnit,
            quantity = request.quantity,
            formattedQuantity = formatted,
            isLoose = request.isLoose
        )

        _products.value = listOf(newProduct) + _products.value
        return newProduct
    }

    fun updateStock(id: Int, newQuantity: Double): Boolean {
        val current = _products.value
        val index = current.indexOfFirst { it.id == id }
        if (index != -1) {
            val item = current[index]
            val formatted = if (item.sellingType == "KG") {
                String.format("%.3f kg", newQuantity)
            } else {
                "${newQuantity.toInt()} units"
            }
            val updated = item.copy(quantity = newQuantity, formattedQuantity = formatted)
            val newList = current.toMutableList()
            newList[index] = updated
            _products.value = newList
            return true
        }
        return false
    }

    fun deleteProduct(id: Int): Boolean {
        val current = _products.value
        val filtered = current.filterNot { it.id == id }
        if (filtered.size != current.size) {
            _products.value = filtered
            return true
        }
        return false
    }

    fun syncFromBackend(backendProducts: List<ProductDto>) {
        if (backendProducts.isNotEmpty()) {
            _products.value = backendProducts
        }
    }

    fun createInvoice(items: List<com.example.ui.cart.CartItem>, paymentMode: String): InvoiceDto {
        val id = nextInvoiceId++
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        val invoiceItems = items.mapIndexed { index, cartItem ->
            val formatted = if (cartItem.sellingType == "KG") {
                String.format("%.3f kg", cartItem.quantity)
            } else {
                "${cartItem.quantity.toInt()} units"
            }
            InvoiceItemDto(
                id = index + 1,
                productName = cartItem.name,
                quantity = cartItem.quantity,
                formattedQuantity = formatted,
                unitPrice = cartItem.unitPrice,
                totalPrice = cartItem.totalPrice
            )
        }

        val totalAmount = items.sumOf { it.totalPrice }
        val invoice = InvoiceDto(
            id = id,
            status = "PAID ($paymentMode)",
            totalAmount = totalAmount,
            createdAt = timestamp,
            items = invoiceItems
        )

        val updatedMap = _invoices.value.toMutableMap()
        updatedMap[id] = invoice
        _invoices.value = updatedMap

        // Deduct inventory quantities
        for (item in items) {
            val prod = getProductById(item.productId)
            if (prod != null) {
                val newQty = (prod.quantity - item.quantity).coerceAtLeast(0.0)
                updateStock(item.productId, newQty)
            }
        }

        return invoice
    }

    fun getInvoice(id: Int): InvoiceDto? {
        return _invoices.value[id] ?: _invoices.value.values.firstOrNull()
    }

    fun getInvoices(): List<InvoiceDto> {
        return _invoices.value.values.toList()
    }

    fun getTodayRevenue(): Double {
        return _invoices.value.values.sumOf { it.totalAmount }
    }
}
