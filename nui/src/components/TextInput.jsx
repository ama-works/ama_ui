// Champ nom — affichage seul, la saisie est gérée par Lua
export function TextInput({ label, value = '' }) {
  return (
    <div className="flex items-center justify-between h-9 bg-char-overlay border border-char-border-orange rounded px-3">
      <span className="text-white text-sm font-medium">{label}</span>
      <span className="text-white text-sm opacity-80">{value}</span>
    </div>
  )
}
