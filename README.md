# ReserVite — PRBD 2526 (groupe C06)

Application de **réservation de restaurants** développée dans le cadre du cours **PRBD** (Programmation Base de Données) à l’EPFC.

Les clients peuvent rechercher un restaurant, consulter ses infos et réserver une table.  
Les managers gèrent les tables, les services horaires et les réservations de leur(s) établissement(s).

---

## Équipe

| Membre | Rôle |
|--------|------|
| Zié Alassane Traoré | Développement |
| Sam Prophete Nsengimana | Développement |

Groupe **C06** — année académique **2025–2026**.

---

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | **Flutter** (Dart) + **Riverpod** |
| API | **PostgREST** (API REST générée depuis PostgreSQL) |
| Base de données | **PostgreSQL** |
| Auth | JWT (rôles `client` / `manager`) |
| Règles métier | Triggers, contraintes et fonctions PL/pgSQL |

L’architecture repose sur le principe *database-centric* : la logique métier et les contrôles d’accès vivent dans PostgreSQL ; PostgREST expose les endpoints ; Flutter consomme l’API.

---

## Fonctionnalités

### Client
- Inscription / connexion
- Recherche de restaurants (ville, critères)
- Consultation du détail d’un restaurant (horaires, tables, description)
- Création et suivi de réservations
- Demande VIP / demandes spéciales

### Manager
- Tableau de bord des réservations
- Confirmation / annulation / clôture des réservations
- Assignation de tables
- Gestion des tables (capacité, table signature)
- Gestion des services (jours et créneaux horaires)

### Backend (PostgreSQL)
- Contrôle de capacité et conflits de réservation
- Transitions de statut (`pending` → `confirmed` → `completed` / `cancelled`)
- Vérification des horaires de service
- Rôles et politiques d’accès (RLS / grants PostgREST)
- Fonction de réinitialisation de la base (`reset_database`)

---

## Structure du dépôt

```
prbd-2526-c06/
├── frontend/          # Application Flutter
│   └── lib/
│       ├── app/       # Bootstrap / thème
│       ├── core/      # API client, widgets partagés
│       ├── model/     # Modèles de données
│       ├── providers/ # État Riverpod
│       └── views/     # Pages client, manager, auth
├── backend/
│   └── scripts/       # Scripts SQL (schéma, BR, endpoints)
├── scripts/           # Scripts bash (Postgres + PostgREST)
├── postgrest.conf     # Configuration PostgREST
└── data/              # Données locales Postgres (non versionnées)
```

---

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK ≥ 3.38)
- [PostgreSQL](https://www.postgresql.org/) (outils `initdb`, `pg_ctl`, `psql`, `createuser`, `createdb` dans le `PATH`)
- [PostgREST](https://postgrest.org/) installé et accessible en ligne de commande

---

## Lancer le projet

### 1. Backend (PostgreSQL + PostgREST)

Si besoin, créez la config locale :

```bash
cp postgrest.conf.example postgrest.conf
# éditez le mot de passe et le jwt-secret
```

Depuis le dossier `scripts/` :

```bash
cd scripts
./postgrest-start.sh
```

Ce script initialise la base si besoin, démarre PostgreSQL, puis lance PostgREST sur le port **3000**.

Pour arrêter :

```bash
./postgrest-stop.sh
```

Réinitialisation complète de la base (suppression du dossier `data/` puis ré-init) :

```bash
./pg-init.sh
./pg-start.sh
# puis relancer PostgREST
```

### 2. Frontend Flutter

```bash
cd frontend
flutter pub get
flutter run -d macos   # ou chrome / windows selon la plateforme
```

L’API attendue est `http://127.0.0.1:3000`.

---

## Comptes de démonstration

Mot de passe commun : `Password1,`

| Email | Rôle |
|-------|------|
| `client@epfc.eu` | Client |
| `manager@epfc.eu` | Manager |
| `xapigeolet@epfc.eu` | Client |
| `boverhaegen@epfc.eu` | Manager |

Des raccourcis de connexion rapide sont aussi disponibles sur l’écran de login.

---

## Scripts SQL (backend)

Les scripts dans `backend/scripts/` s’exécutent dans l’ordre numérique :

| Préfixe | Contenu |
|---------|---------|
| `01_` / `02_` | Init + sécurité / utilisateurs |
| `03_` | Tables et données de démo |
| `04.*` | Business rules (triggers, checks) |
| `05.*` | Endpoints PostgREST (fonctions / vues) |

---

## Remarques pour une publication publique

- Le dossier `data/` (instance locale Postgres) est ignoré par Git — ne pas le committer.
- Copiez `postgrest.conf.example` vers `postgrest.conf` et adaptez le mot de passe DB / le JWT. Le fichier local `postgrest.conf` n’est pas versionné.
- Projet pédagogique : les mots de passe de démo sont intentionnellement simples.
