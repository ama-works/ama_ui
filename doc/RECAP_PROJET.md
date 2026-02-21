# 🦖 DINOSARUS — Récap Global du Projet
*Dernière mise à jour : Février 2026*

---

## 🗂️ CHATS IMPORTANTS À GARDER

| Sujet | Lien |
|---|---|
| NUI couche React + prompt `creation_personnage.md` | https://claude.ai/chat/ca86cf48-6bc2-40a9-bec6-cb08f37ef4db |
| ESX restructuré + organisation fonctions par groupe | https://claude.ai/chat/4e19d6ab-414e-4591-8182-056bd8664cfd |
| Docusaurus ama_ui — setup + config de base | https://claude.ai/chat/d283da5a-8b17-4801-9a42-9c6b3d60e6e7|
| Framework standalone AMA (spawn + position) | https://claude.ai/chat/89e1612b-f49c-4ac0-a307-7aa1305ffd5d |
| Agents Claude Code (7 agents créés) | Chat actuel |

---

## 📦 PROJETS EN COURS

### 1. NativeUI (renommage en cours)
**État :** API Lua existante et fonctionnelle, couche NUI React à développer
**Fichier clé :** `creation_personnage.md` (prompt complet Phase 1→6)
**Prochaine tâche :** Installer les 7 agents Claude Code + démarrer Phase 1 Setup
**À faire :**
- [ ] Renommer `api_nativeui` → nouveau nom
- [ ] Créer dossier `web/` + setup Vite + React + TS + Tailwind
- [ ] Créer `nui_bridge.lua`
- [ ] Implémenter config `use_nui / use_drawrect` dans `config.lua`

**Architecture hybride :**
```
API Lua (GARDER)          →  Menus simples (DrawRect)
Couche NUI React (AJOUTER) →  Interfaces complexes (character creator, etc.)
```

---

### 2. Framework Standalone (Dinosarus Framework)
**État :** Base ESX restructurée pour les tests, standalone prévu après
**Prochaine tâche :** Régler bug `RegisterClientCallback nil` dans `es_extended/client/functions.lua:711`
**À faire :**
- [ ] Fix bug RegisterClientCallback
- [ ] Finir organisation fonctions par groupe (ped, vehicle, notifications, ui, utils)
- [ ] Bridge ESX / QBCore
- [ ] Migrer vers standalone après validation

---

### 3. Docusaurus (Documentation)
**État :** Installé en local (`C:\Users\Pc Gaming\ama_ui`), config de base faite
**Prochaine tâche :** Pousser sur GitHub Pages pour mise en ligne
**À faire :**
- [ ] Créer nouveau compte GitHub dédié Dinosarus
- [ ] Pousser `ama_ui` sur ce repo
- [ ] Activer GitHub Pages → URL publique
- [ ] Rédiger contenu : Introduction, Installation, Composants (Button, List, Checkbox, Slider)
- [ ] Acheter domaine (`dinosarus.gg` ou `dinosarus.dev`) dans le futur

---

### 4. Setup Infrastructure
**État :** À créer
**À faire :**
- [ ] Nouveau compte GitHub dédié Dinosarus
- [ ] Organisation GitHub `DinosaurusRP` ou similaire
- [ ] Compte Zoho Mail avec domaine
- [ ] Compte Discord dédié + serveur communautaire
- [ ] Page profil GitHub (README)
- [ ] Connecter GitHub à Claude.ai

---

### 5. Bot Discord (Python)
**État :** Idée, pas commencé
**Stack :** Python + `discord.py`
**Fonctionnalités prévues :**
- Annonces auto quand push GitHub
- Système de tickets support
- Commandes pour consulter la doc
- Notifications statut serveur FiveM

---

## 🤖 AGENTS CLAUDE CODE (Prêts à installer)
Placer dans `.claude/agents/` du projet :

| Agent | Fichier | Rôle |
|---|---|---|
| ✅ Lua FiveM | `lua-fivem.md` | Code Lua client/serveur |
| ✅ React NUI | `react-nui.md` | Composants React + bridge |
| ✅ TypeScript | `typescript-expert.md` | Types, interfaces |
| ✅ CSS/Tailwind | `css-tailwind.md` | Styles, design gaming |
| ✅ SQL | `sql-database.md` | MySQL + oxmysql |
| ✅ Prompt Engineer | `prompt-engineer.md` | Rédiger des prompts efficaces |
| ✅ Architecte | `fivem-architect.md` | Vision globale, structure |

**Agents à créer plus tard :**
- `figma-to-code.md` — Import direct depuis Figma
- `optimization-expert.md` — Audit perf DrawRect vs NUI
- `github-sync.md` — Workflow Git propre
- `docusaurus-agent.md` — Rédaction doc
- `discord-bot.md` — Python discord.py

---

## 💡 DÉCISIONS TECHNIQUES PRISES
- **Hybride Lua + React** : Lua pour la perf native, React pour les UI complexes
- **Config `use_nui / use_drawrect`** : Choix par menu dans `config.lua`
- **ESX pour démarrer** : Base connue pour la template publique, standalone après
- **Docusaurus** : Choix final pour la documentation (pas Gitbook)
- **Zoho Mail** : Alternative à Google Workspace pour les mails pro
- **GitHub Pages** : Hébergement gratuit en attendant le domaine custom
