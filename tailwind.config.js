module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('daisyui'),
    require('@tailwindcss/typography')
  ],
  theme: {
    extend: {
      transitionDuration: {
        '5000': '5000ms',
      }
    }
  },
  daisyui: {
    themes: [
    ],
  },
}
