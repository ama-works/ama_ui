// Grille d'items 2 colonnes — visuel uniquement
// items = [{ label, value }]  (8 max depuis Lua)
export function ItemGrid({ items = [] }) {
  return (
    <div className="grid grid-cols-2 gap-1.5">
      {items.map((item, i) => (
        <div
          key={i}
          className="flex items-center justify-between bg-char-gray border-2 border-char-border-yellow rounded px-2 h-10"
        >
          <button className="text-gray-400 text-xl w-6 h-6 flex items-center justify-center leading-none">
            ⊖
          </button>
          <span className="text-char-border-yellow text-xs font-semibold text-center flex-1 mx-1 truncate">
            {item.label}
          </span>
          <button className="text-gray-400 text-xl w-6 h-6 flex items-center justify-center leading-none">
            ⊕
          </button>
        </div>
      ))}
    </div>
  )
}
