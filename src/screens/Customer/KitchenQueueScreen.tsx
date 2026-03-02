import React, { useEffect, useRef } from 'react';
import {
  View, Text, StyleSheet, Animated, Easing,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useKitchenQueueStore } from '../../state/KitchenQueueStore';
import { STAGE_LABELS, STAGE_ICONS, STAGE_PROGRESS } from '../../models/KitchenQueue';
import type { KitchenStage } from '../../models/KitchenQueue';
import { colors, spacing, radii } from '../../theme/theme';

const STAGES: KitchenStage[] = ['queued', 'preparing', 'cooking', 'plating', 'ready'];

const StageIndicator: React.FC<{ stage: KitchenStage; currentStage: KitchenStage }> = ({ stage, currentStage }) => {
  const currentIdx = STAGES.indexOf(currentStage);
  const stageIdx = STAGES.indexOf(stage);
  const isComplete = stageIdx < currentIdx;
  const isCurrent = stageIdx === currentIdx;

  return (
    <View style={st.stageItem}>
      <View style={[
        st.stageCircle,
        isComplete && st.stageComplete,
        isCurrent && st.stageCurrent,
      ]}>
        <Text style={st.stageCircleText}>
          {isComplete ? '\u2713' : STAGE_ICONS[stage]}
        </Text>
      </View>
      <Text style={[st.stageLabel, (isComplete || isCurrent) && st.stageLabelActive]}>
        {STAGE_LABELS[stage]}
      </Text>
      {stageIdx < STAGES.length - 1 && (
        <View style={[st.stageLine, isComplete && st.stageLineComplete]} />
      )}
    </View>
  );
};

export const KitchenQueueView: React.FC<{ orderId: string }> = ({ orderId }) => {
  const { getPositionForOrder } = useKitchenQueueStore();
  const queueItem = getPositionForOrder(orderId);
  const progressAnim = useRef(new Animated.Value(0)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    if (!queueItem) return;
    const progress = STAGE_PROGRESS[queueItem.stage];
    Animated.timing(progressAnim, {
      toValue: progress,
      duration: 800,
      easing: Easing.out(Easing.exp),
      useNativeDriver: false,
    }).start();

    if (queueItem.stage !== 'ready') {
      const pulse = Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, { toValue: 1.05, duration: 1000, useNativeDriver: true }),
          Animated.timing(pulseAnim, { toValue: 1, duration: 1000, useNativeDriver: true }),
        ]),
      );
      pulse.start();
      return () => pulse.stop();
    }
  }, [queueItem?.stage]);

  if (!queueItem) {
    return (
      <View style={st.container}>
        <View style={st.card}>
          <Text style={st.noQueue}>{'\uD83C\uDF73'} Your order is being processed</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={st.container}>
      <Animated.View style={[st.card, { transform: [{ scale: pulseAnim }] }]}>
        <View style={st.header}>
          <View>
            <Text style={st.title}>{'\uD83C\uDF73'} Kitchen Status</Text>
            <Text style={st.positionText}>
              Queue position: <Text style={st.positionBold}>#{queueItem.position}</Text>
            </Text>
          </View>
          <View style={st.etaBadge}>
            <Text style={st.etaIcon}>{'\u23F1\uFE0F'}</Text>
            <Text style={st.etaText}>~{queueItem.estimatedMinutes} min</Text>
          </View>
        </View>

        {/* Progress Bar */}
        <View style={st.progressTrack}>
          <Animated.View style={[st.progressFill, {
            width: progressAnim.interpolate({ inputRange: [0, 1], outputRange: ['0%', '100%'] }),
          }]} />
        </View>

        {/* Stage Indicators */}
        <View style={st.stagesRow}>
          {STAGES.map(stage => (
            <StageIndicator key={stage} stage={stage} currentStage={queueItem.stage} />
          ))}
        </View>

        {queueItem.stage === 'ready' && (
          <View style={st.readyBanner}>
            <Text style={st.readyText}>{'\u2705'} Your order is ready for pickup!</Text>
          </View>
        )}
      </Animated.View>
    </View>
  );
};

const st = StyleSheet.create({
  container: { marginBottom: spacing.md },
  card: {
    backgroundColor: colors.cardBackground, borderRadius: radii.large, padding: spacing.md,
    shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 12, shadowOffset: { width: 0, height: 4 }, elevation: 3,
  },
  noQueue: { fontSize: 15, color: colors.textSecondary, textAlign: 'center', paddingVertical: spacing.md },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: spacing.md },
  title: { fontSize: 17, fontWeight: '800', color: colors.textPrimary },
  positionText: { fontSize: 13, color: colors.textSecondary, marginTop: 4 },
  positionBold: { fontWeight: '800', color: colors.accent, fontSize: 15 },
  etaBadge: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.accent + '15', paddingHorizontal: 10, paddingVertical: 6, borderRadius: 14 },
  etaIcon: { fontSize: 14, marginRight: 4 },
  etaText: { fontSize: 13, fontWeight: '700', color: colors.accent },
  progressTrack: { height: 6, backgroundColor: colors.border, borderRadius: 3, overflow: 'hidden', marginBottom: spacing.md },
  progressFill: { height: '100%', backgroundColor: colors.accent, borderRadius: 3 },
  stagesRow: { flexDirection: 'row', justifyContent: 'space-between' },
  readyBanner: { backgroundColor: colors.success + '15', borderRadius: radii.small, padding: spacing.sm, marginTop: spacing.md, alignItems: 'center' },
  readyText: { fontSize: 14, fontWeight: '700', color: colors.success },
  stageItem: { alignItems: 'center', flex: 1, position: 'relative' },
  stageCircle: {
    width: 36, height: 36, borderRadius: 18, backgroundColor: colors.border,
    alignItems: 'center', justifyContent: 'center', marginBottom: 4,
  },
  stageComplete: { backgroundColor: colors.success },
  stageCurrent: { backgroundColor: colors.accent },
  stageCircleText: { fontSize: 16, color: '#FFF' },
  stageLabel: { fontSize: 10, color: colors.textSecondary, fontWeight: '600' },
  stageLabelActive: { color: colors.textPrimary, fontWeight: '700' },
  stageLine: {
    position: 'absolute', top: 18, left: '60%', width: '80%', height: 2,
    backgroundColor: colors.border, zIndex: -1,
  },
  stageLineComplete: { backgroundColor: colors.success },
});
