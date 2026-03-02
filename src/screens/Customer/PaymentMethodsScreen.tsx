import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { colors, spacing, radii } from '../../theme/theme';

interface PaymentMethod {
  id: string;
  type: 'visa' | 'mastercard' | 'apple_pay' | 'cash';
  label: string;
  last4?: string;
  isDefault: boolean;
}

const SEED_METHODS: PaymentMethod[] = [
  { id: 'pm1', type: 'visa', label: 'Visa', last4: '4242', isDefault: true },
  { id: 'pm2', type: 'mastercard', label: 'Mastercard', last4: '8888', isDefault: false },
  { id: 'pm3', type: 'apple_pay', label: 'Apple Pay', isDefault: false },
  { id: 'pm4', type: 'cash', label: 'Cash on Delivery', isDefault: false },
];

const ICONS: Record<string, string> = {
  visa: '\uD83D\uDCB3',
  mastercard: '\uD83D\uDCB3',
  apple_pay: '\uD83C\uDF4F',
  cash: '\uD83D\uDCB5',
};

export const PaymentMethodsScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const [methods, setMethods] = useState<PaymentMethod[]>(SEED_METHODS);

  const setDefault = (id: string) => {
    setMethods(prev => prev.map(m => ({ ...m, isDefault: m.id === id })));
  };

  const removeMethod = (id: string) => {
    Alert.alert('Remove', 'Remove this payment method?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Remove', style: 'destructive', onPress: () => setMethods(prev => prev.filter(m => m.id !== id)) },
    ]);
  };

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <View style={s.header}>
        <Pressable onPress={() => router.back()}>
          <Text style={s.backBtn}>{'\u2190'}</Text>
        </Pressable>
        <Text style={s.headerTitle}>Payment Methods</Text>
        <View style={{ width: 24 }} />
      </View>

      {methods.map(m => (
        <Pressable key={m.id} style={[s.card, m.isDefault && s.cardDefault]} onPress={() => setDefault(m.id)}>
          <View style={s.cardLeft}>
            <Text style={s.cardIcon}>{ICONS[m.type]}</Text>
            <View>
              <Text style={s.cardLabel}>{m.label}{m.last4 ? ` ****${m.last4}` : ''}</Text>
              {m.isDefault && <Text style={s.defaultBadge}>Default</Text>}
            </View>
          </View>
          {!m.isDefault && (
            <Pressable onPress={() => removeMethod(m.id)} hitSlop={8}>
              <Text style={s.removeText}>{'\u2715'}</Text>
            </Pressable>
          )}
          {m.isDefault && <Text style={s.checkMark}>{'\u2713'}</Text>}
        </Pressable>
      ))}

      <Pressable style={s.addBtn} onPress={() => Alert.alert('Add Payment', 'Payment method addition would integrate with Stripe/Apple Pay SDK.')}>
        <Text style={s.addBtnIcon}>+</Text>
        <Text style={s.addBtnText}>Add Payment Method</Text>
      </Pressable>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: spacing.lg },
  backBtn: { fontSize: 24, color: colors.textPrimary },
  headerTitle: { fontSize: 20, fontWeight: '800', color: colors.textPrimary },
  card: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.sm, borderWidth: 1.5, borderColor: 'transparent' },
  cardDefault: { borderColor: colors.accent, backgroundColor: colors.accent + '08' },
  cardLeft: { flexDirection: 'row', alignItems: 'center' },
  cardIcon: { fontSize: 28, marginRight: spacing.sm },
  cardLabel: { fontSize: 15, fontWeight: '700', color: colors.textPrimary },
  defaultBadge: { fontSize: 11, fontWeight: '600', color: colors.accent, marginTop: 2 },
  checkMark: { fontSize: 18, color: colors.accent, fontWeight: '700' },
  removeText: { fontSize: 16, color: colors.textSecondary },
  addBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginTop: spacing.md, borderWidth: 1.5, borderColor: colors.border, borderStyle: 'dashed' },
  addBtnIcon: { fontSize: 22, fontWeight: '700', color: colors.accent, marginRight: spacing.sm },
  addBtnText: { fontSize: 15, fontWeight: '600', color: colors.accent },
});
