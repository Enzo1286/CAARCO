-- Permet aux événements DELETE de Supabase Realtime de transporter les données
-- de la ligne supprimée (nécessaire pour retirer les courses annulées chez les TRs).
ALTER TABLE courses REPLICA IDENTITY FULL;
