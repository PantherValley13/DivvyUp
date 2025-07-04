# DivvyUp Supabase Integration Setup

Follow these steps to integrate Supabase database functionality into your DivvyUp app.

## Prerequisites

- iOS 14.0 or later
- Xcode 14.0 or later
- A Supabase account (free at [supabase.com](https://supabase.com))

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/sign in
2. Click "New Project"
3. Choose your organization (create one if needed)
4. Enter project details:
   - **Name**: DivvyUp (or your preferred name)
   - **Database Password**: Choose a strong password
   - **Region**: Select the closest region to your users
5. Click "Create new project"
6. Wait for the project to be created (2-3 minutes)

## Step 2: Add Supabase Swift SDK

1. Open your DivvyUp project in Xcode
2. Go to **File > Add Package Dependencies**
3. Enter the URL: `https://github.com/supabase/supabase-swift`
4. Click **Add Package**
5. Select the following products:
   - **Supabase** (main SDK)
   - **Realtime** (optional, for real-time updates)
6. Click **Add Package**

## Step 3: Configure Database Schema

1. In your Supabase dashboard, go to the **SQL Editor**
2. Copy the contents of `database_schema.sql` from this project
3. Paste it into the SQL Editor
4. Click **Run** to execute the schema
5. Verify the tables were created in **Table Editor**:
   - `bills`
   - `bill_items`
   - `participants`

## Step 4: Get Your Supabase Credentials

1. In your Supabase dashboard, go to **Settings > API**
2. Copy the following values:
   - **Project URL** (something like `https://abc123.supabase.co`)
   - **anon public key** (starts with `eyJ...`)

## Step 5: Configure the App

1. Open `DivvyUp/SupabaseConfig.swift`
2. Replace the placeholder values:

```swift
struct SupabaseConfig {
    static let url = "https://your-project-id.supabase.co"  // Replace with your URL
    static let anonKey = "your-anon-key"  // Replace with your anon key

    // ... rest of the file
}
```

## Step 6: Test the Integration

1. Build and run the app
2. Add some items using OCR or manual entry
3. Add participants and assign items
4. Tap "Save Bill" in the current bill section
5. Go to the "History" tab to see saved bills
6. Verify data is being saved to Supabase in the **Table Editor**

## Authentication (Optional)

The current setup uses Row Level Security (RLS) policies that require authentication. You have two options:

### Option A: Enable Anonymous Access (Recommended for testing)

In your Supabase SQL Editor, uncomment and run the anonymous access policies from `database_schema.sql`:

```sql
-- Drop the restrictive policies
DROP POLICY IF EXISTS "Users can view their own bills" ON bills;
-- ... (rest of the drop statements)

-- Create permissive policies for anonymous access
CREATE POLICY "Allow anonymous access to bills" ON bills
    FOR ALL USING (true) WITH CHECK (true);
-- ... (rest of the permissive policies)
```

### Option B: Implement User Authentication

Add authentication UI to your app using the Supabase Auth methods in `SupabaseService.swift`:

```swift
// Sign up
try await supabaseService.signUp(email: email, password: password)

// Sign in
try await supabaseService.signIn(email: email, password: password)

// Sign out
try await supabaseService.signOut()
```

## Environment Variables (Optional)

Instead of hardcoding credentials, you can use environment variables:

1. In Xcode, go to **Product > Scheme > Edit Scheme**
2. Select **Run > Arguments > Environment Variables**
3. Add:
   - `SUPABASE_URL`: Your project URL
   - `SUPABASE_ANON_KEY`: Your anon key

The app will automatically use these if available.

## Features Enabled

Once configured, your app will have:

✅ **Database persistence** - Bills saved to Supabase PostgreSQL  
✅ **Bill history** - View and manage previously saved bills  
✅ **Real-time sync** - Optional real-time updates across devices  
✅ **Cloud backup** - Data backed up in the cloud  
✅ **Multi-device sync** - Access bills from multiple devices

## Troubleshooting

### "Supabase Not Configured" Message

- Verify you've updated `SupabaseConfig.swift` with correct credentials
- Check that URL and anon key are correct
- Ensure no extra spaces or quotes in the values

### Network Errors

- Check your internet connection
- Verify Supabase project is running (not paused)
- Check Supabase status page for outages

### Permission Errors

- Ensure RLS policies are set up correctly
- If testing without auth, uncomment the anonymous access policies
- Check that anon key has proper permissions

### Build Errors

- Make sure Supabase Swift SDK is properly added
- Clean build folder (Product > Clean Build Folder)
- Check iOS deployment target is 14.0+

## Database Schema Details

The app uses three main tables:

- **bills**: Main bill information (totals, dates, user association)
- **bill_items**: Individual items from receipts (name, price, assignments)
- **participants**: People involved in bill splitting (name, color coding)

All tables use UUID primary keys and include proper foreign key relationships with cascade deletes.

## Next Steps

Consider implementing:

- **User profiles** with avatars and preferences
- **Bill sharing** via links or QR codes
- **Payment integration** with Venmo/PayPal
- **Receipt image storage** in Supabase Storage
- **Push notifications** for bill updates
- **Analytics** tracking spending patterns

## Support

If you encounter issues:

1. Check the Supabase documentation: [supabase.com/docs](https://supabase.com/docs)
2. Review the Supabase Swift SDK docs: [github.com/supabase/supabase-swift](https://github.com/supabase/supabase-swift)
3. Check the app's console logs for error details
4. Verify your database schema matches the provided SQL

---

**Happy bill splitting! 🧾💰**
