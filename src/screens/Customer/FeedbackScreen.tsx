import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, TextInput, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useFeedbackStore } from '../../state/FeedbackStore';
import { useAuthStore } from '../../state/AuthStore';
import { useDataStore } from '../../state/DataStore';
import { INCIDENT_LABELS } from '../../models/Feedback';
import type { IncidentType } from '../../models/Feedback';
import { colors, spacing, radii } from '../../theme/theme';

const TEMP_OPTIONS = [
  { value: 'hot' as const, label: 'Hot', icon: '\uD83D\uDD25' },
  { value: 'warm' as const, label: 'Warm', icon: '\u2600\uFE0F' },
  { value: 'cold' as const, label: 'Cold', icon: '\u2744\uFE0F' },
];

const PKG_OPTIONS = [
  { value: 'excellent' as const, label: 'Excellent', icon: '\uD83C\uDF1F' },
  { value: 'good' as const, label: 'Good', icon: '\uD83D\uDC4D' },
  { value: 'poor' as const, label: 'Poor', icon: '\uD83D\uDC4E' },
];

const StarRow: React.FC<{ rating: number; onRate: (n: number) => void; label: string }> = ({ rating, onRate, label }) => (
  <View style={s.starSection}>
    <Text style={s.starLabel}>{label}</Text>
    <View style={s.starRow}>
      {[1, 2, 3, 4, 5].map(i => (
        <Pressable key={i} onPress={() => onRate(i)}>
          <Text style={[s.star, i <= rating && s.starActive]}>{i <= rating ? '\u2B50' : '\u2606'}</Text>
        </Pressable>
      ))}
    </View>
  </View>
);

export const FeedbackScreen: React.FC<{ orderId: string; onDone?: () => void }> = ({ orderId, onDone }) => {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const { submitFeedback } = useFeedbackStore();
  const [foodRating, setFoodRating] = useState(0);
  const [driverRating, setDriverRating] = useState(0);
  const [temperature, setTemperature] = useState<'hot' | 'warm' | 'cold'>('hot');
  const [packaging, setPackaging] = useState<'excellent' | 'good' | 'poor'>('good');
  const [comment, setComment] = useState('');

  const handleSubmit = () => {
    if (foodRating === 0) { Alert.alert('Please rate the food'); return; }
    submitFeedback({
      orderId,
      userId: user?.id ?? '',
      foodRating,
      driverRating,
      temperature,
      packagingQuality: packaging,
      missingItems: [],
      comment: comment.trim() || null,
    });
    Alert.alert('Thank you!', 'Your feedback helps us improve.', [{ text: 'OK', onPress: onDone }]);
  };

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <Text style={s.title}>{'\uD83D\uDCDD'} Rate Your Order</Text>
      <Text style={s.subtitle}>Your feedback helps us improve</Text>

      <StarRow rating={foodRating} onRate={setFoodRating} label="Food Quality" />
      <StarRow rating={driverRating} onRate={setDriverRating} label="Delivery Experience" />

      <Text style={s.sectionLabel}>Food Temperature</Text>
      <View style={s.optionRow}>
        {TEMP_OPTIONS.map(o => (
          <Pressable key={o.value} style={[s.optionChip, temperature === o.value && s.optionChipActive]} onPress={() => setTemperature(o.value)}>
            <Text style={s.optionIcon}>{o.icon}</Text>
            <Text style={[s.optionText, temperature === o.value && s.optionTextActive]}>{o.label}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={s.sectionLabel}>Packaging Quality</Text>
      <View style={s.optionRow}>
        {PKG_OPTIONS.map(o => (
          <Pressable key={o.value} style={[s.optionChip, packaging === o.value && s.optionChipActive]} onPress={() => setPackaging(o.value)}>
            <Text style={s.optionIcon}>{o.icon}</Text>
            <Text style={[s.optionText, packaging === o.value && s.optionTextActive]}>{o.label}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={s.sectionLabel}>Additional Comments</Text>
      <TextInput
        style={s.commentInput}
        value={comment}
        onChangeText={setComment}
        placeholder="Tell us more about your experience..."
        placeholderTextColor={colors.textSecondary}
        multiline
        numberOfLines={3}
      />

      <Pressable style={s.submitBtn} onPress={handleSubmit}>
        <Text style={s.submitText}>Submit Feedback</Text>
      </Pressable>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginBottom: spacing.lg },
  starSection: { marginBottom: spacing.lg },
  starLabel: { fontSize: 15, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.sm },
  starRow: { flexDirection: 'row', gap: spacing.sm },
  star: { fontSize: 32, color: colors.border },
  starActive: { color: '#FFD700' },
  sectionLabel: { fontSize: 15, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.sm, marginTop: spacing.sm },
  optionRow: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.md },
  optionChip: { flex: 1, backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, alignItems: 'center', borderWidth: 2, borderColor: 'transparent' },
  optionChipActive: { borderColor: colors.accent, backgroundColor: colors.accent + '10' },
  optionIcon: { fontSize: 24, marginBottom: 4 },
  optionText: { fontSize: 13, fontWeight: '600', color: colors.textSecondary },
  optionTextActive: { color: colors.accent },
  commentInput: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, fontSize: 14, color: colors.textPrimary, minHeight: 80, textAlignVertical: 'top', marginBottom: spacing.lg },
  submitBtn: { backgroundColor: colors.accent, borderRadius: radii.button, padding: spacing.md, alignItems: 'center' },
  submitText: { color: '#FFF', fontSize: 16, fontWeight: '700' },
});
