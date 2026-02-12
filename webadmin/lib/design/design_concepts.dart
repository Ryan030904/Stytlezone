/// Design Concepts for Fashion Admin Dashboard
/// 
/// Concept 1: Modern SaaS / Corporate Design
/// - Professional, trustworthy, clean
/// - Suitable for business admin interfaces
/// 
/// Concept 2: Premium Fashion Design
/// - Luxurious, high-end aesthetic
/// - Aligned with fashion brand identity
/// 
/// Concept 3: Glassmorphism (Frosted Glass Effect)
/// - Modern, sophisticated with depth
/// - Contemporary and trendy appearance

import 'package:flutter/material.dart';

class DesignConcept {
  final String name;
  final String description;
  final Map<String, Color> colors;
  final Map<String, dynamic> shadows;
  final Map<String, dynamic> typography;

  DesignConcept({
    required this.name,
    required this.description,
    required this.colors,
    required this.shadows,
    required this.typography,
  });
}

/// CONCEPT 1: Modern SaaS / Corporate Design
class Concept1SaaS {
  // Color Palette
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color accentPurple = Color(0xFFEC4899);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFFE5E7EB);
  static const Color darkGray = Color(0xFF374151);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFFAFAFA);

  // Shadow Specifications
  // Soft shadow: blur 15-20px, opacity 0.08-0.12
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x00000014), // opacity: 0.08
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x0000001F), // opacity: 0.12
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // Typography
  static const Map<String, dynamic> typography = {
    'headingLarge': {'size': 32.0, 'weight': 700}, // Bold
    'headingMedium': {'size': 24.0, 'weight': 600}, // SemiBold
    'bodyLarge': {'size': 16.0, 'weight': 500}, // Medium
    'bodyMedium': {'size': 14.0, 'weight': 400}, // Regular
    'bodySmall': {'size': 12.0, 'weight': 400}, // Regular
    'fontFamily': 'Inter', // or Manrope
  };

  // Design Description
  static const String description = '''
  Modern SaaS / Corporate Design
  
  Background: Light gray (#FAFAFA) with subtle geometric patterns
  Cards: Solid white with refined soft shadows (blur: 16px, opacity: 0.08-0.12)
  Typography: Inter font family for professional appearance
  Color Palette: Purple (#7C3AED) + neutral grays
  Visual Effect: Professional, trustworthy, high readability
  Key Characteristics: Clean, minimalist, business-focused
  
  Accessibility:
  - Text contrast ratio: 7:1 (AAA standard)
  - Font sizes: 14px minimum for body text
  - Clear visual hierarchy
  - High readability on all devices
  ''';
}

/// CONCEPT 2: Premium Fashion Design
class Concept2PremiumFashion {
  // Color Palette
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFFCBD5E1);
  static const Color borderBright = Color(0xFF64748B);

  // Gradient Overlay
  // Deep charcoal base with subtle purple-to-pink gradient (opacity: 0.05-0.08)
  static const List<Color> gradientColors = [
    Color(0xFF1A1A1A),
    Color(0xFF2D1B4E), // Subtle purple tint
    Color(0xFF3D1F3F), // Subtle pink tint
  ];

  // Shadow Specifications
  // Dark cards with thin bright borders (1px)
  static const BoxShadow premiumShadow = BoxShadow(
    color: Color(0x00000033), // opacity: 0.2
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  // Typography - Larger, spacious for premium feel
  static const Map<String, dynamic> typography = {
    'headingLarge': {'size': 40.0, 'weight': 700}, // Bold
    'headingMedium': {'size': 28.0, 'weight': 600}, // SemiBold
    'bodyLarge': {'size': 18.0, 'weight': 500}, // Medium
    'bodyMedium': {'size': 16.0, 'weight': 400}, // Regular
    'bodySmall': {'size': 14.0, 'weight': 400}, // Regular
    'fontFamily': 'Poppins', // Premium font
    'letterSpacing': 0.5, // Spacious feel
  };

  // Design Description
  static const String description = '''
  Premium Fashion Design
  
  Background: Deep charcoal (#1A1A1A) with subtle purple-to-pink gradient overlay
  Cards: Dark cards with thin bright borders (1px, #64748B)
  Visual Elements: Fashion-themed abstract illustration or blurred dashboard mockup
  Typography: Large, spacious font sizing (40px headings)
  Color Palette: Deep tones with purple/pink accents + gold highlights
  Visual Effect: Luxurious, high-end aesthetic
  Key Characteristics: Generous spacing, premium typography, fashion-aligned
  
  Accessibility:
  - Text contrast ratio: 7:1 (AAA standard)
  - Large font sizes for readability
  - Sufficient spacing between elements
  - High contrast borders for visual separation
  ''';
}

/// CONCEPT 3: Glassmorphism (Frosted Glass Effect)
class Concept3Glassmorphism {
  // Color Palette
  static const Color darkBase = Color(0xFF0F172A);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderBright = Color(0xFF475569);

  // Gradient Background - Multi-layered with depth
  static const List<Color> gradientColors = [
    Color(0xFF0F172A), // Dark base
    Color(0xFF1E293B), // Slightly lighter
    Color(0xFF334155), // Subtle color transition
  ];

  // Glassmorphism Effect
  // Frosted glass: backdrop blur, semi-transparent (opacity: 0.12-0.18)
  static const double glassOpacity = 0.15; // 15% opacity
  static const double backdropBlur = 10.0; // Backdrop blur effect
  static const double borderOpacity = 0.2; // Border opacity

  // Shadow Specifications
  static const BoxShadow glassShadow = BoxShadow(
    color: Color(0x00000033), // opacity: 0.2
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // Typography - High contrast for readability
  static const Map<String, dynamic> typography = {
    'headingLarge': {'size': 36.0, 'weight': 700}, // Bold
    'headingMedium': {'size': 24.0, 'weight': 600}, // SemiBold
    'bodyLarge': {'size': 16.0, 'weight': 500}, // Medium
    'bodyMedium': {'size': 14.0, 'weight': 400}, // Regular
    'bodySmall': {'size': 12.0, 'weight': 400}, // Regular
    'fontFamily': 'Poppins',
  };

  // Design Description
  static const String description = '''
  Glassmorphism (Frosted Glass Effect)
  
  Background: Multi-layered gradient with depth (#0F172A to #334155)
  Cards: Frosted glass effect with backdrop blur (10px)
  Transparency: Semi-transparent (opacity: 15%), thin bright borders (1px)
  Typography: High contrast text (WCAG AA minimum)
  Color Palette: Transparent layers with purple accents
  Visual Effect: Modern, sophisticated with depth perception
  Key Characteristics: Contemporary, trendy, depth-focused
  
  Accessibility (CRITICAL):
  - Text contrast ratio: 7:1 (AAA standard)
  - Minimum font size: 14px
  - Ensure sufficient contrast between text and glass background
  - Test on various backgrounds for readability
  - Use semi-transparent overlays to improve text contrast
  ''';
}

/// Design Specifications Summary
class DesignSpecifications {
  static const Map<String, dynamic> concept1 = {
    'name': 'Modern SaaS / Corporate Design',
    'bgColor': '#FAFAFA',
    'cardColor': '#FFFFFF',
    'shadowBlur': 16,
    'shadowOpacity': 0.08,
    'primaryColor': '#7C3AED',
    'fontFamily': 'Inter',
    'responsive': {
      'mobile': 'Single column, full width',
      'tablet': 'Two columns with padding',
      'desktop': 'Two-column layout with sidebar',
    },
  };

  static const Map<String, dynamic> concept2 = {
    'name': 'Premium Fashion Design',
    'bgColor': '#1A1A1A',
    'cardColor': '#2D2D2D',
    'borderColor': '#64748B',
    'borderWidth': 1,
    'shadowBlur': 24,
    'shadowOpacity': 0.2,
    'primaryColor': '#7C3AED',
    'accentColor': '#EC4899',
    'fontFamily': 'Poppins',
    'responsive': {
      'mobile': 'Single column, full width',
      'tablet': 'Two columns with generous spacing',
      'desktop': 'Two-column layout with illustration',
    },
  };

  static const Map<String, dynamic> concept3 = {
    'name': 'Glassmorphism',
    'bgColor': '#0F172A',
    'cardColor': 'rgba(30, 41, 59, 0.15)',
    'backdropBlur': 10,
    'borderColor': '#475569',
    'borderOpacity': 0.2,
    'shadowBlur': 20,
    'shadowOpacity': 0.2,
    'primaryColor': '#7C3AED',
    'fontFamily': 'Poppins',
    'responsive': {
      'mobile': 'Single column, full width',
      'tablet': 'Two columns with glass effect',
      'desktop': 'Two-column layout with depth',
    },
  };
}

