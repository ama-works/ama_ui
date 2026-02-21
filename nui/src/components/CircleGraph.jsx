// Graphique circulaire parents — SVG avec stroke-dasharray
// mom/dad = pourcentage 0-100
export function CircleGraph({ mom = 50, dad = 50 }) {
  const r  = 36
  const cx = 44
  const cy = 44
  const circumference = 2 * Math.PI * r  // ~226

  const momDash = (mom / 100) * circumference
  const dadDash = (dad / 100) * circumference

  return (
    <div className="bg-char-overlay border border-char-border-cyan rounded p-3 w-44">
      {/* SVG cercle */}
      <div className="flex justify-center mb-2">
        <svg width="88" height="88" viewBox="0 0 88 88">
          {/* Fond */}
          <circle cx={cx} cy={cy} r={r} fill="none" stroke="#333" strokeWidth="6" />
          {/* Arc Dad (orange) */}
          <circle
            cx={cx} cy={cy} r={r}
            fill="none"
            stroke="#FF6411"
            strokeWidth="6"
            strokeDasharray={`${dadDash} ${circumference}`}
            strokeLinecap="round"
            transform={`rotate(-90 ${cx} ${cy})`}
          />
          {/* Arc Mom (cyan) */}
          <circle
            cx={cx} cy={cy} r={r}
            fill="none"
            stroke="#08F7DB"
            strokeWidth="4"
            strokeDasharray={`${momDash} ${circumference}`}
            strokeLinecap="round"
            transform={`rotate(-90 ${cx} ${cy})`}
            opacity="0.7"
          />
          {/* Bordure verte */}
          <circle cx={cx} cy={cy} r={r + 6} fill="none" stroke="#00FF00" strokeWidth="1.5" opacity="0.5" />
        </svg>
      </div>

      <div className="text-xs space-y-1">
        <p className="text-gray-400">parents resemblance :</p>
        <p className="text-char-border-cyan">→ Mom : <span className="text-white font-semibold">{mom}%</span></p>
        <p className="text-char-border-orange">→ Dad : <span className="text-white font-semibold">{dad}%</span></p>
      </div>
    </div>
  )
}
