// Panneau stats (droite) — données du personnage envoyées par Lua
export function StatsPanel({ stats = {} }) {
  const Row = ({ label, value }) => (
    <div className="flex justify-between items-center py-0.5">
      <span className="text-gray-400 text-xs">{label}</span>
      <span className="text-white text-xs font-medium">{value}</span>
    </div>
  )

  return (
    <div className="bg-char-overlay border border-char-border-orange rounded p-3 w-44 space-y-1">
      <Row label="Sex :"    value={stats.sex    ?? 'F / M'}   />
      <div className="flex items-center gap-1 py-0.5">
        <span className="text-gray-400 text-xs">Character</span>
        <span className="text-char-border-orange text-base leading-none ml-1">⊕</span>
      </div>
      <Row label="ID :"     value={`id (${stats.id ?? 1})`}   />
      <Row label="Job :"    value={stats.job    ?? 'unemployed'} />
      <Row
        label="Money :"
        value={`${stats.money ?? 0}$ / ${stats.maxMoney ?? 100}$`}
      />
      <Row label="Date :"   value={stats.date   ?? '—'}        />
      <Row label="Gender :" value={stats.gender ?? '—'}        />
    </div>
  )
}
