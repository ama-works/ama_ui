# Plan d'action complet — Intégration React NUI dans api_nativeui
## De A à Z, étape par étape

---

## 📋 CHECKLIST GLOBALE

- [ ] **Phase 1 :** Setup React (20 min)
- [ ] **Phase 2 :** Bridge Lua→React (10 min)
- [ ] **Phase 3 :** Test visuel sans FiveM (10 min)
- [ ] **Phase 4 :** Intégration FiveM (10 min)
- [ ] **Phase 5 :** Tests in-game (20 min)

**Total estimé : ~1h30**

---

## 🎯 PHASE 1 — Setup React (avec Claude Code)

### Étape 1.1 — Créer le dossier nui/

```bash
# Dans api_nativeui/
mkdir nui
cd nui
```

### Étape 1.2 — Init Vite + React

**Prompt pour Claude Code :**
```
Crée un projet Vite + React dans ce dossier (nui/).
Configuration :
- Template : react (pas TypeScript)
- Package manager : npm
- Ajoute Tailwind CSS avec PostCSS
```

**Ou manuellement :**
```bash
npm create vite@latest . -- --template react
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Étape 1.3 — Configurer Tailwind

**Fichier : `nui/tailwind.config.js`**

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        'char-bg': 'rgba(0, 0, 0, 0.7)',
        'char-border-cyan': '#08F7DB',
        'char-border-orange': '#FF6411',
        'char-border-yellow': '#F7FF0D',
        'char-green': '#00FF00',
        'char-gray': '#222222',
        'char-overlay': 'rgba(34, 34, 34, 0.8)',
      }
    }
  },
  plugins: []
}
```

**Fichier : `nui/src/index.css`**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: transparent;
  overflow: hidden;
}
```

### Étape 1.4 — Créer les composants

**Prompt pour Claude Code :**
```
@docs/brief_claude_code.md

Crée tous les composants React listés dans le brief :
- CharacterCreator.jsx (layout principal)
- ParentSelector.jsx
- SliderGradient.jsx
- ColorPicker.jsx
- TextInput.jsx
- ProgressBar.jsx
- CategoryButton.jsx
- ItemGrid.jsx
- CircleGraph.jsx
- StatsPanel.jsx
- PreviewPanel.jsx

Utilise exactement le code fourni dans le brief.
Place-les dans src/components/
```

### Étape 1.5 — Créer App.jsx

**Fichier : `nui/src/App.jsx`**

```jsx
import { useState, useEffect } from 'react'
import { CharacterCreator } from './components/CharacterCreator'

export default function App() {
  const [state, setState] = useState(null)

  useEffect(() => {
    const handler = (event) => {
      const { type, data } = event.data
      
      if (type === 'UPDATE_MENU') {
        setState(data)
      } else if (type === 'HIDE_MENU') {
        setState(null)
      }
    }
    
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  // Données de test (pour dev sans FiveM)
  if (!state) {
    // Décommenter pour test visuel
    // setState({ ... données mockées ... })
    return null
  }

  return <CharacterCreator state={state} />
}
```

### Étape 1.6 — Build de test

```bash
cd nui
npm run dev
# Ouvre http://localhost:5173
```

**✅ Checkpoint :** Tu devrais voir une page vide (normal, pas de données encore).

---

## 🔗 PHASE 2 — Bridge Lua→React

### Étape 2.1 — Copier nui_bridge.lua

**Fichier fourni :** `nui_bridge.lua` (déjà créé ci-dessus)

**Action :**
```bash
# Copie dans ton projet
cp nui_bridge.lua api_nativeui/client/
```

### Étape 2.2 — Modifier fxmanifest.lua

**Fichier : `api_nativeui/fxmanifest.lua`**

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

-- ▼ NOUVEAU : UI page
ui_page 'nui/dist/index.html'

client_scripts {
    'client/core/*.lua',
    'client/items/*.lua',
    'client/input/*.lua',
    'client/renderer/*.lua',
    'client/ui.lua',
    'client/nui_bridge.lua'  -- ▼ NOUVEAU
}

-- ▼ NOUVEAU : Fichiers NUI
files {
    'nui/dist/**/*'
}
```

### Étape 2.3 — Build React pour FiveM

```bash
cd nui
npm run build
# Génère nui/dist/
```

**✅ Checkpoint :** Le dossier `nui/dist/` existe avec `index.html`, `assets/`.

---

## 🧪 PHASE 3 — Test visuel sans FiveM

### Étape 3.1 — Ajouter des données mockées

**Fichier : `nui/src/App.jsx`** (temporaire pour dev)

```jsx
// UNIQUEMENT POUR LE DEV — À ENLEVER APRÈS
const MOCK_DATA = {
  mom: "elizabeth",
  dad: "benjamin",
  resemblance1: 50,
  resemblance2: 80,
  skinTone: 1,
  name: "Jhon Dhoe",
  nose: 50,
  category: "face",
  items: [
    { label: "Cheeks 1", value: 0 },
    { label: "Cheeks 2", value: 0 },
    { label: "Hair 1", value: 0 },
    { label: "Hair 2", value: 0 },
    { label: "Makeup 1", value: 0 },
    { label: "Makeup 2", value: 0 },
    { label: "Blush 1", value: 0 },
    { label: "Blush 2", value: 0 },
  ],
  stats: {
    sex: "F / M",
    id: 1,
    job: "unemployed",
    money: 10,
    maxMoney: 100,
    date: "12/04/1978",
    gender: "Male"
  },
  momPercent: 28,
  dadPercent: 89
}

export default function App() {
  const [state, setState] = useState(MOCK_DATA)  // ← utilise les mocks
  // ... reste du code
}
```

### Étape 3.2 — Test visuel

```bash
cd nui
npm run dev
# Ouvre http://localhost:5173
```

**✅ Checkpoint :** Tu vois l'interface complète du créateur de personnage.

**Vérifie :**
- [ ] Panel gauche avec tous les contrôles
- [ ] Sliders avec gradient orange→rouge
- [ ] Grille 2×4 items
- [ ] Graphique circulaire (droite)
- [ ] Stats panel (droite)

### Étape 3.3 — Enlever les mocks

Une fois validé visuellement, **enlève les données mockées** :

```jsx
export default function App() {
  const [state, setState] = useState(null)  // ← remet null
  // ... reste
}
```

### Étape 3.4 — Build final

```bash
npm run build
```

---

## 🎮 PHASE 4 — Intégration FiveM

### Étape 4.1 — Créer un menu de test

**Fichier : `client/test_character.lua`**

```lua
-- Test du menu création de personnage avec NUI

CreateThread(function()
    Wait(1000)
    
    local menu = NativeUI.CreateMenu("Character", "Creator")
    
    -- Mom/Dad selectors
    menu:List("Mom", {"elizabeth", "hannah", "audrey"}, 1, "")
    menu:List("Dad", {"benjamin", "daniel", "joshua"}, 1, "")
    
    -- Sliders ressemblance
    menu:SliderProgress("Ressemblance 1", 50, 100, "", { step = 1 })
    menu:SliderProgress("Ressemblance 2", 80, 100, "", { step = 1 })
    
    -- Skin tone
    menu:Slider("Skin tone", 1, 10, "", { step = 1 })
    
    -- Name (button pour l'instant)
    menu:Button("Name", "Jhon Dhoe")
    
    -- Nose progress
    menu:Progress("Nose", 50, 100, "", { step = 1 })
    
    -- Catégories
    menu:Separator("── Categories ──")
    menu:Button("Visage", "")
    menu:Button("Hair", "")
    menu:Button("Makeup", "")
    
    -- Commande de test
    RegisterCommand("testchar", function()
        menu:Toggle()
    end, false)
    
    print("^2[Test] Menu création perso prêt — tape /testchar^7")
end)
```

**Ajoute dans fxmanifest.lua :**
```lua
client_scripts {
    -- ... autres scripts
    'client/test_character.lua'
}
```

### Étape 4.2 — Restart la ressource

```
restart api_nativeui
```

### Étape 4.3 — Test in-game

1. Lance FiveM
2. Connecte-toi au serveur
3. Tape `/testchar` dans F8
4. **Tu devrais voir l'interface React s'afficher**

**✅ Checkpoint :** L'interface React apparaît avec les données du menu Lua.

---

## 🐛 PHASE 5 — Tests et debug

### Test 1 — Navigation clavier

- [ ] Flèche haut/bas change l'item sélectionné
- [ ] L'affichage React se met à jour

### Test 2 — Sliders

- [ ] Flèche gauche/droite change la valeur
- [ ] La barre React bouge en temps réel

### Test 3 — Fermeture

- [ ] ESC ferme le menu
- [ ] L'interface React disparaît

### Test 4 — Console F8

```
debugmenu
```

Devrait afficher l'état JSON du menu dans la console.

---

## 🔧 TROUBLESHOOTING

### Problème : Écran noir, rien ne s'affiche

**Solution :**
```bash
# Vérifie que le build existe
ls api_nativeui/nui/dist/index.html

# Si pas là, rebuild
cd nui
npm run build
```

### Problème : Interface figée (pas de mise à jour)

**Solution :**
Vérifie dans `nui_bridge.lua` que `Menu.useNUI = true`

### Problème : Erreur "Cannot find module"

**Solution :**
```bash
cd nui
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Problème : Les couleurs sont bizarres

**Solution :**
Vérifie `tailwind.config.js` avec les couleurs custom.

---

## 📦 FICHIERS FINAUX À AVOIR

```
api_nativeui/
├─ client/
│  ├─ core/
│  ├─ items/
│  ├─ nui_bridge.lua          ✅ NOUVEAU
│  └─ test_character.lua      ✅ NOUVEAU (test)
│
├─ nui/
│  ├─ src/
│  │  ├─ App.jsx              ✅ NOUVEAU
│  │  ├─ main.jsx
│  │  ├─ index.css            ✅ MODIFIÉ (Tailwind)
│  │  └─ components/          ✅ NOUVEAU (11 composants)
│  │
│  ├─ dist/                   ✅ GÉNÉRÉ (npm run build)
│  ├─ package.json            ✅ NOUVEAU
│  ├─ vite.config.js          ✅ NOUVEAU
│  └─ tailwind.config.js      ✅ NOUVEAU
│
├─ fxmanifest.lua             ✅ MODIFIÉ (ui_page, files)
└─ docs/
   ├─ brief_claude_code.md    ✅ RÉFÉRENCE
   └─ Frame_3_gradientbg.png  ✅ RÉFÉRENCE
```

---

## 🎯 CHECKLIST FINALE

- [ ] `nui/dist/` existe avec les fichiers buildés
- [ ] `client/nui_bridge.lua` présent
- [ ] `fxmanifest.lua` modifié avec `ui_page` et `files`
- [ ] Test `/testchar` in-game fonctionne
- [ ] Interface React s'affiche
- [ ] Navigation clavier met à jour React
- [ ] Fermeture ESC fait disparaître l'UI

---

## 🚀 NEXT STEPS (après validation)

1. **Supprimer `test_character.lua`** (c'était juste pour tester)
2. **Intégrer dans ton vrai menu** de création de personnage
3. **Ajouter les autres menus** (bank, inventory, etc.)
4. **Améliorer CircleGraph.jsx** avec un vrai SVG animé
5. **Ajouter des transitions** CSS (fade in/out)

---

## 💡 TIPS

- **Dev rapide :** Utilise `npm run dev` pour voir les changements sans rebuild
- **Debug :** Commande `/debugmenu` pour voir l'état JSON
- **Fallback :** `Menu.useNUI = false` pour revenir au DrawRect natif
- **Performance :** Le NUI ne ralentit pas, c'est du GPU (CEF/Chromium)

C'est tout ! Suis ce plan étape par étape et ça devrait marcher. 🎉
