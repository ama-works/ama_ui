import { useEffect, useRef, useState } from 'react'

// Préfix des images selon le sexe
const IMG = (type, index) => `/mom_dad/${type}_${index}.png`

// Composant portrait avec slide CSS lors du changement d'index
function Portrait({ type, index }) {
  const [display, setDisplay]   = useState(index)
  const [slide, setSlide]       = useState(false)
  const [direction, setDirection] = useState(1) // 1=droite, -1=gauche
  const prevIndex = useRef(index)

  useEffect(() => {
    if (index === prevIndex.current) return
    const dir = index > prevIndex.current ? 1 : -1
    setDirection(dir)
    setSlide(true)
    const t = setTimeout(() => {
      setDisplay(index)
      setSlide(false)
      prevIndex.current = index
    }, 180)
    return () => clearTimeout(t)
  }, [index])

  return (
    <div className="relative overflow-hidden" style={{ width: '50%', height: '100%' }}>
      <img
        key={display}
        src={IMG(type, display)}
        alt={type}
        className="absolute bottom-0 object-bottom object-contain h-full"
        style={{
          width: '100%',
          objectPosition: 'bottom center',
          transition: 'transform 0.18s ease, opacity 0.18s ease',
          transform: slide ? `translateX(${direction * 40}px)` : 'translateX(0)',
          opacity: slide ? 0 : 1,
          filter: 'grayscale(1)',
        }}
      />
    </div>
  )
}

// Header complet : mumdadbg + portraits mom/dad + cercle graph
export function ParentHeader({ momIndex = 0, dadIndex = 0, momPercent = 50, dadPercent = 50 }) {
  const r   = 30
  const circ = 2 * Math.PI * r
  const momDash = (momPercent / 100) * circ
  const dadDash = (dadPercent / 100) * circ

  return (
    <div
      className="relative overflow-hidden rounded-t"
      style={{ height: '110px', borderBottom: '1px solid #08F7DB' }}
    >
      {/* Background plage N&B */}
      <img
        src="/mom_dad/mumdadbg.png"
        alt="bg"
        className="absolute inset-0 w-full h-full object-cover opacity-60"
        style={{ filter: 'grayscale(1) brightness(0.5)' }}
      />

      {/* Portraits */}
      <div className="absolute inset-0 flex">
        <Portrait type="female" index={momIndex} />
        <Portrait type="male"   index={dadIndex} />
      </div>

      {/* Overlay dégradé bas */}
      <div
        className="absolute bottom-0 left-0 right-0 h-10"
        style={{ background: 'linear-gradient(to top, rgba(0,0,0,0.9), transparent)' }}
      />

      {/* Cercle graph — en haut à droite du header */}
      <div className="absolute top-2 right-2 flex flex-col items-center">
        <svg width="68" height="68" viewBox="0 0 68 68">
          <circle cx="34" cy="34" r={r} fill="none" stroke="#333" strokeWidth="5" />
          <circle
            cx="34" cy="34" r={r} fill="none"
            stroke="#FF6411" strokeWidth="5"
            strokeDasharray={`${dadDash} ${circ}`}
            strokeLinecap="round"
            transform="rotate(-90 34 34)"
          />
          <circle
            cx="34" cy="34" r={r} fill="none"
            stroke="#08F7DB" strokeWidth="4"
            strokeDasharray={`${momDash} ${circ}`}
            strokeLinecap="round"
            transform="rotate(-90 34 34)"
            opacity="0.75"
          />
          <circle cx="34" cy="34" r={r + 5} fill="none" stroke="#00FF00" strokeWidth="1" opacity="0.5" />
        </svg>
        <div className="text-[9px] leading-tight mt-0.5">
          <p className="text-char-border-cyan">Mom <span className="text-white">{momPercent}%</span></p>
          <p className="text-char-border-orange">Dad <span className="text-white">{dadPercent}%</span></p>
        </div>
      </div>
    </div>
  )
}
