import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, TextInput, Alert, Share,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useGroupOrderStore } from '../../state/GroupOrderStore';
import { useAuthStore } from '../../state/AuthStore';
import { colors, spacing, radii } from '../../theme/theme';

export const GroupOrderScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const {
    activeGroup, createGroup, joinGroup, closeGroup, leaveGroup,
    getTotalForMember, getGroupTotal,
  } = useGroupOrderStore();
  const [joinCode, setJoinCode] = useState('');

  const handleCreate = () => {
    if (!user) return;
    const code = createGroup(user.id, user.name);
    Alert.alert('Group Created!', `Share code: ${code}`);
  };

  const handleJoin = () => {
    if (!user || !joinCode.trim()) return;
    const ok = joinGroup(joinCode.trim().toUpperCase(), user.id, user.name);
    if (ok) Alert.alert('Joined!', 'You\'re now part of the group order.');
    else Alert.alert('Error', 'Invalid or closed group code.');
    setJoinCode('');
  };

  const handleShare = async () => {
    if (!activeGroup) return;
    try {
      await Share.share({
        message: `Join my SmartFood group order! Code: ${activeGroup.shareCode}`,
      });
    } catch {}
  };

  if (!activeGroup) {
    return (
      <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
        <Text style={s.title}>{'\uD83D\uDC65'} Group Order</Text>
        <Text style={s.subtitle}>Order together, split the bill</Text>

        <View style={s.optionCard}>
          <Text style={s.optionIcon}>{'\uD83C\uDF89'}</Text>
          <Text style={s.optionTitle}>Start a Group</Text>
          <Text style={s.optionDesc}>Create a shared cart and invite friends</Text>
          <Pressable style={s.primaryBtn} onPress={handleCreate}>
            <Text style={s.primaryBtnText}>Create Group</Text>
          </Pressable>
        </View>

        <View style={s.divider}>
          <View style={s.dividerLine} />
          <Text style={s.dividerText}>or</Text>
          <View style={s.dividerLine} />
        </View>

        <View style={s.optionCard}>
          <Text style={s.optionIcon}>{'\uD83D\uDD17'}</Text>
          <Text style={s.optionTitle}>Join a Group</Text>
          <Text style={s.optionDesc}>Enter the group code to join</Text>
          <View style={s.joinRow}>
            <TextInput
              style={s.codeInput}
              value={joinCode}
              onChangeText={setJoinCode}
              placeholder="Enter code..."
              placeholderTextColor={colors.textSecondary}
              autoCapitalize="characters"
              maxLength={6}
            />
            <Pressable style={s.joinBtn} onPress={handleJoin}>
              <Text style={s.joinBtnText}>Join</Text>
            </Pressable>
          </View>
        </View>
      </ScrollView>
    );
  }

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <View style={s.activeHeader}>
        <View>
          <Text style={s.title}>{'\uD83D\uDC65'} Group Order</Text>
          <View style={s.codeBadge}>
            <Text style={s.codeLabel}>Code: </Text>
            <Text style={s.codeValue}>{activeGroup.shareCode}</Text>
          </View>
        </View>
        <Pressable style={s.shareBtn} onPress={handleShare}>
          <Text style={s.shareBtnText}>{'\uD83D\uDCE4'} Share</Text>
        </Pressable>
      </View>

      <View style={s.statusBanner}>
        <Text style={s.statusIcon}>{activeGroup.isOpen ? '\uD83D\uDFE2' : '\uD83D\uDD34'}</Text>
        <Text style={s.statusText}>
          {activeGroup.isOpen ? 'Open for members' : 'Group closed'}
        </Text>
        <Text style={s.memberCount}>{activeGroup.members.length} members</Text>
      </View>

      {activeGroup.members.map(member => (
        <View key={member.id} style={s.memberCard}>
          <View style={s.memberHeader}>
            <View style={s.memberAvatar}>
              <Text style={s.memberAvatarText}>{member.name[0]}</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={s.memberName}>
                {member.name}
                {member.id === activeGroup.hostId && (
                  <Text style={s.hostTag}> (Host)</Text>
                )}
              </Text>
              <Text style={s.memberItems}>{member.items.length} items</Text>
            </View>
            <Text style={s.memberTotal}>${member.subtotal.toFixed(2)}</Text>
          </View>

          {member.items.map(item => (
            <View key={item.id} style={s.itemRow}>
              <Text style={s.itemName}>{item.menuItem.name} × {item.quantity}</Text>
              <Text style={s.itemPrice}>${(item.menuItem.price * item.quantity).toFixed(2)}</Text>
            </View>
          ))}
        </View>
      ))}

      <View style={s.totalCard}>
        <Text style={s.totalLabel}>Group Total</Text>
        <Text style={s.totalValue}>${getGroupTotal().toFixed(2)}</Text>
      </View>

      <View style={s.actionRow}>
        {activeGroup.isOpen && user?.id === activeGroup.hostId && (
          <Pressable style={s.primaryBtn} onPress={closeGroup}>
            <Text style={s.primaryBtnText}>Close & Place Order</Text>
          </Pressable>
        )}
        <Pressable style={s.leaveBtn} onPress={() => { if (user) leaveGroup(user.id); }}>
          <Text style={s.leaveBtnText}>Leave Group</Text>
        </Pressable>
      </View>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  title: { fontSize: 26, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginTop: 4, marginBottom: spacing.lg },
  optionCard: { backgroundColor: colors.cardBackground, borderRadius: radii.large, padding: spacing.lg, alignItems: 'center', marginBottom: spacing.md },
  optionIcon: { fontSize: 40, marginBottom: spacing.sm },
  optionTitle: { fontSize: 18, fontWeight: '700', color: colors.textPrimary, marginBottom: 4 },
  optionDesc: { fontSize: 13, color: colors.textSecondary, marginBottom: spacing.md, textAlign: 'center' },
  primaryBtn: { backgroundColor: colors.accent, borderRadius: radii.button, paddingVertical: 14, paddingHorizontal: 32, alignItems: 'center', width: '100%' },
  primaryBtnText: { color: '#FFF', fontSize: 16, fontWeight: '700' },
  divider: { flexDirection: 'row', alignItems: 'center', marginVertical: spacing.md },
  dividerLine: { flex: 1, height: 1, backgroundColor: colors.border },
  dividerText: { marginHorizontal: spacing.md, fontSize: 13, color: colors.textSecondary, fontWeight: '600' },
  joinRow: { flexDirection: 'row', gap: spacing.sm, width: '100%' },
  codeInput: { flex: 1, backgroundColor: colors.background, borderRadius: radii.medium, paddingHorizontal: spacing.md, paddingVertical: 12, fontSize: 18, fontWeight: '700', textAlign: 'center', letterSpacing: 4, color: colors.textPrimary },
  joinBtn: { backgroundColor: colors.accent, borderRadius: radii.button, paddingHorizontal: 24, justifyContent: 'center' },
  joinBtnText: { color: '#FFF', fontSize: 15, fontWeight: '700' },
  activeHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: spacing.md },
  codeBadge: { flexDirection: 'row', marginTop: 6, alignItems: 'center' },
  codeLabel: { fontSize: 13, color: colors.textSecondary },
  codeValue: { fontSize: 16, fontWeight: '800', color: colors.accent, letterSpacing: 2 },
  shareBtn: { backgroundColor: colors.accent + '15', borderRadius: radii.button, paddingHorizontal: 16, paddingVertical: 10 },
  shareBtnText: { fontSize: 14, fontWeight: '700', color: colors.accent },
  statusBanner: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.md },
  statusIcon: { fontSize: 12, marginRight: spacing.sm },
  statusText: { fontSize: 14, fontWeight: '600', color: colors.textPrimary, flex: 1 },
  memberCount: { fontSize: 13, color: colors.textSecondary, fontWeight: '600' },
  memberCard: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.sm },
  memberHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  memberAvatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: colors.accent + '20', alignItems: 'center', justifyContent: 'center', marginRight: spacing.sm },
  memberAvatarText: { fontSize: 16, fontWeight: '700', color: colors.accent },
  memberName: { fontSize: 15, fontWeight: '700', color: colors.textPrimary },
  hostTag: { fontSize: 12, color: colors.accent, fontWeight: '600' },
  memberItems: { fontSize: 12, color: colors.textSecondary },
  memberTotal: { fontSize: 16, fontWeight: '800', color: colors.textPrimary },
  itemRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4, paddingLeft: 48 },
  itemName: { fontSize: 13, color: colors.textSecondary },
  itemPrice: { fontSize: 13, color: colors.textSecondary, fontWeight: '600' },
  totalCard: { flexDirection: 'row', justifyContent: 'space-between', backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginVertical: spacing.md },
  totalLabel: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  totalValue: { fontSize: 22, fontWeight: '900', color: colors.accent },
  actionRow: { gap: spacing.sm },
  leaveBtn: { borderWidth: 1.5, borderColor: colors.danger, borderRadius: radii.button, paddingVertical: 14, alignItems: 'center' },
  leaveBtnText: { color: colors.danger, fontSize: 15, fontWeight: '700' },
});
