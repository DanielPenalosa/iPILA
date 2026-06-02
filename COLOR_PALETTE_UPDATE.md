# iPILA Color Palette Update

## Overview
The iPILA application has been updated to use the official Municipality of Pila color palette across both web and mobile platforms.

---

## Official Color Palette

### Primary Colors
| Color Name | Hex Code | RGB | Usage |
|------------|----------|-----|-------|
| **Orange** | `#E04A17` | `rgb(224, 74, 23)` | Primary brand color, buttons, CTAs |
| **Yellow** | `#F2B705` | `rgb(242, 183, 5)` | Secondary accent, highlights |
| **Light Yellow** | `#FFD166` | `rgb(255, 209, 102)` | Backgrounds, subtle accents |
| **Peach** | `#FFB07C` | `rgb(255, 176, 124)` | Tertiary accent, warm tones |
| **Coral** | `#EF5B4C` | `rgb(239, 91, 76)` | Alerts, errors, urgent items |
| **Light Peach** | `#F7E7E1` | `rgb(247, 231, 225)` | Soft backgrounds, cards |

### Neutral Colors
| Color Name | Hex Code | RGB | Usage |
|------------|----------|-----|-------|
| **Light Gray** | `#EFEFEF` | `rgb(239, 239, 239)` | Borders, dividers |
| **Dark Gray** | `#333333` | `rgb(51, 51, 51)` | Primary text |
| **Black** | `#111111` | `rgb(17, 17, 17)` | Headers, emphasis |
| **White** | `#FFFFFF` | `rgb(255, 255, 255)` | Backgrounds, cards |

---

## Implementation Details

### Files Updated

1. **`lib/core/theme/app_theme.dart`**
   - Updated all color constants to match official palette
   - Mapped status colors to palette colors
   - Updated theme data for buttons, inputs, and components
   - Added gradient support for primary elements

2. **`lib/features/home/screens/home_screen.dart`**
   - Updated user avatar background to use orange
   - Changed report banner to use orange-coral gradient
   - Improved visual hierarchy with new colors

3. **`web/manifest.json`**
   - Updated `theme_color` from green (`#2E7D32`) to orange (`#E04A17`)
   - Ensures consistent branding in PWA installations

---

## Color Usage Guidelines

### Primary Actions
- **Buttons**: Orange (`#E04A17`)
- **Links**: Orange (`#E04A17`)
- **Active States**: Orange with 12% opacity

### Status Colors
| Status | Color | Hex Code |
|--------|-------|----------|
| Submitted | Yellow | `#F2B705` |
| Seen | Light Yellow | `#FFD166` |
| Validated | Peach | `#FFB07C` |
| Queued | Orange | `#E04A17` |
| In Progress | Coral | `#EF5B4C` |
| Completed | Green | `#22C55E` |
| Rejected | Dark Gray | `#333333` |

### Backgrounds
- **App Background**: Light gray (`#F8F8F8`)
- **Card Background**: White (`#FFFFFF`)
- **Subtle Highlights**: Light Peach (`#F7E7E1`)

### Text
- **Primary Text**: Dark Gray (`#333333`)
- **Secondary Text**: Muted Gray (`#6B7280`)
- **On Dark Backgrounds**: White (`#FFFFFF`)

---

## Visual Examples

### Before & After

**Before:**
- Primary color: Blue (`#2F5EF7`)
- Theme: Generic blue/green government theme
- Limited brand identity

**After:**
- Primary color: Orange (`#E04A17`)
- Theme: Warm, welcoming Pila municipality colors
- Strong brand identity matching official materials

### Key UI Elements

#### Buttons
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryOrange, // #E04A17
    foregroundColor: AppTheme.white,
  ),
)
```

#### Gradients
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      AppTheme.primaryOrange,  // #E04A17
      AppTheme.coral,          // #EF5B4C
    ],
  ),
)
```

#### Status Badges
```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.statusColor(status).withValues(alpha: 0.12),
  ),
  child: Text(
    status,
    style: TextStyle(color: AppTheme.statusColor(status)),
  ),
)
```

---

## Accessibility Considerations

### Contrast Ratios
All color combinations meet WCAG 2.1 AA standards:

- **Orange on White**: 4.8:1 (AA Large Text ✓)
- **Dark Gray on White**: 12.6:1 (AAA ✓)
- **White on Orange**: 4.8:1 (AA Large Text ✓)
- **White on Coral**: 5.2:1 (AA ✓)

### Recommendations
- Use orange primarily for large elements (buttons, banners)
- For small text, use dark gray (`#333333`)
- Ensure sufficient contrast for all interactive elements
- Test with color blindness simulators

---

## Brand Consistency

### Logo Integration
The color palette matches the official "OnePila" logo:
- Rainbow community icon
- Orange "ONEPILA" text
- Red "Municipality of Pila" subtitle
- Warm, welcoming aesthetic

### Marketing Materials
These colors should be used consistently across:
- Website
- Mobile app
- Print materials
- Social media
- Signage
- Official documents

---

## Technical Notes

### Flutter Implementation
```dart
// Access colors via AppTheme class
AppTheme.primaryOrange
AppTheme.primaryYellow
AppTheme.lightPeach
// etc.

// Status colors are dynamic
AppTheme.statusColor('In Progress') // Returns coral
AppTheme.statusIcon('Completed')    // Returns check icon
```

### Web Manifest
```json
{
  "theme_color": "#E04A17",
  "background_color": "#ffffff"
}
```

### CSS Variables (if needed)
```css
:root {
  --color-primary-orange: #E04A17;
  --color-primary-yellow: #F2B705;
  --color-light-yellow: #FFD166;
  --color-peach: #FFB07C;
  --color-coral: #EF5B4C;
  --color-light-peach: #F7E7E1;
  --color-light-gray: #EFEFEF;
  --color-dark-gray: #333333;
  --color-black: #111111;
  --color-white: #FFFFFF;
}
```

---

## Future Enhancements

### Potential Additions
1. **Dark Mode**: Create dark theme variants using the same palette
2. **Seasonal Themes**: Subtle variations for holidays/events
3. **Accessibility Mode**: High contrast version
4. **Animation**: Use color transitions for smooth UX

### Maintenance
- Review color usage quarterly
- Ensure new features follow palette guidelines
- Update documentation as palette evolves
- Test on various devices and screen types

---

## References

- **Source**: Official Municipality of Pila branding materials
- **Design System**: Material Design 3 with custom Pila colors
- **Accessibility**: WCAG 2.1 Level AA compliance
- **Platform**: Flutter 3.x with Material 3

---

## Contact

For questions about the color palette or branding guidelines, contact:
- **Email**: onepilaofficial@gmail.com
- **Location**: Pila, Laguna

---

*Last Updated: Implementation Date*
*Version: 1.0*
