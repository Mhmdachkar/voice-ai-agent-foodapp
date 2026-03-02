import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, TextInput, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAuthStore } from '../../state/AuthStore';
import { colors, spacing, radii } from '../../theme/theme';
import type { SpiceLevel, FoodMemory } from '../../models/FoodMemory';

const DIETARY_OPTIONS = [
  { id: 'gluten_free', label: 'Gluten-Free', icon: '\uD83C\uDF3E' },
  { id: 'nut_allergy', label: 'Nut Allergy', icon: '\uD83E\uDD5C' },
  { id: 'dairy_free', label: 'Dairy-Free', icon: '\uD83E\uDD5B' },
  { id: 'vegan', label: 'Vegan', icon: '\uD83C\uDF31' },
  { id: 'vegetarian', label: 'Vegetarian', icon: '\uD83E\uDD66' },
  { id: 'halal', label: 'Halal', icon: '\u2618\uFE0F' },
  { id: 'kosher', label: 'Kosher', icon: '\u2721\uFE0F' },
  { id: 'shellfish', label: 'Shellfish Allergy', icon: '\uD83E\uDD90' },
  { id: 'soy_free', label: 'Soy-Free', icon: '\uD83C\uDF3F' },
  { id: 'egg_free', label: 'Egg-Free', icon: '\uD83E\uDD5A' },
];

const SPICE_LEVELS: { value: SpiceLevel; label: string; icon: string }[] = [
  { value: 'none', label: 'None', icon: '\u2744\uFE0F' },
  { value: 'mild', label: 'Mild', icon: '\uD83C\uDF36\uFE0F' },
  { value: 'medium', label: 'Medium', icon: '\uD83D\uDD25' },
  { value: 'hot', label: 'Hot', icon: '\uD83D\uDD25\uD83D\uDD25' },
  { value: 'extraHot', label: 'Extra Hot', icon: '\uD83E\uDDE8' },
];

const CUISINES = ['Italian', 'Japanese', 'Mexican', 'Thai', 'Indian', 'Chinese', 'American', 'Korean', 'Mediterranean', 'Vietnamese'];

export const DietaryProfileScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user, updateFoodMemory } = useAuthStore();
  const fm = user?.foodMemory;

  const [selectedDietary, setSelectedDietary] = useState<string[]>(fm?.dietaryRestrictions ?? []);
  const [disliked, setDisliked] = useState(fm?.dislikedIngredients?.join(', ') ?? '');
  const [spiceLevel, setSpiceLevel] = useState<SpiceLevel>(fm?.spiceLevel ?? 'medium');
  const [defaultDrink, setDefaultDrink] = useState(fm?.defaultDrink ?? '');
  const [selectedCuisines, setSelectedCuisines] = useState<string[]>(fm?.preferredCuisines ?? []);

  const toggleDietary = (id: string) => {
    setSelectedDietary(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  };

  const toggleCuisine = (c: string) => {
    setSelectedCuisines(prev => prev.includes(c) ? prev.filter(x => x !== c) : [...prev, c]);
  };

  const handleSave = async () => {
    const memory: FoodMemory = {
      dietaryRestrictions: selectedDietary,
      dislikedIngredients: disliked.split(',').map(s => s.trim()).filter(Boolean),
      spiceLevel,
      defaultDrink: defaultDrink.trim() || null,
      commonNotes: fm?.commonNotes ?? null,
      preferredCuisines: selectedCuisines,
    };
    await updateFoodMemory(memory);
    Alert.alert('Profile Updated!', 'Your dietary preferences have been saved. They will appear in checkout and your profile.');
  };

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <Text style={s.title}>{'\uD83D\uDEE1\uFE0F'} Dietary Profile</Text>
      <Text style={s.subtitle}>Set once, we'll watch out for you every time</Text>

      {/* Allergen Shield Banner */}
      <View style={s.shieldBanner}>
        <Text style={s.shieldIcon}>{'\uD83D\uDEE1\uFE0F'}</Text>
        <View style={{ flex: 1 }}>
          <Text style={s.shieldTitle}>Allergen Shield Active</Text>
          <Text style={s.shieldDesc}>
            Menu items that conflict with your profile will be flagged with warnings
          </Text>
        </View>
      </View>

      {/* Dietary Restrictions */}
      <Text style={s.sectionTitle}>Dietary Restrictions & Allergies</Text>
      <View style={s.chipGrid}>
        {DIETARY_OPTIONS.map(opt => {
          const active = selectedDietary.includes(opt.id);
          return (
            <Pressable key={opt.id} style={[s.dietaryChip, active && s.dietaryChipActive]} onPress={() => toggleDietary(opt.id)}>
              <Text style={s.dietaryIcon}>{opt.icon}</Text>
              <Text style={[s.dietaryLabel, active && s.dietaryLabelActive]}>{opt.label}</Text>
              {active && <Text style={s.checkMark}>{'\u2713'}</Text>}
            </Pressable>
          );
        })}
      </View>

      {/* Disliked Ingredients */}
      <Text style={s.sectionTitle}>Disliked Ingredients</Text>
      <TextInput
        style={s.input}
        value={disliked}
        onChangeText={setDisliked}
        placeholder="e.g. cilantro, anchovies, mushrooms"
        placeholderTextColor={colors.textSecondary}
      />

      {/* Spice Level */}
      <Text style={s.sectionTitle}>Spice Preference</Text>
      <View style={s.spiceRow}>
        {SPICE_LEVELS.map(sp => (
          <Pressable key={sp.value} style={[s.spiceChip, spiceLevel === sp.value && s.spiceChipActive]} onPress={() => setSpiceLevel(sp.value)}>
            <Text style={s.spiceIcon}>{sp.icon}</Text>
            <Text style={[s.spiceLabel, spiceLevel === sp.value && s.spiceLabelActive]}>{sp.label}</Text>
          </Pressable>
        ))}
      </View>

      {/* Default Drink */}
      <Text style={s.sectionTitle}>Default Drink</Text>
      <TextInput
        style={s.input}
        value={defaultDrink}
        onChangeText={setDefaultDrink}
        placeholder="e.g. Iced Latte, Mango Lassi"
        placeholderTextColor={colors.textSecondary}
      />

      {/* Preferred Cuisines */}
      <Text style={s.sectionTitle}>Preferred Cuisines</Text>
      <View style={s.cuisineGrid}>
        {CUISINES.map(c => {
          const active = selectedCuisines.includes(c);
          return (
            <Pressable key={c} style={[s.cuisineChip, active && s.cuisineChipActive]} onPress={() => toggleCuisine(c)}>
              <Text style={[s.cuisineText, active && s.cuisineTextActive]}>{c}</Text>
            </Pressable>
          );
        })}
      </View>

      <Pressable style={s.saveBtn} onPress={handleSave}>
        <Text style={s.saveBtnText}>Save Dietary Profile</Text>
      </Pressable>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  title: { fontSize: 26, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginTop: 4, marginBottom: spacing.md },
  shieldBanner: { flexDirection: 'row', backgroundColor: '#E8F5E9', borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.lg, alignItems: 'center' },
  shieldIcon: { fontSize: 32, marginRight: spacing.sm },
  shieldTitle: { fontSize: 15, fontWeight: '700', color: '#2E7D32' },
  shieldDesc: { fontSize: 12, color: '#4CAF50', marginTop: 2 },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.sm, marginTop: spacing.md },
  chipGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  dietaryChip: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.cardBackground, borderRadius: radii.medium, paddingHorizontal: 14, paddingVertical: 10, borderWidth: 1.5, borderColor: 'transparent' },
  dietaryChipActive: { borderColor: colors.danger, backgroundColor: colors.danger + '08' },
  dietaryIcon: { fontSize: 18, marginRight: 6 },
  dietaryLabel: { fontSize: 13, fontWeight: '600', color: colors.textSecondary },
  dietaryLabelActive: { color: colors.danger },
  checkMark: { fontSize: 14, color: colors.danger, marginLeft: 4, fontWeight: '700' },
  input: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, paddingHorizontal: spacing.md, paddingVertical: 12, fontSize: 14, color: colors.textPrimary },
  spiceRow: { flexDirection: 'row', gap: spacing.xs },
  spiceChip: { flex: 1, backgroundColor: colors.cardBackground, borderRadius: radii.medium, paddingVertical: 12, alignItems: 'center', borderWidth: 1.5, borderColor: 'transparent' },
  spiceChipActive: { borderColor: colors.accent, backgroundColor: colors.accent + '10' },
  spiceIcon: { fontSize: 18, marginBottom: 4 },
  spiceLabel: { fontSize: 11, fontWeight: '600', color: colors.textSecondary },
  spiceLabelActive: { color: colors.accent },
  cuisineGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  cuisineChip: { backgroundColor: colors.cardBackground, borderRadius: 20, paddingHorizontal: 16, paddingVertical: 8, borderWidth: 1.5, borderColor: 'transparent' },
  cuisineChipActive: { borderColor: colors.accent, backgroundColor: colors.accent + '10' },
  cuisineText: { fontSize: 13, fontWeight: '600', color: colors.textSecondary },
  cuisineTextActive: { color: colors.accent },
  saveBtn: { backgroundColor: colors.accent, borderRadius: radii.button, paddingVertical: 16, alignItems: 'center', marginTop: spacing.xl },
  saveBtnText: { color: '#FFF', fontSize: 16, fontWeight: '700' },
});
