import React from 'react';
import {
  ActivityIndicator,
  Pressable,
  Text,
  ViewStyle,
  StyleProp,
} from 'react-native';
import { colors, radii } from '../theme';

export interface ButtonProps {
  title: string;
  onPress: () => void;
  icon?: React.ReactNode;
  fullWidth?: boolean;
  loading?: boolean;
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
}

export const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  icon,
  fullWidth = true,
  loading = false,
  disabled = false,
  style,
}) => {
  const isDisabled = loading || disabled;
  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      style={({ pressed }) => [
        {
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'center',
          height: 52,
          paddingHorizontal: fullWidth ? 0 : 24,
          borderRadius: radii.button,
          backgroundColor: isDisabled ? colors.border : colors.accent,
          opacity: pressed ? 0.85 : isDisabled ? 0.6 : 1,
          alignSelf: fullWidth ? 'stretch' : 'auto',
        },
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color="#FFFFFF" />
      ) : (
        <>
          {icon}
          <Text
            style={{
              color: '#FFFFFF',
              fontWeight: '700',
              marginLeft: icon ? 8 : 0,
            }}
          >
            {title}
          </Text>
        </>
      )}
    </Pressable>
  );
};

