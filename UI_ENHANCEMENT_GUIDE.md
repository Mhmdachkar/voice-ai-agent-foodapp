# UI/UX Enhancement Guide - Food Delivery App

## Completed Improvements ✅

### 1. Theme System Upgrade
**File**: `src/theme/theme.ts`

**Added**:
- Complete typography scale (h1-h4, body variants, UI text)
- Shadow system (sm, md, lg, xl)
- Dark mode color palette (ready for implementation)
- Extended color palette with light variants for status colors
- Animation constants (durations, easing)
- Z-index layering system
- Breakpoints for responsive design

### 2. New Component Library
**Files**: Created 5 new reusable components in `src/theme/components/`

1. **SearchBar.tsx**
   - Auto-focus support
   - Clear button when text present
   - Focus state styling
   - Keyboard accessory integration

2. **IconButton.tsx**
   - Three variants: filled, outlined, ghost
   - Three sizes: small (32px), medium (44px), large (56px)
   - Haptic feedback support
   - Disabled state styling
   - Accessibility labels

3. **Divider.tsx**
   - Horizontal/vertical orientation
   - Customizable color, thickness, spacing
   - Lightweight, reusable separator

4. **Modal.tsx**
   - Bottom-anchored modal with backdrop
   - Animated entrance/exit (fade + slide)
   - Size variants: small, medium, large, full
   - Optional header with title + close button
   - ScrollView content area

5. **BottomSheet.tsx**
   - Swipe-to-dismiss gesture support
   - Drag handle indicator
   - Animated slide-up/down
   - ScrollView content with auto-sizing
   - Header with title + close

### 3. MenuItemDetailScreen
**File**: `app/customer/menu-item/[itemId].tsx`

**Features**:
- Full-screen item detail with hero image
- Nutrition grid (calories, protein, carbs, fat)
- Allergen warnings with icons
- Complete modifier selection flow:
  - Single-select radio buttons
  - Multi-select with max limits
  - Required modifier validation
  - Price adjustments display
- Special instructions input
- Quantity selector with +/- buttons
- Fixed bottom bar with total price
- Haptic feedback on all interactions
- Accessibility labels throughout

---

## Remaining High-Priority Enhancements

### 4. Tab Bar Enhancement (30 min)
**File**: `app/customer/_layout.tsx`

**Changes Needed**:
```typescript
// Add haptic feedback to tab press
import * as Haptics from 'expo-haptics';

tabBarButton: (props) => (
  <Pressable
    {...props}
    onPress={(e) => {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      props.onPress?.(e);
    }}
  />
),

// Animate cart badge with scale
tabBarBadge: cartItemCount > 0 ? cartItemCount : undefined,
tabBarBadgeStyle: {
  backgroundColor: colors.danger,
  fontSize: 11,
  fontWeight: '700',
  // Add Animated.View wrapper for scale animation
},
```

### 5. Customer Home Screen Polish (1 hour)
**File**: `src/screens/Customer/CustomerHomeScreen.tsx`

**Add**:
1. **Search Bar** (top of screen)
   ```typescript
   import { SearchBar } from '../../theme/components/SearchBar';
   
   const [searchQuery, setSearchQuery] = useState('');
   
   <SearchBar
     value={searchQuery}
     onChangeText={setSearchQuery}
     placeholder="Search for food..."
     containerStyle={{ marginBottom: spacing.md }}
   />
   ```

2. **Location Selector** (below search)
   ```typescript
   <Pressable style={styles.locationBar} onPress={handleLocationPress}>
     <Ionicons name="location" size={20} color={colors.accent} />
     <Text style={styles.locationText}>Delivering to: {address}</Text>
     <Ionicons name="chevron-down" size={20} color={colors.textSecondary} />
   </Pressable>
   ```

3. **Hero Banner Carousel** (after location)
   ```typescript
   import { Dimensions } from 'react-native';
   import Carousel from 'react-native-snap-carousel';
   
   const banners = [
     { id: '1', image: 'url', title: '20% Off First Order', cta: 'Order Now' },
     // ... more banners
   ];
   
   <Carousel
     data={banners}
     renderItem={({ item }) => <BannerCard {...item} />}
     sliderWidth={SCREEN_WIDTH}
     itemWidth={SCREEN_WIDTH - spacing.lg * 2}
   />
   ```

4. **"Order Again" Section**
   ```typescript
   const { orders } = useDataStore();
   const recentOrders = orders.slice(0, 3);
   
   {recentOrders.length > 0 && (
     <View style={styles.section}>
       <SectionHeader title="Order Again" />
       <ScrollView horizontal showsHorizontalScrollIndicator={false}>
         {recentOrders.map(order => (
           <ReorderCard key={order.id} order={order} />
         ))}
       </ScrollView>
     </View>
   )}
   ```

### 6. Categories Screen Enhancements (1 hour)
**File**: `src/screens/Customer/CategoriesScreen.tsx`

**Add**:
1. **Search Integration**
   ```typescript
   import { SearchBar } from '../../theme/components/SearchBar';
   const [searchQuery, setSearchQuery] = useState('');
   
   // Filter menu items by search
   const filteredItems = menuItems.filter(item =>
     item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
     item.description?.toLowerCase().includes(searchQuery.toLowerCase())
   );
   ```

2. **Advanced Filters** (use BottomSheet)
   ```typescript
   import { BottomSheet } from '../../theme/components/BottomSheet';
   
   const [showFilters, setShowFilters] = useState(false);
   const [filters, setFilters] = useState({
     maxPrice: 50,
     dietary: [],
     minRating: 0,
   });
   
   <IconButton
     icon="filter"
     onPress={() => setShowFilters(true)}
   />
   
   <BottomSheet
     visible={showFilters}
     onClose={() => setShowFilters(false)}
     title="Filters"
   >
     <PriceRangeSlider value={filters.maxPrice} onChange={...} />
     <DietaryCheckboxes selected={filters.dietary} onChange={...} />
     <RatingSelector selected={filters.minRating} onChange={...} />
   </BottomSheet>
   ```

3. **Grid/List Toggle**
   ```typescript
   const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
   
   <IconButton
     icon={viewMode === 'grid' ? 'list' : 'grid'}
     onPress={() => setViewMode(v => v === 'grid' ? 'list' : 'grid')}
   />
   
   // In FlatList:
   numColumns={viewMode === 'grid' ? 2 : 1}
   key={viewMode} // Force re-render on layout change
   ```

4. **Sort Options**
   ```typescript
   const [sortBy, setSortBy] = useState<'popular' | 'price' | 'rating'>('popular');
   
   <BottomSheet visible={showSort} onClose={() => setShowSort(false)} title="Sort By">
     <Pressable onPress={() => setSortBy('popular')}>
       <Text>Most Popular</Text>
     </Pressable>
     <Pressable onPress={() => setSortBy('price')}>
       <Text>Price: Low to High</Text>
     </Pressable>
     <Pressable onPress={() => setSortBy('rating')}>
       <Text>Highest Rated</Text>
     </Pressable>
   </BottomSheet>
   ```

### 7. Cart Screen Gestures (1.5 hours)
**File**: `src/screens/Customer/CartScreen.tsx`

**Add**:
1. **Swipe-to-Delete**
   ```bash
   npm install react-native-gesture-handler react-native-reanimated
   ```
   
   ```typescript
   import Swipeable from 'react-native-gesture-handler/Swipeable';
   
   const renderRightActions = (item: CartItem) => (
     <Pressable
       style={styles.deleteAction}
       onPress={() => removeItem(item)}
     >
       <Ionicons name="trash" size={24} color={colors.textInverse} />
       <Text style={styles.deleteText}>Delete</Text>
     </Pressable>
   );
   
   <Swipeable
     renderRightActions={() => renderRightActions(item)}
     overshootRight={false}
   >
     <CartItemCard item={item} />
   </Swipeable>
   ```

2. **Tip Selector** (move from checkout)
   ```typescript
   const tipOptions = [
     { type: 'ten', label: '10%', value: subtotal * 0.1 },
     { type: 'fifteen', label: '15%', value: subtotal * 0.15 },
     { type: 'twenty', label: '20%', value: subtotal * 0.2 },
     { type: 'custom', label: 'Custom', value: null },
   ];
   
   <View style={styles.tipSection}>
     <Text style={styles.tipTitle}>Add Tip for Driver</Text>
     <View style={styles.tipRow}>
       {tipOptions.map(opt => (
         <Chip
           key={opt.type}
           label={opt.label}
           selected={selectedTip.type === opt.type}
           onPress={() => setSelectedTip(opt)}
         />
       ))}
     </View>
   </View>
   ```

3. **Delivery Time Estimate**
   ```typescript
   <View style={styles.deliveryEstimate}>
     <Ionicons name="time-outline" size={20} color={colors.accent} />
     <Text style={styles.estimateText}>
       Estimated delivery: <Text style={styles.estimateBold}>25-35 min</Text>
     </Text>
   </View>
   ```

### 8. Order Tracking Screen (2 hours)
**File**: `app/customer/order-tracking/[orderId].tsx`

**Create New Screen**:
```typescript
import MapView, { Marker, Polyline } from 'react-native-maps';

export default function OrderTrackingScreen() {
  const params = useLocalSearchParams<{ orderId: string }>();
  const order = useDataStore(s => s.orders.find(o => o.id === params.orderId));
  
  return (
    <View style={styles.container}>
      {/* Map View */}
      <MapView
        style={styles.map}
        region={{
          latitude: 37.78825,
          longitude: -122.4324,
          latitudeDelta: 0.01,
          longitudeDelta: 0.01,
        }}
      >
        {/* Restaurant Marker */}
        <Marker coordinate={{ latitude: 37.78825, longitude: -122.4324 }}>
          <View style={styles.restaurantMarker}>
            <Ionicons name="restaurant" size={24} color={colors.accent} />
          </View>
        </Marker>
        
        {/* Driver Marker (if assigned) */}
        {order.driverId && (
          <Marker coordinate={{ latitude: 37.79, longitude: -122.43 }}>
            <View style={styles.driverMarker}>
              <Ionicons name="bicycle" size={24} color={colors.textInverse} />
            </View>
          </Marker>
        )}
        
        {/* Delivery Location Marker */}
        <Marker coordinate={{ latitude: 37.795, longitude: -122.435 }}>
          <View style={styles.homeMarker}>
            <Ionicons name="home" size={24} color={colors.success} />
          </View>
        </Marker>
      </MapView>
      
      {/* Status Card */}
      <View style={styles.statusCard}>
        <View style={styles.statusHeader}>
          <Text style={styles.statusTitle}>{getStatusLabel(order.status)}</Text>
          <Text style={styles.eta}>25-35 min</Text>
        </View>
        
        {/* Progress Bar */}
        <View style={styles.progressBar}>
          {['PLACED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED'].map((status, index) => (
            <View key={status} style={styles.progressStep}>
              <View style={[styles.progressDot, order.status === status && styles.progressDotActive]} />
              {index < 3 && <View style={styles.progressLine} />}
            </View>
          ))}
        </View>
        
        {/* Driver Info (if assigned) */}
        {order.driverName && (
          <View style={styles.driverInfo}>
            <View style={styles.driverAvatar}>
              <Text style={styles.driverInitials}>
                {order.driverName.split(' ').map(n => n[0]).join('')}
              </Text>
            </View>
            <View style={styles.driverDetails}>
              <Text style={styles.driverName}>{order.driverName}</Text>
              <Text style={styles.driverStatus}>On the way</Text>
            </View>
            <IconButton icon="call" variant="filled" size="small" />
          </View>
        )}
        
        {/* Order Summary */}
        <View style={styles.orderSummary}>
          <Text style={styles.summaryTitle}>Order #{order.id.slice(0, 6)}</Text>
          <Text style={styles.summaryItems}>
            {order.items.length} item{order.items.length !== 1 ? 's' : ''} · ${order.total.toFixed(2)}
          </Text>
        </View>
      </View>
    </View>
  );
}
```

**Install**: `expo install react-native-maps`

### 9. Global Micro-interactions (2 hours)

**Add to Every Screen**:

1. **Pull-to-Refresh**
   ```typescript
   import { RefreshControl } from 'react-native';
   
   const [refreshing, setRefreshing] = useState(false);
   
   const onRefresh = async () => {
     setRefreshing(true);
     await loadData();
     setRefreshing(false);
   };
   
   <ScrollView
     refreshControl={
       <RefreshControl
         refreshing={refreshing}
         onRefresh={onRefresh}
         tintColor={colors.accent}
       />
     }
   >
   ```

2. **Skeleton Loaders**
   ```typescript
   import { Skeleton } from '../../theme/components/Skeleton';
   
   {isLoading ? (
     <>
       <Skeleton width="100%" height={120} borderRadius={radii.medium} />
       <Skeleton width="80%" height={20} style={{ marginTop: spacing.md }} />
       <Skeleton width="60%" height={20} style={{ marginTop: spacing.sm }} />
     </>
   ) : (
     <ActualContent />
   )}
   ```

3. **Haptic Feedback in Button Component**
   ```typescript
   // Update src/theme/components/Button.tsx
   import * as Haptics from 'expo-haptics';
   
   const handlePress = (e: any) => {
     if (!disabled && !loading) {
       Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
       onPress?.(e);
     }
   };
   ```

4. **Toast Notifications**
   ```typescript
   // Update src/theme/components/Toast.tsx to show on actions
   // Import in CartStore:
   import { Toast } from '../theme/components/Toast';
   
   // After adding item:
   Toast.show({
     type: 'success',
     message: `${item.name} added to cart`,
     duration: 2000,
   });
   ```

### 10. Accessibility Pass (1.5 hours)

**Add to All Interactive Elements**:

1. **Button Components**
   ```typescript
   <Pressable
     accessibilityRole="button"
     accessibilityLabel="Add to cart"
     accessibilityHint="Adds this item to your shopping cart"
     accessibilityState={{ disabled: !canAddToCart() }}
   >
   ```

2. **Touch Target Sizes**
   ```typescript
   // Ensure all Pressables have minimum 44x44 touch area
   <Pressable style={[styles.button, { minWidth: 44, minHeight: 44 }]}>
   ```

3. **Screen Reader Announcements**
   ```typescript
   import { AccessibilityInfo } from 'react-native';
   
   // After action completes:
   AccessibilityInfo.announceForAccessibility('Item added to cart');
   ```

4. **Focus Management**
   ```typescript
   import { useRef, useEffect } from 'react';
   
   const inputRef = useRef<TextInput>(null);
   
   useEffect(() => {
     inputRef.current?.focus();
   }, []);
   
   <TextInput ref={inputRef} accessible accessibilityLabel="Search for food" />
   ```

---

## Quick Wins (< 30 min each)

### ✅ Completed
1. ✓ Upgrade theme system
2. ✓ Create SearchBar component
3. ✓ Create IconButton component
4. ✓ Create Modal component
5. ✓ Create BottomSheet component
6. ✓ Create Divider component
7. ✓ Build MenuItemDetailScreen

### 🚀 Remaining Quick Wins

1. **Add Haptic Feedback to All Buttons** (15 min)
   - Update `Button.tsx` with `Haptics.impactAsync()`
   - Update tab bar with haptic feedback

2. **Animate Cart Badge** (10 min)
   - Wrap badge in `Animated.View`
   - Add scale animation on count change

3. **Add Search to Home Screen** (20 min)
   - Import `SearchBar` component
   - Add state + filter logic
   - Position at top of screen

4. **Pull-to-Refresh on Orders** (10 min)
   - Add `RefreshControl` to `OrdersScreen` FlatList
   - Hook up to `refreshOrders()` function

5. **Accessibility Labels on Icons** (20 min)
   - Add `accessibilityLabel` to all Ionicons without text
   - Add `accessibilityRole` to all Pressables

---

## Advanced Features (Future Sprints)

### Phase 2: Polish & Delight (2-3 weeks)
- Dark mode toggle in Profile screen
- Onboarding flow (3-4 screens)
- Advanced order search/filters
- Social proof ("15 people ordered this today")
- Loyalty confetti animations
- Voice UI enhancements (waveform, preview)

### Phase 3: Performance (1-2 weeks)
- Image optimization (react-native-fast-image)
- List virtualization (@shopify/flash-list)
- Code splitting for admin/driver
- Zustand store splitting (prevent unnecessary re-renders)

### Phase 4: Analytics & Testing
- Screenshot testing
- Storybook for component library
- Performance monitoring
- A/B testing framework

---

## Testing Checklist

Before deploying, test:
- [ ] All navigation flows (Customer, Admin, Driver)
- [ ] Menu item detail → Add to cart → Checkout → Place order
- [ ] Voice AI ordering end-to-end
- [ ] Order tracking real-time updates
- [ ] Search functionality across screens
- [ ] Filters and sorting in Categories
- [ ] Swipe gestures in Cart
- [ ] Modifier selection validation
- [ ] Accessibility with screen reader
- [ ] Haptic feedback on all interactions
- [ ] Pull-to-refresh on all lists
- [ ] Error states (network failures, empty states)
- [ ] Loading states (skeleton loaders)
- [ ] Dark mode (if enabled)

---

## Performance Targets

- **Time to Interactive**: < 3s on mid-range devices
- **FPS**: 60fps on all scrollable lists
- **Bundle Size**: < 25MB (split by role)
- **API Response Time**: < 500ms p95
- **Image Load Time**: < 2s on 3G

---

## Component Library Documentation

### Button
```typescript
<Button
  title="Add to Cart"
  onPress={handlePress}
  variant="primary | secondary | outline | ghost"
  size="small | medium | large"
  icon="cart"
  iconPosition="left | right"
  loading={isLoading}
  disabled={!canAdd}
  fullWidth
  haptic
/>
```

### SearchBar
```typescript
<SearchBar
  value={query}
  onChangeText={setQuery}
  onClear={() => setQuery('')}
  placeholder="Search..."
  autoFocus
/>
```

### IconButton
```typescript
<IconButton
  icon="heart"
  variant="filled | outlined | ghost"
  size="small | medium | large"
  color={colors.danger}
  backgroundColor={colors.dangerLight}
  onPress={handleFavorite}
  haptic
/>
```

### Modal
```typescript
<Modal
  visible={showModal}
  onClose={() => setShowModal(false)}
  title="Filter Options"
  size="small | medium | large | full"
  showCloseButton
>
  <FilterContent />
</Modal>
```

### BottomSheet
```typescript
<BottomSheet
  visible={showSheet}
  onClose={() => setShowSheet(false)}
  title="Sort By"
  height={300} // or "auto"
  showHandle
>
  <SortOptions />
</BottomSheet>
```

---

## File Structure

```
src/
├── theme/
│   ├── theme.ts (✅ Enhanced)
│   └── components/
│       ├── Button.tsx (existing)
│       ├── SearchBar.tsx (✅ New)
│       ├── IconButton.tsx (✅ New)
│       ├── Divider.tsx (✅ New)
│       ├── Modal.tsx (✅ New)
│       ├── BottomSheet.tsx (✅ New)
│       ├── Card.tsx (existing)
│       ├── Chip.tsx (existing)
│       ├── Badge.tsx (existing)
│       ├── Input.tsx (existing)
│       ├── Toast.tsx (existing)
│       └── Skeleton.tsx (existing)
├── screens/
│   └── Customer/
│       ├── CustomerHomeScreen.tsx (📝 needs search + banners)
│       ├── CategoriesScreen.tsx (📝 needs filters + grid toggle)
│       ├── CartScreen.tsx (📝 needs swipe-to-delete)
│       └── OrdersScreen.tsx (📝 needs pull-to-refresh)
└── app/
    └── customer/
        └── menu-item/
            └── [itemId].tsx (✅ New - full modifier flow)
```

---

## Next Steps

1. **Test the new MenuItemDetailScreen**:
   - Update CategoriesScreen to navigate to it:
     ```typescript
     import { router } from 'expo-router';
     
     <Pressable onPress={() => router.push(`/customer/menu-item/${item.id}`)}>
     ```

2. **Run linter**:
   ```bash
   npx eslint src/theme/**/*.tsx app/customer/**/*.tsx --fix
   ```

3. **Test on device**:
   ```bash
   npx expo start
   ```

4. **Iterate on remaining todos**:
   - Tab bar enhancements
   - Home screen polish
   - Categories filters
   - Cart gestures
   - Order tracking
   - Micro-interactions
   - Accessibility

---

**Total Estimated Time for Remaining Work**: 8-10 hours
**Priority Order**: Tab bar → Home → Categories → Cart → Tracking → Micro-interactions → Accessibility
