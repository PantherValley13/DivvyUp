-- DivvyUp Database Schema for Supabase
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create bills table
CREATE TABLE IF NOT EXISTS bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    total_amount DECIMAL(10,2) DEFAULT 0.0,
    tax_amount DECIMAL(10,2) DEFAULT 0.0,
    tip_amount DECIMAL(10,2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Add user_id if using authentication
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create bill_items table
CREATE TABLE IF NOT EXISTS bill_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    quantity INTEGER DEFAULT 1,
    assigned_to UUID[] DEFAULT '{}', -- Array of participant IDs
    is_manually_assigned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create participants table
CREATE TABLE IF NOT EXISTS participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color_name TEXT DEFAULT 'blue',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bills_user_id ON bills(user_id);
CREATE INDEX IF NOT EXISTS idx_bills_created_at ON bills(created_at);
CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_participants_bill_id ON participants(bill_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for bills table
DROP TRIGGER IF EXISTS update_bills_updated_at ON bills;
CREATE TRIGGER update_bills_updated_at
    BEFORE UPDATE ON bills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
-- Enable RLS on all tables
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;

-- Bills policies
CREATE POLICY "Users can view their own bills" ON bills
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bills" ON bills
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bills" ON bills
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bills" ON bills
    FOR DELETE USING (auth.uid() = user_id);

-- Bill items policies
CREATE POLICY "Users can view bill items for their bills" ON bill_items
    FOR SELECT USING (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert bill items for their bills" ON bill_items
    FOR INSERT WITH CHECK (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update bill items for their bills" ON bill_items
    FOR UPDATE USING (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete bill items for their bills" ON bill_items
    FOR DELETE USING (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

-- Participants policies
CREATE POLICY "Users can view participants for their bills" ON participants
    FOR SELECT USING (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert participants for their bills" ON participants
    FOR INSERT WITH CHECK (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update participants for their bills" ON participants
    FOR UPDATE USING (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete participants for their bills" ON participants
    FOR DELETE USING (
        bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid())
    );

-- If you want to allow anonymous usage (without authentication), 
-- you can create permissive policies instead:

-- Uncomment the following lines if you want to allow anonymous access:
/*
-- Drop the restrictive policies
DROP POLICY IF EXISTS "Users can view their own bills" ON bills;
DROP POLICY IF EXISTS "Users can insert their own bills" ON bills;
DROP POLICY IF EXISTS "Users can update their own bills" ON bills;
DROP POLICY IF EXISTS "Users can delete their own bills" ON bills;

-- Create permissive policies for anonymous access
CREATE POLICY "Allow anonymous access to bills" ON bills
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous access to bill_items" ON bill_items
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous access to participants" ON participants
    FOR ALL USING (true) WITH CHECK (true);
*/

-- Create a view for bill summaries (optional)
CREATE OR REPLACE VIEW bill_summaries AS
SELECT 
    b.id,
    b.total_amount,
    b.tax_amount,
    b.tip_amount,
    b.created_at,
    b.updated_at,
    COUNT(DISTINCT bi.id) as item_count,
    COUNT(DISTINCT p.id) as participant_count,
    COALESCE(SUM(bi.price * bi.quantity), 0) as subtotal
FROM bills b
LEFT JOIN bill_items bi ON b.id = bi.bill_id
LEFT JOIN participants p ON b.id = p.bill_id
GROUP BY b.id, b.total_amount, b.tax_amount, b.tip_amount, b.created_at, b.updated_at;

-- Grant access to the view
GRANT SELECT ON bill_summaries TO authenticated;
GRANT SELECT ON bill_summaries TO anon;

-- Sample data (optional, for testing)
-- Uncomment to insert sample data:
/*
INSERT INTO bills (id, total_amount, tax_amount, tip_amount) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 45.50, 3.50, 8.00);

INSERT INTO participants (id, bill_id, name, color_name) VALUES
    ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Alice', 'blue'),
    ('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'Bob', 'green');

INSERT INTO bill_items (id, bill_id, name, price, quantity, assigned_to) VALUES
    ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 'Pizza', 18.99, 1, '{"550e8400-e29b-41d4-a716-446655440002", "550e8400-e29b-41d4-a716-446655440003"}'),
    ('550e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440001', 'Salad', 12.50, 1, '{"550e8400-e29b-41d4-a716-446655440002"}'),
    ('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440001', 'Soda', 3.00, 2, '{"550e8400-e29b-41d4-a716-446655440003"}');
*/ 