import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { colors } from '../theme';

interface DividerProps {
  orientation?: 'horizontal' | 'vertical';
  color?: string;
  thickness?: number;
  spacing?: number;
  style?: ViewStyle;
}

export const Divider: React.FC<DividerProps> = ({
  orientation = 'horizontal',
  color = colors.border,
  thickness = 1,
  spacing = 0,
  style,
}) => {
  const isHorizontal = orientation === 'horizontal';

  return (
    <View
      style={[
        styles.divider,
        {
          backgroundColor: color,
          [isHorizontal ? 'height' : 'width']: thickness,
          [isHorizontal ? 'marginVertical' : 'marginHorizontal']: spacing,
        },
        style,
      ]}
    />
  );
};

const styles = StyleSheet.create({
  divider: {
    alignSelf: 'stretch',
  },
});
