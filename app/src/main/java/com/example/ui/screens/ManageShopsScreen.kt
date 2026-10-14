package com.example.ui.screens

import androidx.compose.runtime.Composable
import com.example.data.repository.ShopItem

/**
 * Replaced under the Single-Shop Rule:
 * Ordinary owners have exactly one active shop. Multi-shop switching and creation are removed.
 * This composable delegates directly to MyShopScreen for backward compatibility.
 */
@Composable
fun ManageShopsScreen(
    onNavigateBack: () -> Unit,
    onNavigateShopSelected: (ShopItem) -> Unit = {}
) {
    MyShopScreen(
        onNavigateBack = onNavigateBack
    )
}
