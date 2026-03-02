import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useAuthStore } from '../../state/AuthStore';
import { useDataStore } from '../../state/DataStore';
import { colors, spacing, radii } from '../../theme/theme';
import { Card } from '../../theme/components/Card';
import { SectionHeader } from '../../theme/components/SectionHeader';

export const DriverProfileScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user, signOut } = useAuthStore();
  const { ordersForDriver } = useDataStore();
  const router = useRouter();

  const driverOrders = user ? ordersForDriver(user.id) : [];
  const delivered = driverOrders.filter(o => o.status === 'DELIVERED');
  const totalDeliveries = delivered.length;
  const avgRating = 4.8; // placeholder
  const onTimeRate = 95; // placeholder

  const handleSignOut = () => {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign Out',
        style: 'destructive',
        onPress: async () => {
          await signOut();
          router.replace('/auth/login');
        },
      },
    ]);
  };

  return (
    <ScrollView style={[styles.container, { paddingTop: insets.top }]}>
      <Text style={styles.title}>Profile</Text>

      {/* Driver Info */}
      <Card style={styles.profileCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{user?.name?.charAt(0) ?? 'D'}</Text>
        </View>
        <View style={styles.profileInfo}>
          <Text style={styles.profileName}>{user?.name ?? 'Driver'}</Text>
          <Text style={styles.profileEmail}>{user?.email ?? ''}</Text>
        </View>
      </Card>

      {/* Performance Stats */}
      <View style={{ paddingHorizontal: spacing.lg }}>
        <SectionHeader title="Performance" />
      </View>
      <View style={styles.statsRow}>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{totalDeliveries}</Text>
          <Text style={styles.statLabel}>Deliveries</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{avgRating}</Text>
          <Text style={styles.statLabel}>Rating</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{onTimeRate}%</Text>
          <Text style={styles.statLabel}>On Time</Text>
        </Card>
      </View>

      {/* Vehicle Info */}
      <View style={{ paddingHorizontal: spacing.lg }}>
        <SectionHeader title="Vehicle Information" />
      </View>
      <Card style={styles.infoCard}>
        {[
          { label: 'Vehicle', value: 'Honda Civic 2022' },
          { label: 'License Plate', value: 'ABC-1234' },
          { label: 'Insurance', value: 'Active' },
          { label: 'Background Check', value: 'Verified' },
        ].map(item => (
          <View key={item.label} style={styles.infoRow}>
            <Text style={styles.infoLabel}>{item.label}</Text>
            <Text style={styles.infoValue}>{item.value}</Text>
          </View>
        ))}
      </Card>

      {/* Help */}
      <View style={{ paddingHorizontal: spacing.lg }}>
        <SectionHeader title="Support" />
      </View>
      {['Help Center', 'Contact Support', 'Report an Issue'].map(item => (
        <Card key={item} style={styles.menuItem}>
          <Text style={styles.menuItemText}>{item}</Text>
          <Text style={styles.menuItemArrow}>›</Text>
        </Card>
      ))}

      {/* Sign Out */}
      <Pressable style={styles.signOutButton} onPress={handleSignOut}>
        <Text style={styles.signOutText}>Sign Out</Text>
      </Pressable>

      <View style={{ height: spacing.xl }} />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary, paddingHorizontal: spacing.lg, paddingTop: spacing.lg, paddingBottom: spacing.md },
  profileCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.lg, flexDirection: 'row', alignItems: 'center' },
  avatar: { width: 64, height: 64, borderRadius: 32, backgroundColor: colors.accent, justifyContent: 'center', alignItems: 'center', marginRight: spacing.md },
  avatarText: { fontSize: 28, fontWeight: '700', color: '#FFFFFF' },
  profileInfo: { flex: 1 },
  profileName: { fontSize: 20, fontWeight: '700', color: colors.textPrimary },
  profileEmail: { fontSize: 14, color: colors.textSecondary, marginTop: 2 },
  statsRow: { flexDirection: 'row', paddingHorizontal: spacing.lg, gap: spacing.sm, marginBottom: spacing.md },
  statCard: { flex: 1, padding: spacing.md, alignItems: 'center' },
  statValue: { fontSize: 22, fontWeight: '800', color: colors.accent },
  statLabel: { fontSize: 12, color: colors.textSecondary, marginTop: 4 },
  infoCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.md },
  infoRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: spacing.sm, borderBottomWidth: 1, borderBottomColor: colors.border },
  infoLabel: { fontSize: 14, fontWeight: '600', color: colors.textPrimary },
  infoValue: { fontSize: 14, color: colors.textSecondary },
  menuItem: { marginHorizontal: spacing.lg, marginBottom: spacing.sm, padding: spacing.md, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  menuItemText: { fontSize: 15, fontWeight: '600', color: colors.textPrimary },
  menuItemArrow: { fontSize: 20, color: colors.textSecondary },
  signOutButton: { marginHorizontal: spacing.lg, marginTop: spacing.lg, padding: spacing.md, borderRadius: radii.medium, backgroundColor: colors.danger, alignItems: 'center' },
  signOutText: { fontSize: 16, fontWeight: '700', color: '#FFFFFF' },
});
