import React from 'react';
import { FeedbackScreen } from '../../src/screens/Customer/FeedbackScreen';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function FeedbackPage() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  return <FeedbackScreen orderId={orderId ?? ''} onDone={() => router.back()} />;
}
