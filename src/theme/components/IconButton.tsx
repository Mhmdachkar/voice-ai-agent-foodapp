import React from 'react';
import { Pressable, StyleSheet, PressableProps, ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { colors, radii, spacing, shadows } from '../theme';

type IconButtonSize = 'small' | 'medium' | 'large';
type IconButtonVariant = 'filled' | 'outlined' | 'ghost';

interface IconButtonProps extends Omit<PressableProps, 'style'> {
  icon: keyof typeof Ionicons.glyphMap;
  size?: IconButtonSize;
  variant?: IconButtonVariant;
  color?: string;
  backgroundColor?: string;
  disabled?: boolean;
  haptic?: boolean;
  style?: ViewStyle;
}

const sizeMap = {
  small: { container: 32, icon: 18 },
  medium: { container: 44, icon: 22 },
  large: { container: 56, icon: 28 },
};

export const IconButton: React.FC<IconButtonProps> = ({
  icon,
  size = 'medium',
  variant = 'ghost',
  color = colors.textPrimary,
  backgroundColor,
  disabled = false,
  haptic = true,
  onPress,
  style,
  ...pressableProps
}) => {
  const handlePress = (e: any) => {
    if (haptic && !disabled) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    onPress?.(e);
  };

  const containerSize = sizeMap[size].container;
  const iconSize = sizeMap[size].icon;

  const getBackgroundColor = () => {
    if (backgroundColor) return backgroundColor;
    if (variant === 'filled') return colors.accent;
    if (variant === 'outlined') return 'transparent';
    return 'transparent';
  };

  const getIconColor = () => {
    if (disabled) return colors.textTertiary;
    if (variant === 'filled') return colors.textInverse;
    return color;
  };

  return (
    <Pressable
      onPress={handlePress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.container,
        {
          width: containerSize,
          height: containerSize,
          backgroundColor: getBackgroundColor(),
        },
        variant === 'outlined' && styles.outlined,
        variant === 'filled' && shadows.sm,
        pressed && !disabled && styles.pressed,
        disabled && styles.disabled,
        style,
      ]}
      accessibilityRole="button"
      {...pressableProps}
    >
      <Ionicons
        name={icon}
        size={iconSize}
        color={getIconColor()}
      />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radii.round,
  },
  outlined: {
    borderWidth: 1,
    borderColor: colors.border,
  },
  pressed: {
    opacity: 0.7,
    transform: [{ scale: 0.95 }],
  },
  disabled: {
    opacity: 0.4,
  },
});
