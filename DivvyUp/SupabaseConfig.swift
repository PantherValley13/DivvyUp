import Foundation

// MARK: - Supabase Configuration
struct SupabaseConfig {
    // Replace these with your actual Supabase project credentials
    static let url = "https://your-project.supabase.co"
    static let anonKey = "your-anon-key"
    
    // Database table names
    static let billsTable = "bills"
    static let billItemsTable = "bill_items"
    static let participantsTable = "participants"
    
    // Validate configuration
    static var isConfigured: Bool {
        return url != "https://your-project.supabase.co" && 
               anonKey != "your-anon-key"
    }
}

// MARK: - Environment Variables Support
extension SupabaseConfig {
    /// Get Supabase URL from environment variables or use default
    static var supabaseURL: String {
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
            return envURL
        }
        return url
    }
    
    /// Get Supabase anon key from environment variables or use default
    static var supabaseAnonKey: String {
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return envKey
        }
        return anonKey
    }
}

// MARK: - Instructions for Setup
/*
 To set up Supabase for your DivvyUp app:
 
 1. Create a new Supabase project at https://supabase.com
 2. Go to Settings > API in your Supabase dashboard
 3. Copy your project URL and anon key
 4. Replace the placeholders in this file with your actual values
 
 OR
 
 Set environment variables:
 - SUPABASE_URL=https://your-project.supabase.co
 - SUPABASE_ANON_KEY=your-anon-key
 
 5. Run the SQL schema in your Supabase SQL editor (see database_schema.sql)
 6. Add the Supabase Swift package dependency to your Xcode project
 */ 