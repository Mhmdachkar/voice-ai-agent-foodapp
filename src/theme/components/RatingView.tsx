import React from 'react';
import { View, Text, StyleSheet, ViewStyle, StyleProp } from 'react-native';
import { colors, spacing } from '../theme';

interface RatingViewProps {
  rating: number;
  reviewCount?: number;
  size?: 'small' | 'medium';
  style?: StyleProp<ViewStyle>;
}

export const RatingView: React.FC<RatingViewProps> = ({
  rating,
  reviewCount,
  size = 'medium',
  style,
}) => {
  const starSize = size === 'small' ? 12 : 16;
  const textSize = size === 'small' ? 12 : 14;
  const fullStars = Math.floor(rating);
  const halfStar = rating - fullStars >= 0.5;
  const emptyStars = 5 - fullStars - (halfStar ? 1 : 0);

  return (
    <View style={[styles.container, style]}>
      <Text style={{ fontSize: starSize }}>
        {'★'.repeat(fullStars)}
        {halfStar ? '½' : ''}
        {'☆'.repeat(emptyStars)}
      </Text>
      <Text style={[styles.ratingText, { fontSize: textSize }]}>{rating.toFixed(1)}</Text>
      {reviewCount !== undefined && (
        <Text style={[styles.countText, { fontSize: textSize - 2 }]}>({reviewCount})</Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  ratingText: {
    fontWeight: '600',
    color: colors.textPrimary,
  },
  countText: {
    color: colors.textSecondary,
  },
});
