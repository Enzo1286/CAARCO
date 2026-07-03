# GUIDE_COWORK.md — CAARCO
# Comment utiliser Claude Cowork pour continuer le projet
# Cedric Timene — Mai 2026

═══════════════════════════════════════════════════════
  QU'EST-CE QUE CLAUDE COWORK ?
═══════════════════════════════════════════════════════

Claude Cowork est une application desktop de Claude
qui peut accéder à tes fichiers locaux, automatiser
des tâches répétitives et continuer à travailler
même quand tu dors ou es occupé ailleurs.

C'est différent de Claude Code (terminal) :
- Claude Code   → tu travailles AVEC Claude en temps réel
- Claude Cowork → Claude travaille POUR toi en autonomie

Pour CAARCO, tu peux configurer Cowork pour :
→ Continuer le développement d'un module pendant la nuit
→ Faire la review du code pendant que tu dors
→ Générer automatiquement les écrans selon les specs
→ Mettre à jour MEMORY.md en continu

═══════════════════════════════════════════════════════


## ÉTAPE 1 — Installer Claude Cowork

```
1. Aller sur : https://claude.ai/desktop
   ou chercher "Claude Desktop" sur Google
2. Télécharger la version Windows/Mac
3. Installer et se connecter avec ton compte claude.ai
4. Dans les paramètres → connecter ton dossier projet CAARCO
```


## ÉTAPE 2 — Configurer Cowork pour CAARCO

Dans Claude Cowork, crée une "tâche" avec ce prompt :

```
═══════════════════════════════════════
TÂCHE COWORK CAARCO — DÉVELOPPEMENT
═══════════════════════════════════════

Contexte :
Tu es l'agent de développement de CAARCO.
Le projet est dans le dossier : [chemin vers /caarco]

À chaque démarrage de cette tâche :
1. Lire /caarco/CLAUDE.md et /caarco/MEMORY.md
2. Scanner le projet (/scan)
3. Identifier la prochaine étape dans la roadmap
4. La développer selon les règles de CLAUDE.md
5. Mettre à jour MEMORY.md avec ce qui a été fait
6. Laisser un rapport dans /caarco/RAPPORT_COWORK.md

Règles absolues :
- Ne jamais modifier les fichiers .env
- Ne jamais commiter sur Git sans permission explicite
- Toujours respecter les tokens Atelier CAARCO
- Toujours calculer les prix côté serveur
- Si un checkpoint est atteint → s'arrêter et noter
  dans RAPPORT_COWORK.md : "EN ATTENTE DÉCISION CEDRIC : [question]"

Stack : React Native Expo + Supabase + Moneroo
Monnaie : XAF (entiers uniquement)
Langue : Français

GO !
```


## ÉTAPE 3 — Tâches que Cowork peut faire sans toi

### Tâches autonomes (Cowork peut les faire seul)
```
✅ Créer les composants UI à partir des specs Atelier CAARCO
✅ Écrire les types TypeScript (types/index.ts)
✅ Créer les hooks React (useAuth, useCourse, useLocation)
✅ Écrire le code des Edge Functions Supabase
✅ Faire la review du code existant
✅ Écrire les tests unitaires
✅ Mettre à jour MEMORY.md
✅ Générer la documentation technique
✅ Créer les migrations SQL Supabase
✅ Optimiser les performances (bundle size, lazy loading)
```

### Tâches qui nécessitent ton accord (checkpoints)
```
⚠️ TOUJOURS demander avant de :
- Modifier le flux d'authentification
- Changer la formule de calcul du prix
- Modifier les politiques RLS Supabase
- Intégrer un nouveau service externe
- Soumette au Play Store
- Modifier les conditions générales
```


## ÉTAPE 4 — Fichier RAPPORT_COWORK.md

Cowork laissera ce fichier à chaque session autonome.
Format :

```markdown
# RAPPORT COWORK — [date et heure]

## CE QUI A ÉTÉ FAIT
- ✅ [Tâche 1 complétée]
- ✅ [Tâche 2 complétée]

## CE QUI RESTE
- 📋 [Tâche 3 à faire]

## EN ATTENTE DE DÉCISION CEDRIC
- ⚠️ [Question ou choix à faire]

## BUGS TROUVÉS
- 🐛 [Bug 1 : description + fichier:ligne]

## PROCHAINE ÉTAPE
→ [Ce que Claude fera à la prochaine session Cowork]
```


## ÉTAPE 5 — Workflow optimal CAARCO

### Le matin (avec toi)
```
1. Tu ouvres VS Code + Claude Code
2. Claude scanne le rapport Cowork de la nuit
3. Tu valides les checkpoints en attente
4. Vous travaillez ensemble sur les parties complexes
   (UX, business logic, intégration Moneroo...)
5. Tu testes sur ton téléphone
```

### L'après-midi (sans toi si tu es épuisé)
```
1. Tu lances Cowork avec la tâche CAARCO
2. Cowork continue les tâches autonomes
   (composants, tests, docs, Edge Functions...)
3. Tu reviens voir le rapport en fin de journée
4. Tu valides les décisions en attente
```

### La nuit (autonome)
```
1. Cowork peut continuer certaines tâches en arrière-plan
2. Le matin, tu trouves un rapport détaillé
3. Gain de temps estimé : 3-4 heures de développement par nuit
```


## LIMITATIONS IMPORTANTES DE COWORK

```
❌ Cowork ne peut PAS :
- Créer des comptes sur des services externes (Supabase, Moneroo...)
- Payer des services (Play Store, Apple Developer...)
- Tester sur un appareil physique réel
- Valider l'expérience utilisateur réelle
- Prendre des décisions stratégiques à ta place
- Contourner les règles de CLAUDE.md

✅ Cowork PEUT :
- Écrire du code selon les spécifications
- Corriger des bugs identifiés
- Générer des fichiers SQL, TypeScript, JSON
- Mettre à jour la documentation
- Analyser le code existant
- Proposer des améliorations
```


## CONSEIL CEDRIC

La combinaison la plus efficace pour CAARCO :

```
MATIN   → Claude Code (toi + Claude, travail collaboratif)
MIDI    → Toi seul (tests, Supabase Dashboard, Moneroo Dashboard)
SOIR    → Claude Code (finalisation, review, corrections)
NUIT    → Cowork (tâches autonomes pendant que tu dors)
```

Ce rythme peut diviser par 2 le temps de développement
tout en gardant le contrôle sur les décisions importantes.

Objectif : beta Cameroun en Q3 2026. C'est atteignable
avec cette organisation. 🚀
```
