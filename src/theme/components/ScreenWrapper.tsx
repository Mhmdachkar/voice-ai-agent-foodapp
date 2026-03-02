import React from 'react';
import { View, StyleSheet, StatusBar, Platform } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors } from '../theme';

interface ScreenWrapperProps {
  children: React.ReactNode;
  bg?: string;
  noPadding?: boolean;
}

export const ScreenWrapper: React.FC<ScreenWrapperProps> = ({
  children,
  bg = colors.background,
  noPadding = false,
}) => {
  const insets = useSafeAreaInsets();

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: bg,
          paddingTop: noPadding ? insets.top : insets.top + 8,
          paddingBottom: noPadding ? 0 : insets.bottom,
        },
      ]}
    >
      <StatusBar barStyle="dark-content" backgroundColor={bg} />
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
