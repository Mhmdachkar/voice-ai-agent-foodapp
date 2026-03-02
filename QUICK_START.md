# Quick Start Guide - Testing Your App

## 🚀 Getting Started

### Prerequisites
- Node.js installed
- Windows (you're good!)
- Text editor (VS Code recommended)

---

## 📋 Step-by-Step Setup

### 1. Install Dependencies

Open PowerShell in the project folder:

```powershell
npm install
```

**Expected time:** 2-5 minutes

---

### 2. Verify Environment Variables

Your `.env` file is already configured with:
- ✅ Supabase URL
- ✅ Supabase Anon Key
- ✅ Voice API Key

No changes needed!

---

### 3. Start the Development Server

```powershell
npm run web
```

This will:
- Start Expo Metro bundler
- Open browser automatically
- Show the app at `http://localhost:8081`

**Alternative (Android):**
```powershell
npm run android
```
*Requires Android Studio + emulator installed*

---

## 🧪 Testing the Customer Flow

### Test Scenario 1: New Customer Sign-Up

1. **Launch app** → Should redirect to login screen
2. **Click "Sign Up" tab**
3. **Fill in:**
   - Full name: "Test User"
   - Email: "test@example.com"
   - Password: "password123"
   - Role: Select "customer"
4. **Click "Create account"**
5. **Result:** Should redirect to customer home screen

---

### Test Scenario 2: Browse Menu

1. **From home screen**, click **"🍔 Browse Menu"**
2. **See categories:** Burgers, Pizza, Sushi, etc.
3. **Click different categories** → Menu items update
4. **Observe:**
   - Item images (or placeholders)
   - Prices
   - Ratings
   - Nutrition info (calories, protein, prep time)
   - Tags (Healthy, Spicy, etc.)

---

### Test Scenario 3: Add to Cart

1. **Browse menu** → Pick an item
2. **Click "Add to Cart"** button
3. **Observe:**
   - Toast message appears
   - Cart counter appears at bottom
4. **Add 2-3 more items** from different categories

---

### Test Scenario 4: Manage Cart

1. **Click cart bar** at bottom → Opens cart screen
2. **Test quantity controls:**
   - Click `+` to increase quantity
   - Click `-` to decrease quantity
   - Click "Remove" to delete item
3. **Observe:**
   - Prices update automatically
   - Subtotal/tax/total recalculate
   - Can see any modifiers (if items have them)

---

### Test Scenario 5: Checkout

1. **From cart**, click **"Proceed to Checkout"**
2. **Fill delivery address:**
   - Street: "123 Main St"
   - City: "San Francisco"
   - State: "CA"
   - ZIP: "94102"
3. **Select payment method:** Credit Card or Cash
4. **Try promo code:**
   - Enter: `SAVE10`
   - Click "Apply"
   - See discount applied!
   
   **Valid codes:**
   - `SAVE10` - 10% off
   - `FREE5` - $5 off

5. **Click "Place Order"**
6. **Success alert appears** → Click "View Orders"

---

### Test Scenario 6: View Orders

1. **Orders screen opens** with your placed order
2. **Click on order card** to expand
3. **See:**
   - Order timeline (visual dots and lines)
   - Status: PLACED
   - All items ordered
   - Delivery address
   - Price breakdown
4. **Click again** to collapse

---

## 🎯 What to Look For

### ✅ Should Work
- ✅ Sign up / sign in
- ✅ Browse categories
- ✅ Add items to cart
- ✅ Modify cart quantities
- ✅ Apply promo codes
- ✅ Place order
- ✅ View order history
- ✅ Expand/collapse order details
- ✅ See order timelines

### ❌ Not Yet Implemented (Expected)
- ❌ Admin dashboard
- ❌ Driver screens
- ❌ Voice AI (microphone input)
- ❌ Profile editing
- ❌ Settings
- ❌ Real-time order updates (subscriptions work, but need backend updates)

---

## 🐛 Common Issues & Solutions

### Issue: "Module not found"
**Solution:**
```powershell
rm -r node_modules
npm install
```

### Issue: "Cannot connect to Metro"
**Solution:**
```powershell
# Kill any running processes
taskkill /F /IM node.exe

# Restart
npm run web
```

### Issue: "Supabase connection failed"
**Check:**
1. `.env` file is in project root
2. `SUPABASE_URL` and `SUPABASE_ANON_KEY` are filled in
3. Your Supabase project is active

### Issue: "Order placement fails"
**Possible causes:**
1. Supabase RPC function `create_order` not deployed
2. Database tables not created
3. Row Level Security (RLS) policies blocking access

**Check Supabase:**
- Run migrations in `supabase/migrations/`
- Verify RPC functions exist
- Check RLS policies allow inserts

---

## 📱 Supported Platforms

| Platform | Status | How to Run |
|----------|--------|------------|
| **Web** | ✅ Full support | `npm run web` |
| **Android** | ✅ Full support | `npm run android` (requires emulator) |
| **iOS** | ⚠️ Needs macOS | `npm run ios` (macOS only) |

---

## 🎨 UI Features to Test

### Theme
- Orange accent color (`#FF8C1A`)
- Light background
- Clean card-based UI
- Proper spacing and padding

### Components
- Buttons with loading states
- Cards with shadows
- Chips (tags)
- Empty states
- Price breakdowns
- Timeline visualization

### Navigation
- Bottom cart bar (clickable)
- Quick action buttons
- Category chips (horizontal scroll)
- Expandable order cards

---

## 📊 Database Testing

If you want to test with real Supabase data:

1. **Go to Supabase dashboard** → Your project
2. **Table Editor** → Check:
   - `profiles` table (your user should be there)
   - `menu_items` table (add some test items)
   - `categories` table (create categories)
   - `orders` table (should see your placed order)

---

## 🎉 Success Criteria

Your app is working correctly if you can:

✅ Sign up as a new customer  
✅ See menu items by category  
✅ Add items to cart  
✅ Modify cart quantities  
✅ Apply a promo code successfully  
✅ Place an order  
✅ View order in history  
✅ See order timeline  

---

## 📞 Need Help?

Check these files for implementation details:
- `CONVERSION_REVIEW.md` - Full code review
- `IMPLEMENTATION_SUMMARY.md` - What was implemented
- `CODE_QUALITY_HIGHLIGHTS.md` - Best practices used

---

## 🚀 Next Steps After Testing

Once basic flow works:

1. **Add real menu data** in Supabase
2. **Create admin account** (role: "admin")
3. **Test admin features** (coming in Phase 2)
4. **Deploy to production**

---

**Happy Testing! 🎉**
