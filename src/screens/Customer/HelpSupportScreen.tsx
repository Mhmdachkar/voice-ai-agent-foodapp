import React from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, Linking, Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { colors, spacing, radii } from '../../theme/theme';

const HELP_ITEMS = [
  { icon: '\uD83D\uDCDE', title: 'Contact Support', desc: 'Call our 24/7 support line', action: 'phone' },
  { icon: '\uD83D\uDCE7', title: 'Email Us', desc: 'support@smartfood.com', action: 'email' },
  { icon: '\uD83D\uDCAC', title: 'Live Chat', desc: 'Chat with our support team', action: 'chat' },
  { icon: '\u2753', title: 'FAQ', desc: 'Frequently asked questions', action: 'faq' },
  { icon: '\uD83D\uDCDC', title: 'Terms of Service', desc: 'Read our terms & conditions', action: 'terms' },
  { icon: '\uD83D\uDD12', title: 'Privacy Policy', desc: 'How we protect your data', action: 'privacy' },
  { icon: '\uD83D\uDC1B', title: 'Report a Bug', desc: 'Help us improve the app', action: 'bug' },
  { icon: '\u2139\uFE0F', title: 'About SmartFood', desc: 'Version 1.0.0', action: 'about' },
];

export const HelpSupportScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const handlePress = (action: string) => {
    switch (action) {
      case 'phone':
        Linking.openURL('tel:+15551234567').catch(() => Alert.alert('Error', 'Cannot open phone dialer'));
        break;
      case 'email':
        Linking.openURL('mailto:support@smartfood.com').catch(() => Alert.alert('Error', 'Cannot open email client'));
        break;
      case 'chat':
        Alert.alert('Live Chat', 'Live chat feature coming soon! In the meantime, use the Voice AI assistant from the home screen.');
        break;
      case 'faq':
        Alert.alert('FAQ', 'How to place an order?\nBrowse the menu, add items to cart, and proceed to checkout.\n\nHow to track my order?\nGo to Orders tab and tap any active order.\n\nHow to cancel an order?\nContact support within 5 minutes of placing.');
        break;
      case 'terms':
        Alert.alert('Terms of Service', 'By using SmartFood, you agree to our terms of service. Full terms available at smartfood.com/terms');
        break;
      case 'privacy':
        Alert.alert('Privacy Policy', 'We take your privacy seriously. Your data is encrypted and never shared with third parties without consent.');
        break;
      case 'bug':
        Alert.alert('Report a Bug', 'Thank you for helping us improve! Please describe the issue at support@smartfood.com with subject "Bug Report".');
        break;
      case 'about':
        Alert.alert('About SmartFood', 'SmartFood Delivery v1.0.0\nAI-powered food delivery platform\n\nBuilt with React Native & Supabase');
        break;
    }
  };

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <View style={s.header}>
        <Pressable onPress={() => router.back()}>
          <Text style={s.backBtn}>{'\u2190'}</Text>
        </Pressable>
        <Text style={s.headerTitle}>Help & Support</Text>
        <View style={{ width: 24 }} />
      </View>

      <View style={s.heroCard}>
        <Text style={s.heroIcon}>{'\uD83D\uDE4B'}</Text>
        <Text style={s.heroTitle}>How can we help?</Text>
        <Text style={s.heroDesc}>We're here for you 24/7. Choose an option below.</Text>
      </View>

      {HELP_ITEMS.map(item => (
        <Pressable key={item.action} style={s.card} onPress={() => handlePress(item.action)}>
          <View style={s.iconCircle}>
            <Text style={s.icon}>{item.icon}</Text>
          </View>
          <View style={s.cardBody}>
            <Text style={s.cardTitle}>{item.title}</Text>
            <Text style={s.cardDesc}>{item.desc}</Text>
          </View>
          <Text style={s.arrow}>{'\u203A'}</Text>
        </Pressable>
      ))}
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: spacing.lg },
  backBtn: { fontSize: 24, color: colors.textPrimary },
  headerTitle: { fontSize: 20, fontWeight: '800', color: colors.textPrimary },
  heroCard: { backgroundColor: colors.accent, borderRadius: radii.large, padding: spacing.lg, alignItems: 'center', marginBottom: spacing.lg },
  heroIcon: { fontSize: 40, marginBottom: spacing.sm },
  heroTitle: { fontSize: 22, fontWeight: '800', color: '#FFF' },
  heroDesc: { fontSize: 14, color: '#FFF', opacity: 0.9, marginTop: 4 },
  card: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.sm },
  iconCircle: { width: 44, height: 44, borderRadius: 22, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center', marginRight: spacing.sm },
  icon: { fontSize: 20 },
  cardBody: { flex: 1 },
  cardTitle: { fontSize: 15, fontWeight: '700', color: colors.textPrimary },
  cardDesc: { fontSize: 12, color: colors.textSecondary, marginTop: 2 },
  arrow: { fontSize: 22, color: colors.textSecondary },
});
