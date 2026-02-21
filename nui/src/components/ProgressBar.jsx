// Barre de progression à segments (ex: Nose)
// value = 0-100, segments = nombre de cases
export function ProgressBar({ label, value = 50, segments = 6 }) {
  const filled = Math.round((value / 100) * segments)

  return (
    <div className="flex items-center gap-2 h-9 bg-char-overlay border border-char-border-orange rounded px-3">
      <span className="text-white text-sm font-medium min-w-[60px]">{label}</span>
      <div className="flex-1 flex gap-1">
        {Array.from({ length: segments }).map((_, i) => (
          <div
            key={i}
            className={`flex-1 h-4 border border-char-border-yellow rounded-sm transition-colors duration-150 ${
              i < filled ? 'bg-char-border-yellow' : 'bg-gray-800'
            }`}
          />
        ))}
      </div>
    </div>
  )
}
