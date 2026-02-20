/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,jsx}',
  ],
  theme: {
    extend: {
      colors: {
        'char-bg':            'rgba(0,0,0,0.82)',
        'char-border-cyan':   '#08F7DB',
        'char-border-orange': '#FF6411',
        'char-border-yellow': '#F7FF0D',
        'char-green':         '#00FF00',
        'char-gray':          '#1a1a1a',
        'char-overlay':       'rgba(30,30,30,0.90)',
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
