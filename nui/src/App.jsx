import { useState, useEffect } from 'react'
import { CharacterCreator } from './components/CharacterCreator'

// ── Données mock pour dev sans FiveM ──────────────────────────────────────────
// Décommenter MOCK_DATA + const [state, setState] = useState(MOCK_DATA) pour tester
const MOCK_DATA = {
  mom:         'elizabeth',
  dad:         'benjamin',
  resemblance1: 60,
  resemblance2: 40,
  skinTone:    3,
  name:        'John Doe',
  nose:        50,
  category:    'face',
  items: [
    { label: 'Cheeks 1', value: 0 },
    { label: 'Cheeks 2', value: 0 },
    { label: 'Hair 1',   value: 0 },
    { label: 'Hair 2',   value: 0 },
    { label: 'Makeup 1', value: 0 },
    { label: 'Makeup 2', value: 0 },
    { label: 'Blush 1',  value: 0 },
    { label: 'Blush 2',  value: 0 },
  ],
  stats: {
    sex:      'F / M',
    id:       1,
    job:      'unemployed',
    money:    10,
    maxMoney: 100,
    date:     '12/04/1978',
    gender:   'Male',
  },
  momPercent: 28,
  dadPercent: 89,
}

export default function App() {
  // TEST VISUEL — remettre null une fois validé
  const [state, setState] = useState(MOCK_DATA)

  useEffect(() => {
    const handler = (event) => {
      const { type, data } = event.data
      if (type === 'UPDATE_MENU' || type === 'UPDATE_CHARACTER') {
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
