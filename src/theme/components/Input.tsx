import React from 'react';
import {
  TextInput,
  TextInputProps,
  View,
  Text,
  StyleSheet,
} from 'react-native';
import { colors, radii, spacing } from '../theme';

interface InputProps extends TextInputProps {
  label?: string;
  errorText?: string;
}

export const Input: React.FC<InputProps> = ({
  label,
  errorText,
  style,
  ...rest
}) => {
  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      <TextInput
        style={[styles.input, style]}
        placeholderTextColor={colors.textSecondary}
        {...rest}
      />
      {errorText ? <Text style={styles.error}>{errorText}</Text> : null}
    </View>
  );
};

const styles = StyleSheet.create({
  label: {
    marginBottom: 4,
    color: colors.textPrimary,
    fontSize: 14,
    fontWeight: '600',
  },
  input: {
    height: 48,
    borderRadius: radii.small,
    borderWidth: 1,
    borderColor: colors.border,
    paddingHorizontal: spacing.md,
    backgroundColor: '#FFFFFF',
    color: colors.textPrimary,
    fontSize: 15,
  },
  error: {
    marginTop: 4,
    color: colors.danger,
    fontSize: 12,
  },
});

