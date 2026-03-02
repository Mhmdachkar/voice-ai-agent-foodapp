export const colors = {
  // Brand
  accent: '#FF8C1A',
  accentLight: '#FFB366',
  accentDark: '#E67A00',
  
  // Backgrounds
  background: '#F8F8F8',
  cardBackground: '#FFFFFF',
  overlayBackground: 'rgba(0, 0, 0, 0.5)',
  
  // Text
  textPrimary: '#1A1A2E',
  textSecondary: '#8E8E93',
  textTertiary: '#C7C7CC',
  textInverse: '#FFFFFF',
  
  // Borders & Dividers
  border: '#E5E5EA',
  borderLight: '#F2F2F7',
  divider: '#E5E5EA',
  
  // Status
  success: '#34C759',
  successLight: '#E8F8EC',
  warning: '#FF9500',
  warningLight: '#FFF4E5',
  danger: '#FF3B30',
  dangerLight: '#FFEBE9',
  info: '#007AFF',
  infoLight: '#E5F1FF',
  
  // Additional
  shimmer: '#F0F0F0',
  shadow: '#000000',
};

export const darkColors = {
  // Brand (stays same)
  accent: '#FF8C1A',
  accentLight: '#FFB366',
  accentDark: '#E67A00',
  
  // Backgrounds
  background: '#000000',
  cardBackground: '#1C1C1E',
  overlayBackground: 'rgba(0, 0, 0, 0.8)',
  
  // Text
  textPrimary: '#FFFFFF',
  textSecondary: '#AEAEB2',
  textTertiary: '#636366',
  textInverse: '#000000',
  
  // Borders & Dividers
  border: '#38383A',
  borderLight: '#2C2C2E',
  divider: '#38383A',
  
  // Status
  success: '#32D74B',
  successLight: '#1A3323',
  warning: '#FF9F0A',
  warningLight: '#332A1A',
  danger: '#FF453A',
  dangerLight: '#331A1A',
  info: '#0A84FF',
  infoLight: '#1A2633',
  
  // Additional
  shimmer: '#2C2C2E',
  shadow: '#000000',
};

export const typography = {
  // Headings
  h1: {
    fontSize: 32,
    fontWeight: '800' as const,
    lineHeight: 40,
    letterSpacing: -0.5,
  },
  h2: {
    fontSize: 26,
    fontWeight: '800' as const,
    lineHeight: 32,
    letterSpacing: -0.3,
  },
  h3: {
    fontSize: 20,
    fontWeight: '700' as const,
    lineHeight: 26,
    letterSpacing: 0,
  },
  h4: {
    fontSize: 18,
    fontWeight: '700' as const,
    lineHeight: 24,
    letterSpacing: 0,
  },
  
  // Body
  body: {
    fontSize: 15,
    fontWeight: '400' as const,
    lineHeight: 22,
    letterSpacing: 0,
  },
  bodyBold: {
    fontSize: 15,
    fontWeight: '600' as const,
    lineHeight: 22,
    letterSpacing: 0,
  },
  bodyLarge: {
    fontSize: 17,
    fontWeight: '400' as const,
    lineHeight: 24,
    letterSpacing: 0,
  },
  
  // UI Elements
  button: {
    fontSize: 16,
    fontWeight: '700' as const,
    lineHeight: 20,
    letterSpacing: 0.3,
  },
  caption: {
    fontSize: 12,
    fontWeight: '500' as const,
    lineHeight: 16,
    letterSpacing: 0,
  },
  captionBold: {
    fontSize: 12,
    fontWeight: '700' as const,
    lineHeight: 16,
    letterSpacing: 0.3,
  },
  meta: {
    fontSize: 11,
    fontWeight: '600' as const,
    lineHeight: 14,
    letterSpacing: 0.5,
  },
};

export const shadows = {
  none: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0,
    shadowRadius: 0,
    elevation: 0,
  },
  sm: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 2,
  },
  md: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  lg: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
    elevation: 6,
  },
  xl: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.12,
    shadowRadius: 24,
    elevation: 10,
  },
};

export const radii = {
  xs: 8,
  small: 12,
  medium: 16,
  large: 20,
  xl: 24,
  xxl: 28,
  round: 999,
  button: 24,
};

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const animations = {
  duration: {
    fast: 150,
    normal: 300,
    slow: 500,
  },
  easing: {
    ease: 'ease' as const,
    easeIn: 'ease-in' as const,
    easeOut: 'ease-out' as const,
    easeInOut: 'ease-in-out' as const,
  },
};

// Breakpoints for responsive design
export const breakpoints = {
  phone: 0,
  tablet: 768,
  desktop: 1024,
};

// Z-index layering
export const zIndex = {
  base: 0,
  dropdown: 1000,
  sticky: 1100,
  modal: 1300,
  popover: 1400,
  toast: 1500,
};

