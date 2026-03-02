import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, TextInput, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useFeedbackStore } from '../../state/FeedbackStore';
import { useAuthStore } from '../../state/AuthStore';
import { INCIDENT_LABELS } from '../../models/Feedback';
import type { IncidentType } from '../../models/Feedback';
import { colors, spacing, radii } from '../../theme/theme';

const ISSUE_TYPES: { type: IncidentType; icon: string }[] = [
  { type: 'missing_item', icon: '\uD83D\uDCE6' },
  { type: 'wrong_order', icon: '\u274C' },
  { type: 'cold_food', icon: '\u2744\uFE0F' },
  { type: 'late_delivery', icon: '\u23F0' },
  { type: 'damaged', icon: '\uD83D\uDCA5' },
  { type: 'other', icon: '\uD83D\uDCAC' },
];

export const ReportIssueScreen: React.FC<{ orderId: string; onDone?: () => void }> = ({ orderId, onDone }) => {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const { submitIncident } = useFeedbackStore();
  const [selectedType, setSelectedType] = useState<IncidentType | null>(null);
  const [description, setDescription] = useState('');

  const handleSubmit = () => {
    if (!selectedType) { Alert.alert('Please select an issue type'); return; }
    if (!description.trim()) { Alert.alert('Please describe the issue'); return; }
    submitIncident({
      orderId,
      userId: user?.id ?? '',
      type: selectedType,
      description: description.trim(),
    });
    Alert.alert(
      'Issue Reported',
      'We\'ll review your report and get back to you shortly. You\'ll receive a notification when it\'s resolved.',
      [{ text: 'OK', onPress: onDone }],
    );
  };

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <Text style={s.title}>{'\u26A0\uFE0F'} Report an Issue</Text>
      <Text style={s.subtitle}>We're sorry something went wrong. Let us know what happened.</Text>

      <Text style={s.sectionLabel}>What went wrong?</Text>
      <View style={s.typeGrid}>
        {ISSUE_TYPES.map(({ type, icon }) => (
          <Pressable
            key={type}
            style={[s.typeCard, selectedType === type && s.typeCardActive]}
            onPress={() => setSelectedType(type)}
          >
            <Text style={s.typeIcon}>{icon}</Text>
            <Text style={[s.typeLabel, selectedType === type && s.typeLabelActive]}>
              {INCIDENT_LABELS[type]}
            </Text>
          </Pressable>
        ))}
      </View>

      <Text style={s.sectionLabel}>Describe the issue</Text>
      <TextInput
        style={s.input}
        value={description}
        onChangeText={setDescription}
        placeholder="Tell us what happened in detail..."
        placeholderTextColor={colors.textSecondary}
        multiline
        numberOfLines={4}
      />

      <View style={s.infoCard}>
        <Text style={s.infoIcon}>{'\uD83D\uDCA1'}</Text>
        <Text style={s.infoText}>
          Our team typically resolves issues within 30 minutes. You'll receive a notification with the resolution.
        </Text>
      </View>

      <Pressable
        style={[s.submitBtn, !selectedType && s.submitBtnDisabled]}
        onPress={handleSubmit}
        disabled={!selectedType}
      >
        <Text style={s.submitText}>Submit Report</Text>
      </Pressable>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginBottom: spacing.lg },
  sectionLabel: { fontSize: 15, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.sm, marginTop: spacing.md },
  typeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginBottom: spacing.md },
  typeCard: {
    width: '47%', backgroundColor: colors.cardBackground, borderRadius: radii.medium,
    padding: spacing.md, alignItems: 'center', borderWidth: 2, borderColor: 'transparent',
  },
  typeCardActive: { borderColor: colors.danger, backgroundColor: colors.danger + '08' },
  typeIcon: { fontSize: 28, marginBottom: 6 },
  typeLabel: { fontSize: 13, fontWeight: '600', color: colors.textSecondary, textAlign: 'center' },
  typeLabelActive: { color: colors.danger },
  input: {
    backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md,
    fontSize: 14, color: colors.textPrimary, minHeight: 100, textAlignVertical: 'top', marginBottom: spacing.md,
  },
  infoCard: {
    flexDirection: 'row', backgroundColor: '#EEF6FF', borderRadius: radii.medium,
    padding: spacing.md, marginBottom: spacing.lg, alignItems: 'flex-start',
  },
  infoIcon: { fontSize: 18, marginRight: spacing.sm },
  infoText: { fontSize: 13, color: '#2563EB', flex: 1, lineHeight: 19 },
  submitBtn: { backgroundColor: colors.danger, borderRadius: radii.button, padding: spacing.md, alignItems: 'center' },
  submitBtnDisabled: { opacity: 0.4 },
  submitText: { color: '#FFF', fontSize: 16, fontWeight: '700' },
});
