import React, { useEffect, useRef } from 'react';
import { Animated, StyleSheet, ViewStyle } from 'react-native';
import { radii } from '../theme';

interface SkeletonProps {
  style?: ViewStyle;
}

export const Skeleton: React.FC<SkeletonProps> = ({ style }) => {
  const translateX = useRef(new Animated.Value(-200)).current;

  useEffect(() => {
    Animated.loop(
      Animated.timing(translateX, {
        toValue: 200,
        duration: 1500,
        useNativeDriver: true,
      }),
    ).start();
  }, [translateX]);

  return (
    <Animated.View style={[styles.base, style]}>
      <Animated.View
        style={[
          styles.shimmer,
          {
            transform: [{ translateX }],
          },
        ]}
      />
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  base: {
    overflow: 'hidden',
    borderRadius: radii.small,
    backgroundColor: 'rgba(0,0,0,0.05)',
  },
  shimmer: {
    width: 200,
    height: '100%',
    backgroundColor: 'rgba(255,255,255,0.3)',
  },
});

