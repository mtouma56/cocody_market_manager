-- Location: supabase/migrations/20241018215142_cocody_market_rental_management.sql
-- Schema Analysis: Fresh project - no existing tables
-- Integration Type: Complete new rental management system
-- Dependencies: None - creating complete schema

-- 1. Types and Enums
CREATE TYPE public.statut_local AS ENUM ('Occupé', 'Disponible', 'Maintenance');
CREATE TYPE public.statut_bail AS ENUM ('Actif', 'Expire bientôt', 'Expiré');
CREATE TYPE public.statut_paiement AS ENUM ('Payé', 'En attente', 'En retard');
CREATE TYPE public.mode_paiement AS ENUM ('Espèces', 'Virement', 'Mobile Money', 'Chèque');

-- 2. Table étages (4 étages : RDC, 1er, 2e, 3e)
CREATE TABLE public.etages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL UNIQUE,
    ordre INTEGER NOT NULL UNIQUE,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Table types_locaux (6 types avec surfaces)
CREATE TABLE public.types_locaux (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL UNIQUE,
    surface_m2 DECIMAL(5,2) NOT NULL,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Table commercants (avec nom, contact, activité, email, photo_url)
CREATE TABLE public.commercants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL,
    contact TEXT NOT NULL,
    activite TEXT NOT NULL,
    email TEXT UNIQUE,
    photo_url TEXT,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Table locaux (avec numero unique, type_id, etage_id, statut, actif)
CREATE TABLE public.locaux (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero TEXT NOT NULL UNIQUE,
    type_id UUID REFERENCES public.types_locaux(id) ON DELETE CASCADE,
    etage_id UUID REFERENCES public.etages(id) ON DELETE CASCADE,
    statut public.statut_local DEFAULT 'Disponible'::public.statut_local,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Table baux (avec numero_contrat, local_id, commercant_id, dates, montant_loyer, statut)
CREATE TABLE public.baux (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_contrat TEXT NOT NULL UNIQUE,
    local_id UUID REFERENCES public.locaux(id) ON DELETE CASCADE,
    commercant_id UUID REFERENCES public.commercants(id) ON DELETE CASCADE,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    montant_loyer DECIMAL(12,2) NOT NULL,
    statut public.statut_bail DEFAULT 'Actif'::public.statut_bail,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Table paiements (avec bail_id, montant, dates, mois_concerne, statut, mode_paiement)
CREATE TABLE public.paiements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bail_id UUID REFERENCES public.baux(id) ON DELETE CASCADE,
    montant DECIMAL(12,2) NOT NULL,
    date_echeance DATE NOT NULL,
    date_paiement DATE,
    mois_concerne TEXT NOT NULL,
    statut public.statut_paiement DEFAULT 'En attente'::public.statut_paiement,
    mode_paiement public.mode_paiement,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. Essential Indexes
CREATE INDEX idx_etages_ordre ON public.etages(ordre);
CREATE INDEX idx_types_locaux_nom ON public.types_locaux(nom);
CREATE INDEX idx_commercants_nom ON public.commercants(nom);
CREATE INDEX idx_commercants_actif ON public.commercants(actif);
CREATE INDEX idx_locaux_numero ON public.locaux(numero);
CREATE INDEX idx_locaux_type_id ON public.locaux(type_id);
CREATE INDEX idx_locaux_etage_id ON public.locaux(etage_id);
CREATE INDEX idx_locaux_statut ON public.locaux(statut);
CREATE INDEX idx_baux_local_id ON public.baux(local_id);
CREATE INDEX idx_baux_commercant_id ON public.baux(commercant_id);
CREATE INDEX idx_baux_statut ON public.baux(statut);
CREATE INDEX idx_paiements_bail_id ON public.paiements(bail_id);
CREATE INDEX idx_paiements_date_echeance ON public.paiements(date_echeance);
CREATE INDEX idx_paiements_statut ON public.paiements(statut);
CREATE INDEX idx_paiements_mois_concerne ON public.paiements(mois_concerne);

-- 9. Enable RLS
ALTER TABLE public.etages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.types_locaux ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commercants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locaux ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.baux ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paiements ENABLE ROW LEVEL SECURITY;

-- 10. RLS Policies (Pattern 4: Public Read, Private Write for preview mode)
CREATE POLICY "public_can_read_etages" ON public.etages FOR SELECT TO public USING (true);
CREATE POLICY "public_can_read_types_locaux" ON public.types_locaux FOR SELECT TO public USING (true);
CREATE POLICY "public_can_read_commercants" ON public.commercants FOR SELECT TO public USING (true);
CREATE POLICY "public_can_read_locaux" ON public.locaux FOR SELECT TO public USING (true);
CREATE POLICY "public_can_read_baux" ON public.baux FOR SELECT TO public USING (true);
CREATE POLICY "public_can_read_paiements" ON public.paiements FOR SELECT TO public USING (true);

-- Insert/Update/Delete for authenticated users only
CREATE POLICY "authenticated_can_manage_etages" ON public.etages FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_can_manage_types_locaux" ON public.types_locaux FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_can_manage_commercants" ON public.commercants FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_can_manage_locaux" ON public.locaux FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_can_manage_baux" ON public.baux FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_can_manage_paiements" ON public.paiements FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 11. Mock Data Insertion
DO $$
DECLARE
    rdc_id UUID := gen_random_uuid();
    premier_id UUID := gen_random_uuid();
    deuxieme_id UUID := gen_random_uuid();
    troisieme_id UUID := gen_random_uuid();
    
    -- Type IDs
    boutique_9_id UUID := gen_random_uuid();
    boutique_4_5_id UUID := gen_random_uuid();
    restaurant_id UUID := gen_random_uuid();
    banque_id UUID := gen_random_uuid();
    box_id UUID := gen_random_uuid();
    etal_id UUID := gen_random_uuid();
    
    -- Variables pour les boucles
    i INTEGER;
    local_id UUID;
    commercant_id UUID;
    bail_id UUID;
    type_choices UUID[];
    etage_choices UUID[];
    current_type UUID;
    current_etage UUID;
    local_numero TEXT;
    contrat_numero TEXT;
BEGIN
    -- Insert étages (4 étages : RDC ordre 0, 1er ordre 1, 2e ordre 2, 3e ordre 3)
    INSERT INTO public.etages (id, nom, ordre) VALUES
        (rdc_id, 'RDC', 0),
        (premier_id, '1er étage', 1),
        (deuxieme_id, '2e étage', 2),
        (troisieme_id, '3e étage', 3);

    -- Insert types de locaux avec surfaces
    INSERT INTO public.types_locaux (id, nom, surface_m2) VALUES
        (boutique_9_id, 'Boutique 9m²', 9.00),
        (boutique_4_5_id, 'Boutique 4.5m²', 4.50),
        (restaurant_id, 'Restaurant', 25.00),
        (banque_id, 'Banque', 40.00),
        (box_id, 'Box', 2.00),
        (etal_id, 'Étal', 1.50);

    -- Insert 30 commerçants ivoiriens
    INSERT INTO public.commercants (nom, contact, activite, email) VALUES
        ('Aminata Traoré', '+225 07 12 34 56', 'Tissus et pagnes', 'aminata.traore@email.ci'),
        ('Kouassi Jean-Baptiste', '+225 07 23 45 67', 'Téléphones et accessoires', 'jbaptiste.kouassi@email.ci'),
        ('Fatou Diabaté', '+225 07 34 56 78', 'Chaussures femmes', 'fatou.diabate@email.ci'),
        ('Mamadou Sanogo', '+225 07 45 67 89', 'Électronique', 'mamadou.sanogo@email.ci'),
        ('Aïcha Koné', '+225 07 56 78 90', 'Coiffure et beauté', 'aicha.kone@email.ci'),
        ('Ibrahim Ouattara', '+225 07 67 89 01', 'Alimentation générale', 'ibrahim.ouattara@email.ci'),
        ('Mariam Bamba', '+225 07 78 90 12', 'Restaurant ivoirien', 'mariam.bamba@email.ci'),
        ('Seydou Coulibaly', '+225 07 89 01 23', 'Réparation mobiles', 'seydou.coulibaly@email.ci'),
        ('Kadiatou Keita', '+225 07 90 12 34', 'Produits cosmétiques', 'kadiatou.keita@email.ci'),
        ('Abou Traoré', '+225 07 01 23 45', 'Vêtements hommes', 'abou.traore@email.ci'),
        ('Salimata Diarra', '+225 07 12 34 67', 'Bijouterie', 'salimata.diarra@email.ci'),
        ('Moussa Diabaté', '+225 07 23 45 78', 'Maroquinerie', 'moussa.diabate@email.ci'),
        ('Fatoumata Sidibé', '+225 07 34 56 89', 'Fruits et légumes', 'fatoumata.sidibe@email.ci'),
        ('Bakary Fofana', '+225 07 45 67 90', 'Pièces automobiles', 'bakary.fofana@email.ci'),
        ('Awa Camara', '+225 07 56 78 01', 'Pharmacie', 'awa.camara@email.ci'),
        ('Lassana Doumbia', '+225 07 67 89 12', 'Matériaux construction', 'lassana.doumbia@email.ci'),
        ('Nana Touré', '+225 07 78 90 23', 'Pâtisserie', 'nana.toure@email.ci'),
        ('Drissa Konaté', '+225 07 89 01 34', 'Quincaillerie', 'drissa.konate@email.ci'),
        ('Adja Cissé', '+225 07 90 12 45', 'Mode enfantine', 'adja.cisse@email.ci'),
        ('Siaka Berté', '+225 07 01 23 56', 'Librairie papeterie', 'siaka.berte@email.ci'),
        ('Rokia Sangaré', '+225 07 12 34 78', 'Produits ménagers', 'rokia.sangare@email.ci'),
        ('Youssouf Dembélé', '+225 07 23 45 89', 'Optique lunetterie', 'youssouf.dembele@email.ci'),
        ('Aminata Konaté', '+225 07 34 56 90', 'Salon de coiffure', 'aminata.konate@email.ci'),
        ('Issouf Ouédraogo', '+225 07 45 67 01', 'Transfert d''argent', 'issouf.ouedraogo@email.ci'),
        ('Hawa Traoré', '+225 07 56 78 12', 'Vente de pagnes', 'hawa.traore@email.ci'),
        ('Amadou Bah', '+225 07 67 89 23', 'Cordonnerie', 'amadou.bah@email.ci'),
        ('Safiatou Diallo', '+225 07 78 90 34', 'Restaurant fast-food', 'safiatou.diallo@email.ci'),
        ('Boubacar Sissoko', '+225 07 89 01 45', 'Pressing nettoyage', 'boubacar.sissoko@email.ci'),
        ('Djénéba Koné', '+225 07 90 12 56', 'Mercerie couture', 'djeneba.kone@email.ci'),
        ('Adama Touré', '+225 07 01 23 67', 'Agence de voyage', 'adama.toure@email.ci');

    -- Préparer les arrays pour la distribution des locaux
    type_choices := ARRAY[boutique_9_id, boutique_4_5_id, restaurant_id, banque_id, box_id, etal_id];
    etage_choices := ARRAY[rdc_id, premier_id, deuxieme_id, troisieme_id];

    -- Insert 80 locaux répartis sur 4 étages
    i := 1;
    WHILE i <= 80 LOOP
        -- Déterminer l'étage et le type selon la répartition
        IF i <= 30 THEN  -- RDC: 30 locaux (A-001 à A-030)
            current_etage := rdc_id;
            local_numero := 'A-' || LPAD(i::TEXT, 3, '0');
        ELSIF i <= 60 THEN  -- 1er étage: 30 locaux (B-101 à B-130)
            current_etage := premier_id;
            local_numero := 'B-' || (100 + (i - 30))::TEXT;
        ELSIF i <= 80 THEN  -- 2e étage: 20 locaux (C-201 à C-220)
            current_etage := deuxieme_id;
            local_numero := 'C-' || (200 + (i - 60))::TEXT;
        END IF;
        
        -- Si on dépasse 80, on va au 3e étage pour les locaux suivants
        IF i > 80 THEN
            current_etage := troisieme_id;
            local_numero := 'D-' || (300 + (i - 80))::TEXT;
        END IF;

        -- Distribuer les types de façon variée
        current_type := type_choices[((i - 1) % 6) + 1];
        
        local_id := gen_random_uuid();
        
        -- Déterminer le statut (majorité Occupé, quelques Disponibles, 2-3 Maintenance)
        INSERT INTO public.locaux (id, numero, type_id, etage_id, statut) VALUES (
            local_id,
            local_numero,
            current_type,
            current_etage,
            CASE 
                WHEN i <= 70 THEN 'Occupé'::public.statut_local
                WHEN i <= 77 THEN 'Disponible'::public.statut_local
                ELSE 'Maintenance'::public.statut_local
            END
        );

        -- Créer un bail pour les locaux occupés et quelques commerçants
        IF i <= 50 THEN  -- 50 baux actifs
            commercant_id := (SELECT id FROM public.commercants ORDER BY random() LIMIT 1);
            contrat_numero := 'BL-2024-' || LPAD(i::TEXT, 3, '0');
            bail_id := gen_random_uuid();

            INSERT INTO public.baux (id, numero_contrat, local_id, commercant_id, date_debut, date_fin, montant_loyer, statut) VALUES (
                bail_id,
                contrat_numero,
                local_id,
                commercant_id,
                '2024-01-01'::DATE + (i || ' days')::INTERVAL,
                '2025-12-31'::DATE,
                CASE 
                    WHEN current_type = boutique_9_id THEN 150000 + (random() * 50000)::INTEGER
                    WHEN current_type = boutique_4_5_id THEN 75000 + (random() * 25000)::INTEGER
                    WHEN current_type = restaurant_id THEN 300000 + (random() * 100000)::INTEGER
                    WHEN current_type = banque_id THEN 500000
                    WHEN current_type = box_id THEN 30000 + (random() * 20000)::INTEGER
                    WHEN current_type = etal_id THEN 15000 + (random() * 10000)::INTEGER
                    ELSE 100000
                END,
                CASE 
                    WHEN i <= 40 THEN 'Actif'::public.statut_bail
                    WHEN i <= 45 THEN 'Expire bientôt'::public.statut_bail
                    ELSE 'Expiré'::public.statut_bail
                END
            );

            -- Créer 2-4 paiements par bail (150 paiements au total)
            FOR j IN 1..3 LOOP
                INSERT INTO public.paiements (bail_id, montant, date_echeance, date_paiement, mois_concerne, statut, mode_paiement) VALUES (
                    bail_id,
                    (SELECT montant_loyer FROM public.baux WHERE id = bail_id),
                    ('2024-10-01'::DATE + ((j-1) || ' month')::INTERVAL),
                    CASE 
                        WHEN (i + j) <= 100 THEN ('2024-10-' || LPAD(((i + j) % 28 + 1)::TEXT, 2, '0'))::DATE
                        ELSE NULL
                    END,
                    CASE j
                        WHEN 1 THEN 'oct-2024'
                        WHEN 2 THEN 'nov-2024'  
                        WHEN 3 THEN 'déc-2024'
                        ELSE 'jan-2025'
                    END,
                    CASE 
                        WHEN (i + j) <= 100 THEN 'Payé'::public.statut_paiement
                        WHEN (i + j) <= 130 THEN 'En attente'::public.statut_paiement
                        ELSE 'En retard'::public.statut_paiement
                    END,
                    (ARRAY['Espèces', 'Virement', 'Mobile Money', 'Chèque'])[(i % 4) + 1]::public.mode_paiement
                );
            END LOOP;
        END IF;

        i := i + 1;
    END LOOP;

    -- Ajouter 20 locaux supplémentaires au 3e étage (D-301 à D-320)
    FOR i IN 81..100 LOOP
        local_numero := 'D-' || (300 + (i - 80))::TEXT;
        current_type := type_choices[((i - 1) % 6) + 1];
        
        INSERT INTO public.locaux (numero, type_id, etage_id, statut) VALUES (
            local_numero,
            current_type,
            troisieme_id,
            CASE 
                WHEN i <= 95 THEN 'Occupé'::public.statut_local
                ELSE 'Disponible'::public.statut_local
            END
        );
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de l''insertion des données: %', SQLERRM;
END $$;