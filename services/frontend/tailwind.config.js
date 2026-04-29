/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'sre-dark-blue': '#1a2a45',
        'sre-orange': '#f97316',
        'sre-cream': '#f5f1e8',
      },
    },
  },
  plugins: [],
}
