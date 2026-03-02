import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { TrendingUp } from 'lucide-react-native';

export interface PopularNowBadgeProps {
  ordersInLastHour: number;
}

export const PopularNowBadge: React.FC<PopularNowBadgeProps> = ({ ordersInLastHour }) => {
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(opacity, {
      toValue: 1,
      duration: 400,
      delay: 300,
      useNativeDriver: true,
    }).start();
  }, []);

  return (
    <Animated.View testID="popular-now-badge" style={[s.container, { opacity }]}>
      <View style={s.dot} />
      <TrendingUp size={13} color="#E74C3C" />
      <Text style={s.text}>{ordersInLastHour}+ ordered in the last hour</Text>
    </Animated.View>
  );
};

const s = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF0F0',
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 6,
    gap: 6,
    alignSelf: 'flex-start',
    marginBottom: 6,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#E74C3C',
  },
  text: {
    fontSize: 11,
    fontWeight: '600' as const,
    color: '#E74C3C',
  },
});
