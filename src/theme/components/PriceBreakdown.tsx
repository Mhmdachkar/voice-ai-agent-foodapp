import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing } from '../theme';

interface PriceBreakdownProps {
  subtotal: number;
  tax: number;
  deliveryFee: number;
  tip: number;
  discount: number;
  total: number;
}

const formatMoney = (value: number) => `$${value.toFixed(2)}`;

export const PriceBreakdown: React.FC<PriceBreakdownProps> = ({
  subtotal,
  tax,
  deliveryFee,
  tip,
  discount,
  total,
}) => {
  return (
    <View style={styles.container}>
      <Row label="Subtotal" value={formatMoney(subtotal)} />
      <Row label="Tax" value={formatMoney(tax)} />
      <Row label="Delivery fee" value={formatMoney(deliveryFee)} />
      <Row label="Tip" value={formatMoney(tip)} />
      {discount > 0 ? (
        <Row label="Discount" value={`- ${formatMoney(discount)}`} />
      ) : null}
      <View style={styles.divider} />
      <Row label="Total" value={formatMoney(total)} strong />
    </View>
  );
};

interface RowProps {
  label: string;
  value: string;
  strong?: boolean;
}

const Row: React.FC<RowProps> = ({ label, value, strong }) => (
  <View style={styles.row}>
    <Text style={[styles.label, strong && styles.strong]}>{label}</Text>
    <Text style={[styles.value, strong && styles.strong]}>{value}</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    gap: 4,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginVertical: 2,
  },
  label: {
    color: colors.textSecondary,
    fontSize: 14,
  },
  value: {
    color: colors.textPrimary,
    fontSize: 14,
  },
  strong: {
    fontWeight: '700',
    color: colors.textPrimary,
  },
  divider: {
    height: 1,
    marginVertical: spacing.sm,
    backgroundColor: colors.border,
  },
});

