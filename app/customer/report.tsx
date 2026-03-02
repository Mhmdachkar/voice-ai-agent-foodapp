import React from 'react';
import { ReportIssueScreen } from '../../src/screens/Customer/ReportIssueScreen';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function ReportIssuePage() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  return <ReportIssueScreen orderId={orderId ?? ''} onDone={() => router.back()} />;
}
