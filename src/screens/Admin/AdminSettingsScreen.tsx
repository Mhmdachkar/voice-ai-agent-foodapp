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
import { colors, spacing, radii } from '../../theme/theme';
import { Card } from '../../theme/components/Card';
import { SectionHeader } from '../../theme/components/SectionHeader';

export const AdminSettingsScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user, signOut } = useAuthStore();
  const router = useRouter();

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
      <Text style={styles.title}>Settings</Text>

      {/* Profile */}
      <Card style={styles.profileCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{user?.name?.charAt(0) ?? 'A'}</Text>
        </View>
        <View style={styles.profileInfo}>
          <Text style={styles.profileName}>{user?.name ?? 'Admin'}</Text>
          <Text style={styles.profileEmail}>{user?.email ?? ''}</Text>
          <Text style={styles.profileRole}>Administrator</Text>
        </View>
      </Card>

      {/* Reports */}
      <View style={{ paddingHorizontal: spacing.lg }}>
        <SectionHeader title="Reports" />
      </View>
      {['Sales Report', 'Peak Hours', 'Driver Performance', 'Menu Analytics'].map(report => (
        <Card key={report} style={styles.menuItem}>
          <Text style={styles.menuItemText}>{report}</Text>
          <Text style={styles.menuItemArrow}>›</Text>
        </Card>
      ))}

      {/* Store Settings */}
      <View style={{ paddingHorizontal: spacing.lg }}>
        <SectionHeader title="Store Settings" />
      </View>
      {[
        { label: 'Operating Hours', value: '8:00 AM – 10:00 PM' },
        { label: 'Delivery Radius', value: '5 miles' },
        { label: 'Minimum Order', value: '$10.00' },
        { label: 'Tax Rate', value: '8.75%' },
      ].map(setting => (
        <Card key={setting.label} style={styles.menuItem}>
          <Text style={styles.menuItemText}>{setting.label}</Text>
          <Text style={styles.menuItemValue}>{setting.value}</Text>
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
  avatar: { width: 56, height: 56, borderRadius: 28, backgroundColor: colors.accent, justifyContent: 'center', alignItems: 'center', marginRight: spacing.md },
  avatarText: { fontSize: 24, fontWeight: '700', color: '#FFFFFF' },
  profileInfo: { flex: 1 },
  profileName: { fontSize: 18, fontWeight: '700', color: colors.textPrimary },
  profileEmail: { fontSize: 14, color: colors.textSecondary, marginTop: 2 },
  profileRole: { fontSize: 12, color: colors.accent, fontWeight: '600', marginTop: 4 },
  menuItem: { marginHorizontal: spacing.lg, marginBottom: spacing.sm, padding: spacing.md, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  menuItemText: { fontSize: 15, fontWeight: '600', color: colors.textPrimary },
  menuItemArrow: { fontSize: 20, color: colors.textSecondary },
  menuItemValue: { fontSize: 14, color: colors.textSecondary },
  signOutButton: { marginHorizontal: spacing.lg, marginTop: spacing.lg, padding: spacing.md, borderRadius: radii.medium, backgroundColor: colors.danger, alignItems: 'center' },
  signOutText: { fontSize: 16, fontWeight: '700', color: '#FFFFFF' },
});
