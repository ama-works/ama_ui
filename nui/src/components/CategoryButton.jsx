// Bouton catégorie avec toggle ON/OFF — visuel uniquement
// active = catégorie actuellement sélectionnée par Lua
export function CategoryButton({ label, active = false }) {
  return (
    <div className={`
      flex items-center justify-between h-10 px-3 rounded transition-colors duration-150
      ${active
        ? 'bg-char-overlay border-2 border-char-border-orange'
        : 'bg-char-gray border border-gray-700'}
    `}>
      <span className={`text-sm ${active ? 'text-white font-semibold' : 'text-gray-500'}`}>
        ▶ {label}
      </span>

      {/* Toggle rond */}
      <div className={`w-9 h-5 rounded-full relative transition-colors duration-200 ${
        active ? 'bg-char-border-orange' : 'bg-gray-700'
      }`}>
        <div className={`w-4 h-4 rounded-full bg-white absolute top-0.5 transition-all duration-200 ${
          active ? 'right-0.5' : 'left-0.5'
        }`} />
      </div>
    </div>
  )
}
