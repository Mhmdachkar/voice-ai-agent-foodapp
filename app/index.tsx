import React, { useEffect } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { Redirect, useRouter } from 'expo-router';
import { useAuthStore } from '../src/state/AuthStore';

export default function Index() {
  const { user, role, isLoading, initialize } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    initialize();
  }, [initialize]);

  useEffect(() => {
    if (!isLoading && user && role) {
      if (role === 'customer') {
        router.replace('/customer/home');
      } else if (role === 'admin') {
        router.replace('/admin/dashboard');
      } else if (role === 'driver') {
        router.replace('/driver/available');
      }
    }
  }, [isLoading, user, role, router]);

  if (isLoading) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  if (!user || !role) {
    return <Redirect href="/auth/login" />;
  }

  // If we get here, the role-based redirect effect will run.
  return null;
}

