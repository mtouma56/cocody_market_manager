-- =============================================================================
-- Document Storage Migration for Market Management
-- =============================================================================
-- Create document storage buckets for business files

-- ============================================================================= 
-- STORAGE BUCKETS
-- =============================================================================

-- Create private bucket for business documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'business-documents',
    'business-documents', 
    false, -- Private bucket for business documents
    20971520, -- 20MB limit
    ARRAY[
        'application/pdf',
        'image/jpeg', 
        'image/png',
        'image/webp',
        'image/jpg',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain'
    ]
);

-- Create public bucket for profile images and general assets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
    'public-assets',
    'public-assets',
    true, -- Public bucket for profile images
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- =============================================================================
-- DOCUMENT ATTACHMENTS TABLE
-- =============================================================================

-- Create table to track document attachments and their metadata
CREATE TABLE public.document_attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('commercant', 'local', 'bail', 'paiement')),
    entity_id UUID NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    document_type TEXT, -- 'contract', 'receipt', 'photo', 'identity', 'other'
    title TEXT,
    description TEXT,
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX idx_document_attachments_entity ON public.document_attachments(entity_type, entity_id);
CREATE INDEX idx_document_attachments_type ON public.document_attachments(document_type);
CREATE INDEX idx_document_attachments_created ON public.document_attachments(created_at DESC);

-- Enable RLS on document attachments
ALTER TABLE public.document_attachments ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- ROW LEVEL SECURITY POLICIES FOR DOCUMENT ATTACHMENTS
-- =============================================================================

-- Allow authenticated users to view all document attachments
CREATE POLICY "authenticated_users_view_attachments"
ON public.document_attachments
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to create document attachments
CREATE POLICY "authenticated_users_create_attachments"
ON public.document_attachments
FOR INSERT
TO authenticated
WITH CHECK (uploaded_by = auth.uid());

-- Allow users to update their own uploaded documents
CREATE POLICY "users_update_own_attachments"
ON public.document_attachments
FOR UPDATE
TO authenticated
USING (uploaded_by = auth.uid())
WITH CHECK (uploaded_by = auth.uid());

-- Allow users to delete their own uploaded documents
CREATE POLICY "users_delete_own_attachments"
ON public.document_attachments
FOR DELETE
TO authenticated
USING (uploaded_by = auth.uid());

-- =============================================================================
-- STORAGE RLS POLICIES FOR BUSINESS DOCUMENTS
-- =============================================================================

-- Allow authenticated users to view business documents
CREATE POLICY "authenticated_users_view_business_docs"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'business-documents');

-- Allow authenticated users to upload business documents with proper folder structure
CREATE POLICY "authenticated_users_upload_business_docs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'business-documents'
    AND (storage.foldername(name))[1] IN ('commercants', 'locaux', 'baux', 'paiements', 'general')
);

-- Allow users to update business documents
CREATE POLICY "authenticated_users_update_business_docs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'business-documents')
WITH CHECK (bucket_id = 'business-documents');

-- Allow authenticated users to delete business documents
CREATE POLICY "authenticated_users_delete_business_docs"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'business-documents');

-- =============================================================================
-- STORAGE RLS POLICIES FOR PUBLIC ASSETS
-- =============================================================================

-- Anyone can view public assets
CREATE POLICY "public_view_assets"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'public-assets');

-- Only authenticated users can upload public assets
CREATE POLICY "authenticated_users_upload_public_assets"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'public-assets');

-- Only file owner can manage their public assets
CREATE POLICY "owners_manage_public_assets"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'public-assets' AND owner = auth.uid())
WITH CHECK (bucket_id = 'public-assets' AND owner = auth.uid());

CREATE POLICY "owners_delete_public_assets"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'public-assets' AND owner = auth.uid());

-- =============================================================================
-- TRIGGERS FOR UPDATED_AT
-- =============================================================================

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_document_attachments_updated_at
    BEFORE UPDATE ON public.document_attachments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- MOCK DATA FOR DOCUMENT ATTACHMENTS
-- =============================================================================

-- Get existing entity IDs for mock attachments
DO $$
DECLARE
    commercant_id UUID;
    local_id UUID;
    bail_id UUID;
    paiement_id UUID;
BEGIN
    -- Get a commercant ID
    SELECT id INTO commercant_id FROM public.commercants LIMIT 1;
    
    -- Get a local ID  
    SELECT id INTO local_id FROM public.locaux LIMIT 1;
    
    -- Get a bail ID
    SELECT id INTO bail_id FROM public.baux LIMIT 1;
    
    -- Get a paiement ID
    SELECT id INTO paiement_id FROM public.paiements LIMIT 1;

    -- Insert mock document attachments if entities exist
    IF commercant_id IS NOT NULL THEN
        INSERT INTO public.document_attachments (
            entity_type, entity_id, file_name, file_path, file_size, mime_type, 
            document_type, title, description
        ) VALUES 
        (
            'commercant', commercant_id, 'piece_identite.pdf', 
            'commercants/' || commercant_id || '/piece_identite.pdf',
            1048576, 'application/pdf', 'identity', 
            'Pièce d''identité', 'Copie de la carte d''identité nationale'
        ),
        (
            'commercant', commercant_id, 'photo_profil.jpg',
            'commercants/' || commercant_id || '/photo_profil.jpg', 
            524288, 'image/jpeg', 'photo',
            'Photo de profil', 'Photo du commerçant'
        );
    END IF;

    IF local_id IS NOT NULL THEN
        INSERT INTO public.document_attachments (
            entity_type, entity_id, file_name, file_path, file_size, mime_type,
            document_type, title, description
        ) VALUES
        (
            'local', local_id, 'plan_local.pdf',
            'locaux/' || local_id || '/plan_local.pdf',
            2097152, 'application/pdf', 'other',
            'Plan du local', 'Plan architectural du local commercial'
        );
    END IF;

    IF bail_id IS NOT NULL THEN
        INSERT INTO public.document_attachments (
            entity_type, entity_id, file_name, file_path, file_size, mime_type,
            document_type, title, description  
        ) VALUES
        (
            'bail', bail_id, 'contrat_bail.pdf',
            'baux/' || bail_id || '/contrat_bail.pdf',
            3145728, 'application/pdf', 'contract',
            'Contrat de bail', 'Contrat de location signé'
        );
    END IF;

    IF paiement_id IS NOT NULL THEN
        INSERT INTO public.document_attachments (
            entity_type, entity_id, file_name, file_path, file_size, mime_type,
            document_type, title, description
        ) VALUES
        (
            'paiement', paiement_id, 'recu_paiement.pdf', 
            'paiements/' || paiement_id || '/recu_paiement.pdf',
            524288, 'application/pdf', 'receipt',
            'Reçu de paiement', 'Justificatif de paiement du loyer'
        );
    END IF;
END $$;