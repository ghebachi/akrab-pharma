-- pharmacy_inquiries: patients send questions to a pharmacy,
-- pharmacists reply directly from their dashboard.

CREATE TABLE IF NOT EXISTS pharmacy_inquiries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pharmacy_id UUID REFERENCES pharmacies(id) ON DELETE CASCADE NOT NULL,
    patient_name TEXT NOT NULL,
    patient_phone TEXT,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'replied', 'closed')),
    pharmacist_reply TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE pharmacy_inquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public to insert inquiries" ON pharmacy_inquiries
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow pharmacists to view and update their pharmacy inquiries" ON pharmacy_inquiries
    FOR ALL
    USING (
        pharmacy_id IN (
            SELECT id FROM pharmacies WHERE pharmacist_id = auth.uid()
        )
    );

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_pharmacy_inquiries_modtime
    BEFORE UPDATE ON pharmacy_inquiries
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();
