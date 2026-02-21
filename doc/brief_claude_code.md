# Brief pour Claude Code — NUI React Création de personnage
## Contexte projet

Tu travailles sur `api_nativeui`, une API de menu FiveM en Lua (déjà fonctionnelle).
L'objectif est d'ajouter une couche NUI React pour le rendu visuel uniquement.
**La logique métier reste en Lua** — React ne fait qu'afficher l'état.

---

## Architecture cible

```
api_nativeui/
├─ client/                    # Lua existant (NE PAS TOUCHER)
│  ├─ core/menu.lua
│  ├─ items/*.lua
│  └─ nui_bridge.lua         # À CRÉER (sérialise état Lua → NUI)
│
├─ nui/                       # À CRÉER (React)
│  ├─ src/
│  │  ├─ App.jsx
│  │  ├─ main.jsx
│  │  ├─ index.css
│  │  └─ components/
│  │     ├─ CharacterCreator.jsx
│  │     ├─ ParentSelector.jsx
│  │     ├─ SliderGradient.jsx
│  │     ├─ ColorPicker.jsx
│  │     ├─ TextInput.jsx
│  │     ├─ ProgressBar.jsx
│  │     ├─ CategoryButton.jsx
│  │     ├─ ItemGrid.jsx
│  │     ├─ CircleGraph.jsx
│  │     ├─ StatsPanel.jsx
│  │     └─ PreviewPanel.jsx
│  │
│  ├─ package.json
│  ├─ vite.config.js
│  └─ tailwind.config.js
│
└─ fxmanifest.lua            # À MODIFIER (ajouter ui_page)
```

---

## Stack technique

```json
{
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "vite": "^5.1.0"
  }
}
```

**Pas de TypeScript, juste JSX.**

---

## Design de référence

Voir le fichier `Frame_3_gradientbg.png` (joint).

**Palette de couleurs extraite :**

```js
// tailwind.config.js
module.exports = {
  content: ['./index.html', './src/**/*.{js,jsx}'],
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

---

## Composants à créer (ordre de priorité)

### 1. CharacterCreator.jsx (Layout principal)

**Props :** `{ state }` (vient de Lua via SendNUIMessage)

**Structure :**
```jsx
<div className="flex h-screen">
  <aside className="w-[560px] bg-char-bg border-2 border-char-border-cyan p-4 space-y-2">
    {/* Tous les contrôles */}
  </aside>
  <main className="flex-1 relative">
    {/* Preview 3D + graphique circulaire + stats */}
  </main>
</div>
```

**État reçu de Lua :**
```js
{
  mom: "elizabeth",
  dad: "benjamin",
  resemblance1: 50,      // 0-100
  resemblance2: 80,      // 0-100
  skinTone: 1,
  name: "Jhon Dhoe",
  nose: 50,              // 0-100
  category: "face",      // "face" | "hair" | "makeup" | "beard" | "skin" | "clothes"
  items: [
    { label: "Cheeks 1", value: 0 },
    { label: "Cheeks 2", value: 0 },
    // ... (8 items max affichés)
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
  momPercent: 28,        // pour le graphique circulaire
  dadPercent: 89
}
```

---

### 2. ParentSelector.jsx

**Props :** `{ label, value, icon }`

**Visuel :**
```
┌────────────────────────────────────────┐
│ ▶ Mom      ◀  elizabeth  ▶            │
└────────────────────────────────────────┘
```

**Code :**
```jsx
export function ParentSelector({ label, value, icon }) {
  return (
    <div className="flex items-center h-9 bg-char-overlay border border-char-border-orange rounded px-4">
      <span className="text-char-border-orange text-sm mr-2">{icon}</span>
      <span className="text-white text-sm">{label}</span>
      <div className="flex-1" />
      <button className="text-white text-lg hover:text-char-border-orange">◀</button>
      <span className="text-white text-sm mx-4 min-w-[100px] text-center">{value}</span>
      <button className="text-white text-lg hover:text-char-border-orange">▶</button>
    </div>
  )
}
```

**Note :** Les boutons sont **purement visuels**, pas de `onClick`. Les inputs sont gérés par Lua.

---

### 3. SliderGradient.jsx

**Props :** `{ label, value, icon1, icon2 }`

**Visuel :**
```
┌────────────────────────────────────────┐
│ Ressemblance : 1  👤 [████▌░░░] 👩  │
└────────────────────────────────────────┘
```

**Code :**
```jsx
export function SliderGradient({ label, value, icon1, icon2 }) {
  const percentage = value // 0-100
  
  return (
    <div className="flex items-center h-9 bg-char-overlay border border-char-border-orange rounded px-4">
      <span className="text-white text-sm mr-2">{label}</span>
      <span className="text-xl">{icon1}</span>
      
      {/* Barre avec gradient orange→rouge */}
      <div className="flex-1 mx-2 relative h-3 bg-gray-600 border border-char-border-orange rounded-sm overflow-hidden">
        {/* Partie remplie */}
        <div 
          className="absolute left-0 top-0 h-full bg-gradient-to-r from-orange-500 to-red-600 transition-all duration-150"
          style={{ width: `${percentage}%` }}
        />
        {/* Curseur vert */}
        <div 
          className="absolute top-1/2 -translate-y-1/2 w-1 h-5 bg-char-green"
          style={{ left: `${percentage}%`, transform: 'translateY(-50%)' }}
        />
      </div>
      
      <span className="text-xl">{icon2}</span>
    </div>
  )
}
```

---

### 4. ColorPicker.jsx

**Props :** `{ label, value }`

**Visuel :**
```
┌────────────────────────────────────────┐
│ Skin tone      ◀  Color: (1)  ▶      │
└────────────────────────────────────────┘
```

**Code :**
```jsx
export function ColorPicker({ label, value }) {
  return (
    <div className="flex items-center h-9 bg-char-overlay border border-char-border-orange rounded px-4">
      <span className="text-white text-sm">{label}</span>
      <div className="flex-1" />
      <button className="text-white text-lg">◀</button>
      <span className="text-white text-sm mx-4">Color: ({value})</span>
      <button className="text-white text-lg">▶</button>
    </div>
  )
}
```

---

### 5. TextInput.jsx

**Props :** `{ label, value }`

**Visuel :**
```
┌────────────────────────────────────────┐
│ Name                    Jhon Dhoe     │
└────────────────────────────────────────┘
```

**Code :**
```jsx
export function TextInput({ label, value }) {
  return (
    <div className="flex items-center justify-between h-9 bg-char-overlay border border-char-border-orange rounded px-4">
      <span className="text-white text-sm">{label}</span>
      <span className="text-white text-sm">{value}</span>
    </div>
  )
}
```

---

### 6. ProgressBar.jsx

**Props :** `{ label, value, segments }`

**Visuel :**
```
┌──────────────────────────────────────────────┐
│ Nose : [████][████][████][░░░░][░░░░][░░░░] │
└──────────────────────────────────────────────┘
```

**Code :**
```jsx
export function ProgressBar({ label, value, segments = 6 }) {
  const filled = Math.floor((value / 100) * segments)
  
  return (
    <div className="flex items-center gap-2 h-8">
      <span className="text-white text-sm">{label}</span>
      <div className="flex-1 flex gap-1">
        {Array.from({ length: segments }).map((_, i) => (
          <div 
            key={i}
            className={`flex-1 h-6 border border-char-border-yellow ${
              i < filled ? 'bg-char-border-yellow' : 'bg-gray-700'
            }`}
          />
        ))}
      </div>
    </div>
  )
}
```

---

### 7. CategoryButton.jsx

**Props :** `{ label, active }`

**Visuel :**
```
┌──────────────────┐
│ ▶ Visage    ⊙  │  ← actif (bordure orange + toggle activé)
└──────────────────┘
```

**Code :**
```jsx
export function CategoryButton({ label, active }) {
  return (
    <div className={`
      flex items-center justify-between h-10 px-3 rounded
      ${active 
        ? 'bg-char-overlay border-2 border-char-border-orange' 
        : 'bg-char-gray border border-gray-600'
      }
    `}>
      <span className={`text-sm ${active ? 'text-white font-semibold' : 'text-gray-400'}`}>
        ▶ {label}
      </span>
      {/* Toggle rond */}
      <div className={`w-8 h-5 rounded-full relative ${
        active ? 'bg-char-border-orange' : 'bg-gray-600'
      }`}>
        <div className={`w-4 h-4 rounded-full bg-white absolute top-0.5 transition-all ${
          active ? 'right-0.5' : 'left-0.5'
        }`} />
      </div>
    </div>
  )
}
```

---

### 8. ItemGrid.jsx

**Props :** `{ items }` — array de `{ label, value }`

**Visuel :**
```
┌────────────────────┬────────────────────┐
│ ⊖  Cheeks 1    ⊕  │ ⊖  Hair 1      ⊕  │
├────────────────────┼────────────────────┤
│ ⊖  Cheeks 2    ⊕  │ ⊖  Hair 2      ⊕  │
└────────────────────┴────────────────────┘
```

**Code :**
```jsx
export function ItemGrid({ items }) {
  return (
    <div className="grid grid-cols-2 gap-2">
      {items.map((item, i) => (
        <div 
          key={i}
          className="flex items-center justify-between bg-gray-800 border-2 border-char-border-yellow rounded p-2 h-10"
        >
          <button className="text-white text-xl w-6 h-6 flex items-center justify-center hover:text-char-border-yellow">
            ⊖
          </button>
          <span className="text-char-border-yellow text-sm font-semibold">
            {item.label}
          </span>
          <button className="text-white text-xl w-6 h-6 flex items-center justify-center hover:text-char-border-yellow">
            ⊕
          </button>
        </div>
      ))}
    </div>
  )
}
```

---

### 9. CircleGraph.jsx

**Props :** `{ mom, dad }`

**Visuel :**
```
┌─────────────────┐
│      ◯         │  ← cercle vert néon
│  Mom : 28%     │
│  Dad : 89%     │
└─────────────────┘
```

**Code (simplifié, SVG basic) :**
```jsx
export function CircleGraph({ mom, dad }) {
  return (
    <div className="absolute top-4 right-4 w-48 bg-char-overlay border border-char-border-cyan rounded p-3">
      {/* Cercle simplifié */}
      <div className="w-24 h-24 mx-auto mb-2 rounded-full border-4 border-char-green bg-black" />
      
      <div className="text-white text-xs space-y-1">
        <p>parents resemblance :</p>
        <p>→ Mom : {mom}%</p>
        <p>→ Dad : {dad}%</p>
      </div>
    </div>
  )
}
```

**Note :** Pour un vrai graphique circulaire, utilise SVG avec `<circle>` + `stroke-dasharray`.

---

### 10. StatsPanel.jsx

**Props :** `{ stats }`

**Code :**
```jsx
export function StatsPanel({ stats }) {
  return (
    <div className="absolute top-20 right-4 bg-char-overlay border border-char-border-orange rounded p-3 w-48 text-white text-xs space-y-1">
      <div className="flex justify-between">
        <span>Sex :</span>
        <span>{stats.sex}</span>
      </div>
      <div className="flex items-center gap-2">
        <span>Character</span>
        <button className="text-lg">⊕</button>
      </div>
      <div className="flex justify-between">
        <span>John Doe :</span>
        <span>id ({stats.id})</span>
      </div>
      <div className="flex justify-between">
        <span>Job :</span>
        <span>{stats.job}</span>
      </div>
      <div className="flex justify-between">
        <span>Money :</span>
        <span>{stats.money}$ / {stats.maxMoney}$</span>
      </div>
      <div className="flex justify-between">
        <span>Date :</span>
        <span>{stats.date}</span>
      </div>
      <div className="flex justify-between">
        <span>Gender :</span>
        <span>{stats.gender}</span>
      </div>
    </div>
  )
}
```

---

### 11. PreviewPanel.jsx

**Props :** aucune (zone centrale vide pour le ped 3D)

**Code :**
```jsx
export function PreviewPanel() {
  return (
    <div className="absolute inset-0 flex items-center justify-center">
      <div className="w-96 h-96 border-2 border-dashed border-gray-600 rounded flex items-center justify-center">
        <span className="text-gray-500 text-sm">Preview 3D (géré par Lua)</span>
      </div>
    </div>
  )
}
```

---

## App.jsx (point d'entrée)

```jsx
import { useState, useEffect } from 'react'
import { CharacterCreator } from './components/CharacterCreator'

export default function App() {
  const [state, setState] = useState(null)

  useEffect(() => {
    const handler = (event) => {
      const { type, data } = event.data
      
      if (type === 'UPDATE_CHARACTER') {
        setState(data)
      } else if (type === 'HIDE_MENU') {
        setState(null)
      }
    }
    
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  if (!state) return null

  return <CharacterCreator state={state} />
}
```

---

## fxmanifest.lua (modification)

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'nui/dist/index.html'

client_scripts {
    'client/core/*.lua',
    'client/items/*.lua',
    'client/input/*.lua',
    'client/renderer/*.lua',
    'client/ui.lua',
    'client/nui_bridge.lua'  -- NOUVEAU
}

files {
    'nui/dist/**/*'
}
```

---

## nui_bridge.lua (à créer)

```lua
-- client/nui_bridge.lua
-- Sérialise l'état du menu Lua et l'envoie à React

local function SerializeCharacterMenu(menu)
    local items = menu.items or {}
    
    return {
        mom = items[1] and items[1]:GetSelectedItem() or "elizabeth",
        dad = items[2] and items[2]:GetSelectedItem() or "benjamin",
        resemblance1 = items[3] and items[3].value or 50,
        resemblance2 = items[4] and items[4].value or 80,
        skinTone = items[5] and items[5].value or 1,
        name = items[6] and items[6].text or "Jhon Dhoe",
        nose = items[7] and items[7].value or 50,
        category = menu._activeCategory or "face",
        items = {
            { label = "Cheeks 1", value = 0 },
            { label = "Cheeks 2", value = 0 },
            { label = "Hair 1", value = 0 },
            { label = "Hair 2", value = 0 },
            { label = "Makeup 1", value = 0 },
            { label = "Makeup 2", value = 0 },
            { label = "Blush 1", value = 0 },
            { label = "Blush 2", value = 0 },
        },
        stats = {
            sex = "F / M",
            id = 1,
            job = "unemployed",
            money = 10,
            maxMoney = 100,
            date = "12/04/1978",
            gender = "Male"
        },
        momPercent = 28,
        dadPercent = 89
    }
end

-- Override de Menu:Draw() pour envoyer à NUI au lieu de DrawRect
local _origDraw = Menu.Draw
Menu.Draw = function(self)
    if not self.visible then
        SendNUIMessage({ type = "HIDE_MENU" })
        return
    end
    
    local state = SerializeCharacterMenu(self)
    SendNUIMessage({
        type = "UPDATE_CHARACTER",
        data = state
    })
end
```

---

## Commandes pour Claude Code

**Setup initial :**
```
Crée un projet Vite + React dans le dossier nui/ avec Tailwind configuré
```

**Création des composants :**
```
Crée tous les composants listés dans le brief avec le code exact fourni
```

**Test visuel :**
```
Ajoute des données de test dans App.jsx pour voir le rendu sans FiveM
```

---

## Notes importantes

1. **Tous les boutons sont visuels uniquement** — pas de `onClick`
2. **Les inputs sont gérés par Lua** — React ne fait qu'afficher
3. **Utilise Flexbox/Grid, jamais `position: absolute` sauf pour les overlays (CircleGraph, StatsPanel)**
4. **Couleurs via Tailwind custom colors** définis dans `tailwind.config.js`
5. **Transitions CSS** sur les sliders (`transition-all duration-150`)

---

## Checklist finale

- [ ] Setup Vite + React + Tailwind
- [ ] Créer `tailwind.config.js` avec palette custom
- [ ] Créer tous les 11 composants
- [ ] Créer `App.jsx` avec listener `message`
- [ ] Tester avec données mockées
- [ ] Build : `npm run build` → vérifie `nui/dist/index.html`
- [ ] Créer `nui_bridge.lua`
- [ ] Modifier `fxmanifest.lua`
- [ ] Test in-game
