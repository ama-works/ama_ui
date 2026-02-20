// Sélecteur ← nom → (Mom ou Dad) — visuel uniquement
export function ParentSelector({ label, value = '—', icon }) {
  return (
    <div className="flex items-center h-8 bg-char-overlay border border-char-border-orange rounded px-2 gap-1.5">
      {icon && (
        <span className="text-char-border-orange text-sm w-4 text-center">{icon}</span>
      )}
      <span className="text-white text-xs font-medium w-8">{label}</span>
      <div className="flex-1" />
      <span className="text-gray-500 text-base w-4 text-center">◀</span>
      <span className="text-white text-xs min-w-[80px] text-center">{value}</span>
      <span className="text-gray-500 text-base w-4 text-center">▶</span>
    </div>
  )
}
