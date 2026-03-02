import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing } from '../theme';

export type ToastType = 'success' | 'error' | 'info';

interface ToastProps {
  message: string;
  type?: ToastType;
}

export const Toast: React.FC<ToastProps> = ({
  message,
  type = 'info',
}) => {
  const accent =
    type === 'success'
      ? colors.success
      : type === 'error'
      ? colors.danger
      : colors.accent;

  return (
    <View style={styles.container}>
      <View style={[styles.icon, { backgroundColor: accent }]} />
      <Text style={styles.text}>{message}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
    paddingVertical: 14,
    borderRadius: 999,
    backgroundColor: 'rgba(0,0,0,0.8)',
  },
  icon: {
    width: 8,
    height: 8,
    borderRadius: 999,
    marginRight: 10,
  },
  text: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
});

