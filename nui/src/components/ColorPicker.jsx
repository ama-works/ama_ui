// Sélecteur de couleur (Skin Tone) — visuel uniquement
export function ColorPicker({ label, value = 1 }) {
  return (
    <div className="flex items-center h-9 bg-char-overlay border border-char-border-orange rounded px-3 gap-2">
      <span className="text-white text-sm font-medium">{label}</span>
      <div className="flex-1" />
      <button className="text-white text-base w-5 text-center opacity-60">◀</button>
      <span className="text-white text-sm min-w-[70px] text-center">Color : ({value})</span>
      <button className="text-white text-base w-5 text-center opacity-60">▶</button>
    </div>
  )
}
