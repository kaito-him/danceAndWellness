# Gold and White Theme Guide

## Overview
The mobile app now uses a luxurious **Gold and White** color scheme throughout the entire application.

## Color Palette

### Primary Colors
- **Primary Gold**: `#D4AF37` - Classic gold used for primary actions and highlights
- **Light Gold**: `#FFD700` - Bright gold for accents and warnings
- **Dark Gold**: `#B8860B` - Dark goldenrod for depth and contrast
- **Pale Gold**: `#FFF8DC` - Very light gold (cornsilk) for subtle backgrounds

### Neutral Colors
- **Pure White**: `#FFFFFF` - Main background color
- **Off White**: `#FAFAFA` - Scaffold background
- **Light Gray**: `#F5F5F5` - Subtle backgrounds
- **Medium Gray**: `#E0E0E0` - Borders and dividers

### Semantic Colors
- **Success Gold**: `#DAA520` - Goldenrod for success messages
- **Error Gold**: `#CD853F` - Peru (muted gold) for error messages
- **Warning Gold**: `#FFD700` - Gold for warning messages

### Text Colors
- **Text Primary**: `#2C2C2C` - Dark gray for main text
- **Text Secondary**: `#757575` - Medium gray for secondary text
- **Text on Gold**: `#FFFFFF` - White text on gold backgrounds
- **Text on White**: `#2C2C2C` - Dark text on white backgrounds

## Theme Components

### Buttons
- **Elevated Buttons**: Gold background with white text
- **Outlined Buttons**: Gold border with gold text
- **Text Buttons**: Gold text

### Input Fields
- **Background**: Pure white
- **Border**: Medium gray (default), Primary gold (focused)
- **Error Border**: Error gold

### Cards
- **Background**: Pure white
- **Border**: Pale gold
- **Shadow**: Gold with 20% opacity

### AppBar
- **Background**: Primary gold
- **Text/Icons**: Pure white

### Snackbars
- **Default**: Dark gold background with white text
- **Success**: Success gold background
- **Error**: Error gold background
- **Warning**: Warning gold background

### Progress Indicators
- **Active**: Primary gold
- **Track**: Pale gold

## Usage

### Importing the Theme
```dart
import 'utils/app_theme.dart';
```

### Applying the Theme
The theme is automatically applied in `main.dart`:
```dart
MaterialApp.router(
  theme: AppTheme.lightTheme,
  // ...
)
```

### Using Theme Colors in Code
```dart
// Use theme colors
Container(
  color: Theme.of(context).colorScheme.primary, // Primary gold
)

// Or use AppTheme directly
Container(
  color: AppTheme.primaryGold,
)
```

### Custom Snackbars
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success message'),
    backgroundColor: AppTheme.successGold,
  ),
);
```

## Files Modified

### Core Theme Files
- ✅ `lib/utils/app_theme.dart` - New theme configuration file
- ✅ `lib/main.dart` - Updated to use AppTheme

### Screen Files Updated
- ✅ `lib/screens/login_screen.dart`
- ✅ `lib/screens/student_registration_screen.dart`
- ✅ `lib/screens/instructor_application_screen.dart`

### Automatic Theme Application
The following components automatically use the gold and white theme:
- All buttons (Elevated, Outlined, Text)
- All input fields
- All cards
- AppBar
- Bottom navigation
- Progress indicators
- Dialogs
- Chips
- Dividers

## Design Philosophy

The gold and white theme creates:
- **Elegance**: Gold conveys luxury and premium quality
- **Clarity**: White backgrounds ensure excellent readability
- **Consistency**: All components follow the same color scheme
- **Accessibility**: High contrast between text and backgrounds
- **Professional**: Suitable for a dance and wellness platform

## Notes

- The theme uses Material 3 design principles
- All colors are carefully chosen for accessibility
- Error and warning colors are gold-tinted to maintain theme consistency
- Gray colors are used sparingly for text and subtle UI elements
