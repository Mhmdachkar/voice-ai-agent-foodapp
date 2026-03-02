import React from 'react';
import { View, Text, StyleSheet, ViewStyle, StyleProp } from 'react-native';
import { colors, spacing, radii } from '../theme';

type BadgeVariant = 'danger' | 'warning' | 'success' | 'info' | 'default';

const VARIANT_COLORS: Record<BadgeVariant, { bg: string; fg: string }> = {
  danger: { bg: colors.danger, fg: '#FFFFFF' },
  warning: { bg: colors.warning, fg: '#FFFFFF' },
  success: { bg: colors.success, fg: '#FFFFFF' },
  info: { bg: colors.accent, fg: '#FFFFFF' },
  default: { bg: colors.border, fg: colors.textPrimary },
};

export interface BadgeProps {
  count?: number;
  text?: string;
  variant?: BadgeVariant;
  style?: StyleProp<ViewStyle>;
}

export const Badge: React.FC<BadgeProps> = ({ count, text, variant = 'danger', style }) => {
  // Count mode (original)
  if (count !== undefined) {
    if (count <= 0) return null;
    const { bg, fg } = VARIANT_COLORS[variant];
    return (
      <View style={[styles.badge, { backgroundColor: bg }, style]}>
        <Text style={[styles.text, { color: fg }]}>{count > 99 ? '99+' : count}</Text>
      </View>
    );
  }

  // Text mode
  if (text) {
    const { bg, fg } = VARIANT_COLORS[variant];
    return (
      <View style={[styles.textBadge, { backgroundColor: bg }, style]}>
        <Text style={[styles.textBadgeLabel, { color: fg }]}>{text}</Text>
      </View>
    );
  }

  return null;
};

const styles = StyleSheet.create({
  badge: {
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: colors.danger,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  text: {
    fontSize: 11,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  textBadge: {
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: radii.small,
  },
  textBadgeLabel: {
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
});
