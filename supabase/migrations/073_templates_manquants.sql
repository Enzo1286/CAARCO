-- Migration 073 — Ajout des 2 templates de notification manquants
-- candidature_acceptee_tr : client sélectionne un TR spécifique (ProfilTransporteurScreen)
-- transporteur_arrive_destination : TR signale son arrivée à la destination (NavigationScreen)

INSERT INTO notification_templates (cle, groupe, description, variables, titre, corps)
VALUES

('candidature_acceptee_tr', 'course_tr',
 'Envoyé au transporteur quand un client choisit spécifiquement son profil parmi les candidats.',
 ARRAY['{nom}'],
 '🎉 Candidature retenue !',
 'Bonne nouvelle {nom} ! Un client a choisi votre profil. Rendez-vous au point de départ.'
),

('transporteur_arrive_destination', 'course_client',
 'Envoyé au client quand le TR signale son arrivée au point de livraison.',
 ARRAY['{nom}', '{nom_tr}'],
 '✅ Livraison effectuée !',
 'Bonjour {nom} ! {nom_tr} est arrivé à destination. Confirmez la réception depuis votre application.'
)

ON CONFLICT (cle) DO NOTHING;
