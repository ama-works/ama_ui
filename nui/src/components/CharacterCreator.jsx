import { ParentHeader }    from './ParentHeader'
import { ParentSelector }  from './ParentSelector'
import { SliderGradient }  from './SliderGradient'
import { ColorPicker }     from './ColorPicker'
import { TextInput }       from './TextInput'
import { ProgressBar }     from './ProgressBar'
import { CategoryButton }  from './CategoryButton'
import { ItemGrid }        from './ItemGrid'
import { StatsPanel }      from './StatsPanel'

const CATEGORIES = [
  { id: 'face',    label: 'Visage'  },
  { id: 'hair',    label: 'Hair'    },
  { id: 'makeup',  label: 'Makeup'  },
  { id: 'beard',   label: 'Beard'   },
  { id: 'skin',    label: 'Skin'    },
  { id: 'clothes', label: 'Clothes' },
]

// Noms parents GTA V (index = numéro du fichier image)
const MOM_NAMES = [
  'elizabeth','hannah','jasmine','amparo','casey',
  'lena','miranda','adrienne','ag','henrietta',
  'arabella','audrey','olivia','chianda','siobhan',
  'rhonda','wanda','ines','nilufar','ryusei','old_man1',
]
const DAD_NAMES = [
  'benjamin','daniel','joshua','noah','andrew',
  'juan','alex','isaac','dominic','thomas',
  'sammy','kane','alfredo','carlos','kwame',
  'old_man1','old_man2','mr_raspberry_jam','claude','niko','john',
]

export function CharacterCreator({ state }) {
  if (!state) return null

  const {
    mom          = 'elizabeth',
    dad          = 'benjamin',
    momIndex     = 0,
    dadIndex     = 0,
    resemblance1 = 50,
    resemblance2 = 50,
    skinTone     = 1,
    name         = 'John Doe',
    nose         = 50,
    category     = 'face',
    items        = [],
    stats        = {},
    momPercent   = 50,
    dadPercent   = 50,
  } = state

  // Index numérique pour les portraits (fallback sur MOM_NAMES)
  const mIdx = typeof momIndex === 'number' ? momIndex : MOM_NAMES.indexOf(mom)
  const dIdx = typeof dadIndex === 'number' ? dadIndex : DAD_NAMES.indexOf(dad)

  return (
    // Tout dans UN seul rectangle, positionné en bas-gauche
    <div
      className="fixed bottom-0 left-0 flex items-end"
      style={{ width: '100vw', height: '100vh', pointerEvents: 'none' }}
    >
      {/* ── Rectangle principal ──────────────────────────────────────────── */}
      <div
        className="flex gap-3"
        style={{ pointerEvents: 'auto', padding: '0 0 8px 8px', alignItems: 'flex-end' }}
      >

        {/* ── Panneau gauche principal ───────────────────────────────────── */}
        <div
          className="flex flex-col"
          style={{
            width: '285px',
            background: 'rgba(0,0,0,0.88)',
            border: '2px solid #08F7DB',
            borderRadius: '4px',
            overflow: 'hidden',
          }}
        >
          {/* Header mumdadbg + portraits */}
          <ParentHeader
            momIndex={mIdx >= 0 ? mIdx : 0}
            dadIndex={dIdx >= 0 ? dIdx : 0}
            momPercent={momPercent}
            dadPercent={dadPercent}
          />

          {/* Contrôles */}
          <div className="flex flex-col gap-1 p-2">

            {/* Mom / Dad selectors */}
            <ParentSelector label="Mom" value={mom} icon="♀" />
            <ParentSelector label="Dad" value={dad} icon="♂" />

            {/* Sliders Ressemblance */}
            <SliderGradient label="Resemblance : 1" value={resemblance1} icon1="👤" icon2="👩" />
            <SliderGradient label="Resemblance : 2" value={resemblance2} icon1="👤" icon2="👨" />

            {/* Skin Tone */}
            <ColorPicker label="Skin Tone" value={skinTone} />

            {/* Nom */}
            <TextInput label="Name" value={name} />

            {/* Nose segments */}
            <ProgressBar label="Nose" value={nose} segments={6} />

            {/* Séparateur */}
            <div style={{ borderTop: '1px solid #333', margin: '2px 0' }} />

            {/* Catégories 2 colonnes */}
            <div className="grid grid-cols-2 gap-1">
              {CATEGORIES.map((cat) => (
                <CategoryButton
                  key={cat.id}
                  label={cat.label}
                  active={category === cat.id}
                />
              ))}
            </div>

            {/* Grille items */}
            <ItemGrid items={items.slice(0, 8)} />

            {/* Confirm */}
            <button
              className="w-full h-9 rounded font-bold text-white text-sm tracking-widest uppercase mt-1"
              style={{ background: 'linear-gradient(to right, #1a5eff, #0a3bcc)' }}
            >
              CONFIRM
            </button>
          </div>
        </div>

        {/* ── Stats panel flottant à droite du rectangle ─────────────────── */}
        <StatsPanel stats={stats} />

      </div>
    </div>
  )
}
