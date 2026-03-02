import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { colors, spacing, radii } from '../../theme/theme';

interface SavedAddress {
  id: string;
  label: string;
  street: string;
  city: string;
  state: string;
  zip: string;
  notes?: string;
  isDefault: boolean;
}

const SEED_ADDRESSES: SavedAddress[] = [
  { id: 'a1', label: 'Home', street: '123 Oak Street', city: 'Springfield', state: 'IL', zip: '62701', notes: 'Ground floor, blue door', isDefault: true },
  { id: 'a2', label: 'Work', street: '456 Tech Park Ave', city: 'Springfield', state: 'IL', zip: '62702', notes: 'Lobby entrance', isDefault: false },
];

const LABEL_ICONS: Record<string, string> = {
  Home: '\uD83C\uDFE0',
  Work: '\uD83C\uDFE2',
};

export const SavedAddressesScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const [addresses, setAddresses] = useState<SavedAddress[]>(SEED_ADDRESSES);

  const setDefault = (id: string) => {
    setAddresses(prev => prev.map(a => ({ ...a, isDefault: a.id === id })));
  };

  const removeAddress = (id: string) => {
    Alert.alert('Remove', 'Remove this address?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Remove', style: 'destructive', onPress: () => setAddresses(prev => prev.filter(a => a.id !== id)) },
    ]);
  };

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <View style={s.header}>
        <Pressable onPress={() => router.back()}>
          <Text style={s.backBtn}>{'\u2190'}</Text>
        </Pressable>
        <Text style={s.headerTitle}>Saved Addresses</Text>
        <View style={{ width: 24 }} />
      </View>

      {addresses.map(a => (
        <Pressable key={a.id} style={[s.card, a.isDefault && s.cardDefault]} onPress={() => setDefault(a.id)}>
          <View style={s.cardTop}>
            <View style={s.cardLeft}>
              <Text style={s.cardIcon}>{LABEL_ICONS[a.label] ?? '\uD83D\uDCCD'}</Text>
              <View>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <Text style={s.cardLabel}>{a.label}</Text>
                  {a.isDefault && <View style={s.defaultBadge}><Text style={s.defaultBadgeText}>Default</Text></View>}
                </View>
                <Text style={s.cardAddress}>{a.street}</Text>
                <Text style={s.cardCity}>{a.city}, {a.state} {a.zip}</Text>
                {a.notes ? <Text style={s.cardNotes}>{a.notes}</Text> : null}
              </View>
            </View>
            <Pressable onPress={() => removeAddress(a.id)} hitSlop={8}>
              <Text style={s.removeText}>{'\u2715'}</Text>
            </Pressable>
          </View>
        </Pressable>
      ))}

      <Pressable style={s.addBtn} onPress={() => Alert.alert('Add Address', 'Address form would appear here to add a new delivery address.')}>
        <Text style={s.addBtnIcon}>+</Text>
        <Text style={s.addBtnText}>Add New Address</Text>
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
  card: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.sm, borderWidth: 1.5, borderColor: 'transparent' },
  cardDefault: { borderColor: colors.accent, backgroundColor: colors.accent + '08' },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  cardLeft: { flexDirection: 'row', flex: 1 },
  cardIcon: { fontSize: 28, marginRight: spacing.sm, marginTop: 2 },
  cardLabel: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  defaultBadge: { backgroundColor: colors.accent, borderRadius: 8, paddingHorizontal: 8, paddingVertical: 2, marginLeft: 8 },
  defaultBadgeText: { fontSize: 10, fontWeight: '700', color: '#FFF' },
  cardAddress: { fontSize: 14, color: colors.textSecondary, marginTop: 2 },
  cardCity: { fontSize: 13, color: colors.textSecondary },
  cardNotes: { fontSize: 12, color: colors.accent, fontStyle: 'italic', marginTop: 4 },
  removeText: { fontSize: 16, color: colors.textSecondary, padding: 4 },
  addBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginTop: spacing.md, borderWidth: 1.5, borderColor: colors.border, borderStyle: 'dashed' },
  addBtnIcon: { fontSize: 22, fontWeight: '700', color: colors.accent, marginRight: spacing.sm },
  addBtnText: { fontSize: 15, fontWeight: '600', color: colors.accent },
});
