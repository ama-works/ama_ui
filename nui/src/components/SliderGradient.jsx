// Slider avec gradient orange→rouge — valeur 0-100
// Le curseur vert indique la position courante
export function SliderGradient({ label, value = 50, icon1, icon2 }) {
  const pct = Math.max(0, Math.min(100, value))

  return (
    <div className="flex items-center h-9 bg-char-overlay border border-char-border-orange rounded px-3 gap-2">
      <span className="text-white text-sm font-medium min-w-[90px]">{label}</span>
      {icon1 && <span className="text-lg leading-none">{icon1}</span>}

      {/* Barre gradient */}
      <div className="flex-1 relative h-3 bg-gray-700 border border-char-border-orange rounded-sm overflow-visible">
        {/* Remplissage */}
        <div
          className="absolute left-0 top-0 h-full rounded-sm"
          style={{
            width: `${pct}%`,
            background: 'linear-gradient(to right, #FF6411, #cc1a00)',
          }}
        />
        {/* Curseur vert */}
        <div
          className="absolute top-1/2 w-[3px] h-5 bg-char-green rounded-sm"
          style={{
            left: `${pct}%`,
            transform: 'translate(-50%, -50%)',
          }}
        />
      </div>

      {icon2 && <span className="text-lg leading-none">{icon2}</span>}
    </div>
  )
}
