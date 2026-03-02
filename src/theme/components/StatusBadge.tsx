import React from 'react';
import { View, Text, StyleSheet, ViewStyle, StyleProp } from 'react-native';
import { colors, radii, spacing } from '../theme';

type BadgeVariant = 'success' | 'warning' | 'danger' | 'accent' | 'neutral';

const VARIANT_COLORS: Record<BadgeVariant, { bg: string; text: string }> = {
  success: { bg: colors.success, text: '#FFFFFF' },
  warning: { bg: colors.warning, text: '#FFFFFF' },
  danger: { bg: colors.danger, text: '#FFFFFF' },
  accent: { bg: colors.accent, text: '#FFFFFF' },
  neutral: { bg: colors.border, text: colors.textPrimary },
};

interface StatusBadgeProps {
  label: string;
  variant?: BadgeVariant;
  style?: StyleProp<ViewStyle>;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  label,
  variant = 'neutral',
  style,
}) => {
  const scheme = VARIANT_COLORS[variant];
  return (
    <View style={[styles.badge, { backgroundColor: scheme.bg }, style]}>
      <Text style={[styles.text, { color: scheme.text }]}>{label}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: radii.small,
    alignSelf: 'flex-start',
  },
  text: {
    fontSize: 11,
    fontWeight: '600',
  },
});
