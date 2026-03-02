import React from 'react';
import {
  Pressable,
  Text,
  StyleSheet,
  ViewStyle,
  StyleProp,
} from 'react-native';
import { colors, radii, spacing } from '../theme';

export interface ChipProps {
  label: string;
  selected?: boolean;
  size?: 'small' | 'medium';
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
}

export const Chip: React.FC<ChipProps> = ({
  label,
  selected = false,
  size = 'medium',
  onPress,
  style,
}) => {
  const isSmall = size === 'small';
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.base,
        isSmall && styles.baseSmall,
        {
          backgroundColor: selected ? colors.accent : colors.cardBackground,
          borderColor: selected ? 'transparent' : colors.border,
          opacity: pressed ? 0.9 : 1,
        },
        style,
      ]}
    >
      <Text
        style={[
          styles.label,
          isSmall && styles.labelSmall,
          { color: selected ? '#FFFFFF' : colors.textPrimary },
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  base: {
    paddingHorizontal: spacing.md,
    paddingVertical: 10,
    borderRadius: 999,
    borderWidth: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  baseSmall: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
  },
  labelSmall: {
    fontSize: 12,
  },
});

