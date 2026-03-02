export const Platform = { OS: 'web' };
export const StyleSheet = { create: (s: any) => s };
export const Dimensions = { get: () => ({ width: 375, height: 812 }) };
export const View = 'View';
export const Text = 'Text';
export const Pressable = 'Pressable';
export const TextInput = 'TextInput';
export const FlatList = 'FlatList';
export const ScrollView = 'ScrollView';
export const Animated = {
  Value: jest.fn(),
  View: 'Animated.View',
  timing: jest.fn(),
  loop: jest.fn(),
  sequence: jest.fn(),
  parallel: jest.fn(),
  delay: jest.fn(),
  multiply: jest.fn(),
};
export const Easing = { inOut: jest.fn(), ease: {}, linear: {} };
export const KeyboardAvoidingView = 'KeyboardAvoidingView';
export const ActivityIndicator = 'ActivityIndicator';
