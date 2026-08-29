// Tailwind v4 is a PostCSS plugin and needs no tailwind.config file - the theme is declared
// in src/app/globals.css with @theme instead.
const config = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};

export default config;
