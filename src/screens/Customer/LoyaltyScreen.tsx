import React, { useEffect, useRef } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Animated, Easing, Pressable,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useLoyaltyStore } from '../../state/LoyaltyStore';
import { useAuthStore } from '../../state/AuthStore';
import { TIER_LABELS, TIER_COLORS, TIER_PERKS, pointsToNextTier } from '../../models/Loyalty';
import { colors, spacing, radii } from '../../theme/theme';

const TierBadge: React.FC<{ tier: string; color: string }> = ({ tier, color }) => (
  <View style={[s.tierBadge, { backgroundColor: color + '20', borderColor: color }]}>
    <Text style={[s.tierBadgeText, { color }]}>{tier}</Text>
  </View>
);

export const LoyaltyScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const { profile, isLoaded, load, getProgress } = useLoyaltyStore();
  const progressAnim = useRef(new Animated.Value(0)).current;
  const fadeIn = useRef(new Animated.Value(0)).current;

  useEffect(() => { if (!isLoaded) load(); }, [isLoaded, load]);

  const progress = getProgress();

  useEffect(() => {
    Animated.parallel([
      Animated.timing(progressAnim, { toValue: progress.percent, duration: 1200, easing: Easing.out(Easing.exp), useNativeDriver: false }),
      Animated.timing(fadeIn, { toValue: 1, duration: 600, useNativeDriver: true }),
    ]).start();
  }, [progress.percent]);

  const tierColor = TIER_COLORS[profile.tier];

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <Animated.View style={{ opacity: fadeIn }}>
        {/* Header */}
        <View style={s.header}>
          <Text style={s.title}>{'\uD83C\uDFC6'} Rewards</Text>
          <TierBadge tier={TIER_LABELS[profile.tier]} color={tierColor} />
        </View>

        {/* Points Card */}
        <View style={[s.pointsCard, { borderColor: tierColor + '40' }]}>
          <View style={s.pointsTop}>
            <View>
              <Text style={s.pointsLabel}>Your Points</Text>
              <Text style={[s.pointsValue, { color: tierColor }]}>{profile.points.toLocaleString()}</Text>
            </View>
            <View style={[s.tierCircle, { backgroundColor: tierColor }]}>
              <Text style={s.tierCircleText}>{TIER_LABELS[profile.tier][0]}</Text>
            </View>
          </View>

          {/* Progress Bar */}
          {progress.nextTier && (
            <View style={s.progressSection}>
              <View style={s.progressTrack}>
                <Animated.View style={[s.progressFill, {
                  backgroundColor: tierColor,
                  width: progressAnim.interpolate({ inputRange: [0, 1], outputRange: ['0%', '100%'] }),
                }]} />
              </View>
              <Text style={s.progressText}>
                {progress.needed} pts to {TIER_LABELS[progress.nextTier]}
              </Text>
            </View>
          )}
          {!progress.nextTier && (
            <Text style={[s.progressText, { marginTop: spacing.sm }]}>{'\u2728'} You've reached the highest tier!</Text>
          )}
        </View>

        {/* Streak */}
        <View style={s.streakCard}>
          <Text style={s.streakIcon}>{'\uD83D\uDD25'}</Text>
          <View style={{ flex: 1 }}>
            <Text style={s.streakTitle}>
              {profile.currentStreak} Week Streak
            </Text>
            <Text style={s.streakSub}>
              {profile.currentStreak >= 4
                ? 'Free delivery earned!'
                : `${4 - profile.currentStreak} more weeks for free delivery`}
            </Text>
          </View>
          <View style={s.streakDots}>
            {[1, 2, 3, 4].map(i => (
              <View key={i} style={[s.streakDot, i <= profile.currentStreak && { backgroundColor: colors.accent }]} />
            ))}
          </View>
        </View>

        {/* Stats */}
        <View style={s.statsRow}>
          <View style={s.statCard}>
            <Text style={s.statValue}>{profile.totalOrders}</Text>
            <Text style={s.statLabel}>Orders</Text>
          </View>
          <View style={s.statCard}>
            <Text style={s.statValue}>{profile.longestStreak}</Text>
            <Text style={s.statLabel}>Best Streak</Text>
          </View>
          <View style={s.statCard}>
            <Text style={s.statValue}>{profile.freeDeliveryEarned ? 'Yes' : 'No'}</Text>
            <Text style={s.statLabel}>Free Delivery</Text>
          </View>
        </View>

        {/* Tier Perks */}
        <Text style={s.sectionTitle}>Your Perks</Text>
        {TIER_PERKS[profile.tier].map((perk, i) => (
          <View key={i} style={s.perkRow}>
            <Text style={s.perkCheck}>{'\u2705'}</Text>
            <Text style={s.perkText}>{perk}</Text>
          </View>
        ))}

        {/* All Tiers */}
        <Text style={[s.sectionTitle, { marginTop: spacing.lg }]}>All Tiers</Text>
        {(['bronze', 'silver', 'gold'] as const).map(t => (
          <View key={t} style={[s.tierRow, profile.tier === t && { borderColor: TIER_COLORS[t], borderWidth: 2 }]}>
            <View style={[s.tierDot, { backgroundColor: TIER_COLORS[t] }]} />
            <View style={{ flex: 1 }}>
              <Text style={s.tierRowName}>{TIER_LABELS[t]}</Text>
              <Text style={s.tierRowPerks}>{TIER_PERKS[t].join(' · ')}</Text>
            </View>
            {profile.tier === t && <Text style={s.currentTag}>Current</Text>}
          </View>
        ))}
      </Animated.View>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.md },
  title: { fontSize: 28, fontWeight: '800', color: colors.textPrimary },
  tierBadge: { paddingHorizontal: 14, paddingVertical: 6, borderRadius: 20, borderWidth: 1.5 },
  tierBadgeText: { fontSize: 13, fontWeight: '700' },
  pointsCard: { backgroundColor: colors.cardBackground, borderRadius: radii.large, padding: spacing.lg, marginBottom: spacing.md, borderWidth: 1 },
  pointsTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  pointsLabel: { fontSize: 14, color: colors.textSecondary, fontWeight: '600' },
  pointsValue: { fontSize: 42, fontWeight: '900', marginTop: 4 },
  tierCircle: { width: 48, height: 48, borderRadius: 24, alignItems: 'center', justifyContent: 'center' },
  tierCircleText: { fontSize: 22, fontWeight: '900', color: '#FFF' },
  progressSection: { marginTop: spacing.md },
  progressTrack: { height: 8, backgroundColor: colors.border, borderRadius: 4, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 4 },
  progressText: { fontSize: 12, color: colors.textSecondary, marginTop: 6, fontWeight: '600' },
  streakCard: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  streakIcon: { fontSize: 32, marginRight: spacing.sm },
  streakTitle: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  streakSub: { fontSize: 13, color: colors.textSecondary, marginTop: 2 },
  streakDots: { flexDirection: 'row', gap: 6 },
  streakDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: colors.border },
  statsRow: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.lg },
  statCard: { flex: 1, backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, alignItems: 'center' },
  statValue: { fontSize: 22, fontWeight: '800', color: colors.textPrimary },
  statLabel: { fontSize: 11, color: colors.textSecondary, fontWeight: '600', marginTop: 4 },
  sectionTitle: { fontSize: 18, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.sm },
  perkRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  perkCheck: { fontSize: 16, marginRight: spacing.sm },
  perkText: { fontSize: 14, color: colors.textPrimary, flex: 1 },
  tierRow: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm, borderWidth: 1, borderColor: 'transparent' },
  tierDot: { width: 12, height: 12, borderRadius: 6, marginRight: spacing.sm },
  tierRowName: { fontSize: 15, fontWeight: '700', color: colors.textPrimary },
  tierRowPerks: { fontSize: 12, color: colors.textSecondary, marginTop: 2 },
  currentTag: { fontSize: 11, fontWeight: '700', color: colors.accent, backgroundColor: colors.accent + '15', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 8 },
});
