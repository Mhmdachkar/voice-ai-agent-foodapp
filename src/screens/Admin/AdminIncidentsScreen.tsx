import React, { useEffect } from 'react';
import {
  View, Text, StyleSheet, FlatList, Pressable, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useFeedbackStore } from '../../state/FeedbackStore';
import { INCIDENT_LABELS, RESOLUTION_LABELS } from '../../models/Feedback';
import type { OrderIncident, ResolutionType } from '../../models/Feedback';
import { colors, spacing, radii } from '../../theme/theme';

const RESOLUTIONS: { type: ResolutionType; icon: string }[] = [
  { type: 'refund_item', icon: '\uD83D\uDCB0' },
  { type: 'resend_item', icon: '\uD83D\uDE9A' },
  { type: 'apply_credit', icon: '\uD83C\uDF81' },
  { type: 'full_refund', icon: '\uD83D\uDCB3' },
];

const IncidentCard: React.FC<{ incident: OrderIncident; onResolve: (id: string, res: ResolutionType) => void }> = ({ incident, onResolve }) => {
  const isResolved = incident.status === 'resolved';

  const handleResolve = (res: ResolutionType) => {
    Alert.alert(
      'Resolve Incident',
      `Apply "${RESOLUTION_LABELS[res]}" for this issue?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Confirm', onPress: () => onResolve(incident.id, res) },
      ],
    );
  };

  return (
    <View style={[s.card, isResolved && s.cardResolved]}>
      <View style={s.cardHeader}>
        <View style={[s.statusBadge, { backgroundColor: isResolved ? colors.success + '20' : colors.danger + '20' }]}>
          <Text style={[s.statusText, { color: isResolved ? colors.success : colors.danger }]}>
            {isResolved ? 'Resolved' : 'Open'}
          </Text>
        </View>
        <Text style={s.cardTime}>
          {new Date(incident.createdAt).toLocaleDateString()}
        </Text>
      </View>

      <View style={s.cardBody}>
        <Text style={s.cardType}>{INCIDENT_LABELS[incident.type]}</Text>
        <Text style={s.cardDesc}>{incident.description}</Text>
        <Text style={s.cardOrder}>Order #{incident.orderId.slice(0, 8)}</Text>
      </View>

      {isResolved && incident.resolution && (
        <View style={s.resolutionBanner}>
          <Text style={s.resolutionIcon}>{'\u2705'}</Text>
          <Text style={s.resolutionText}>{RESOLUTION_LABELS[incident.resolution]}</Text>
        </View>
      )}

      {!isResolved && (
        <View style={s.actionsRow}>
          {RESOLUTIONS.map(({ type, icon }) => (
            <Pressable key={type} style={s.actionBtn} onPress={() => handleResolve(type)}>
              <Text style={s.actionIcon}>{icon}</Text>
              <Text style={s.actionLabel}>{RESOLUTION_LABELS[type]}</Text>
            </Pressable>
          ))}
        </View>
      )}
    </View>
  );
};

export const AdminIncidentsScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { incidents, isLoaded, load, resolveIncident, getColdFoodAlerts } = useFeedbackStore();

  useEffect(() => { if (!isLoaded) load(); }, [isLoaded, load]);

  const coldAlerts = getColdFoodAlerts();
  const sortedIncidents = [...incidents].sort((a, b) => {
    if (a.status === 'open' && b.status !== 'open') return -1;
    if (a.status !== 'open' && b.status === 'open') return 1;
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });

  const handleResolve = (id: string, res: ResolutionType) => {
    resolveIncident(id, res, 'Resolved by admin');
  };

  return (
    <View style={[s.container, { paddingTop: insets.top }]}>
      <Text style={s.title}>{'\uD83D\uDEA8'} Incident Queue</Text>

      {coldAlerts.length > 0 && (
        <View style={s.alertBanner}>
          <Text style={s.alertIcon}>{'\u26A0\uFE0F'}</Text>
          <Text style={s.alertText}>
            Cold food reported 3+ times for: {coldAlerts.map(a => a.itemName).join(', ')}
          </Text>
        </View>
      )}

      <FlatList
        data={sortedIncidents}
        keyExtractor={i => i.id}
        renderItem={({ item }) => <IncidentCard incident={item} onResolve={handleResolve} />}
        contentContainerStyle={{ padding: spacing.md, paddingBottom: 100 }}
        ListEmptyComponent={
          <View style={s.empty}>
            <Text style={s.emptyIcon}>{'\u2705'}</Text>
            <Text style={s.emptyText}>No incidents to review</Text>
          </View>
        }
      />
    </View>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary, padding: spacing.md, paddingBottom: spacing.sm },
  alertBanner: { flexDirection: 'row', backgroundColor: '#FFF3CD', borderRadius: radii.medium, padding: spacing.md, marginHorizontal: spacing.md, marginBottom: spacing.sm, alignItems: 'center' },
  alertIcon: { fontSize: 18, marginRight: spacing.sm },
  alertText: { fontSize: 13, color: '#856404', flex: 1, fontWeight: '600' },
  card: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.sm },
  cardResolved: { opacity: 0.7 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.sm },
  statusBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12 },
  statusText: { fontSize: 12, fontWeight: '700' },
  cardTime: { fontSize: 12, color: colors.textSecondary },
  cardBody: { marginBottom: spacing.sm },
  cardType: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  cardDesc: { fontSize: 14, color: colors.textSecondary, marginTop: 4 },
  cardOrder: { fontSize: 12, color: colors.textSecondary, marginTop: 4 },
  resolutionBanner: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.success + '10', borderRadius: radii.small, padding: spacing.sm },
  resolutionIcon: { fontSize: 14, marginRight: spacing.xs },
  resolutionText: { fontSize: 13, color: colors.success, fontWeight: '600' },
  actionsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  actionBtn: { backgroundColor: colors.background, borderRadius: radii.small, paddingHorizontal: 10, paddingVertical: 8, alignItems: 'center', minWidth: 75 },
  actionIcon: { fontSize: 16, marginBottom: 2 },
  actionLabel: { fontSize: 10, color: colors.textSecondary, fontWeight: '600', textAlign: 'center' },
  empty: { alignItems: 'center', paddingTop: 80 },
  emptyIcon: { fontSize: 48, marginBottom: spacing.sm },
  emptyText: { fontSize: 16, color: colors.textSecondary, fontWeight: '600' },
});
