import { Slot } from 'expo-router';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import React from 'react';
import { ErrorBoundary } from '../src/components/ErrorBoundary';
import { RecentlyViewedProvider } from '../src/providers/RecentlyViewedProvider';

export default function RootLayout() {
  return (
    <ErrorBoundary>
      <SafeAreaProvider>
        <RecentlyViewedProvider>
          <Slot />
        </RecentlyViewedProvider>
      </SafeAreaProvider>
    </ErrorBoundary>
  );
}

