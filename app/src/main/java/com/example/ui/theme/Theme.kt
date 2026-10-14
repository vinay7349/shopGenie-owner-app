package com.example.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColorScheme = lightColorScheme(
    primary = ShopGeniePrimary,
    onPrimary = ShopGenieOnPrimary,
    primaryContainer = ShopGeniePrimaryContainer,
    onPrimaryContainer = ShopGenieOnPrimaryContainer,
    secondary = ShopGenieSecondary,
    onSecondary = ShopGenieOnSecondary,
    secondaryContainer = ShopGenieSecondaryContainer,
    onSecondaryContainer = ShopGenieOnSecondaryContainer,
    tertiary = ShopGenieTertiary,
    onTertiary = ShopGenieOnTertiary,
    tertiaryContainer = ShopGenieTertiaryContainer,
    onTertiaryContainer = ShopGenieOnTertiaryContainer,
    background = ShopGenieBackground,
    onBackground = ShopGenieOnBackground,
    surface = ShopGenieSurface,
    onSurface = ShopGenieOnSurface,
    surfaceVariant = ShopGenieSurfaceVariant,
    onSurfaceVariant = ShopGenieOnSurfaceVariant,
    outline = ShopGenieOutline,
    outlineVariant = Color(0xFFE2E8E4),
    error = ShopGenieError,
    onError = Color.White,
    errorContainer = ShopGenieErrorContainer,
    onErrorContainer = Color(0xFF991B1B)
)

private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF8CF4C5),
    onPrimary = Color(0xFF003825),
    primaryContainer = Color(0xFF005238),
    onPrimaryContainer = Color(0xFFA6FAD1),
    secondary = Color(0xFFFFB951),
    onSecondary = Color(0xFF452B00),
    secondaryContainer = Color(0xFF633F00),
    onSecondaryContainer = Color(0xFFFFDDB3),
    tertiary = Color(0xFF6EE7B7),
    onTertiary = Color(0xFF003824),
    background = Color(0xFF0D1512),
    onBackground = Color(0xFFE5EDE8),
    surface = Color(0xFF14201B),
    onSurface = Color(0xFFE5EDE8),
    surfaceVariant = Color(0xFF1E2E28),
    onSurfaceVariant = Color(0xFFC0CDC6),
    outline = Color(0xFF2C3E36),
    error = Color(0xFFF87171),
    onError = Color(0xFF450A0A)
)

@Composable
fun MyApplicationTheme(
    darkTheme: Boolean = ThemeManager.isDarkThemeActive(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
