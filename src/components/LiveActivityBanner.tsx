import React, { useEffect, useRef, useState } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { Flame, Users } from 'lucide-react-native';

const MESSAGES: { icon: 'flame' | 'users'; text: string }[] = [
  { icon: 'flame', text: '47 orders placed in the last 30 min' },
  { icon: 'users', text: '128 people browsing right now' },
  { icon: 'flame', text: 'Chicken Biryani is trending today' },
  { icon: 'flame', text: 'Double Smash Burger is almost sold out' },
];

export const LiveActivityBanner: React.FC = () => {
  const [index, setIndex] = useState(0);
  const opacity = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    const interval = setInterval(() => {
      Animated.timing(opacity, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }).start(() => {
        setIndex(prev => (prev + 1) % MESSAGES.length);
        Animated.timing(opacity, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }).start();
      });
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  const msg = MESSAGES[index];
  const Icon = msg.icon === 'users' ? Users : Flame;

  return (
    <View testID="live-activity-banner" style={s.container}>
      <Animated.View style={[s.inner, { opacity }]}>
        <Icon size={16} color="#666" />
        <Text style={s.text}>{msg.text}</Text>
      </Animated.View>
      <View style={s.liveDot} />
    </View>
  );
};

const s = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F2F2F7',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginBottom: 16,
  },
  inner: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 8,
  },
  text: {
    fontSize: 13,
    fontWeight: '600' as const,
    color: '#444',
    flex: 1,
  },
  liveDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#2ECC71',
    marginLeft: 8,
  },
});
