const { defineConfig } = require("cypress");

module.exports = defineConfig({
  projectId: "6b645r",

  e2e: {
    baseUrl: 'https://turbo.az',
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },

  component: {
    devServer: {
      framework: "angular",
      bundler: "webpack",
    },
    specPattern: "**/*.cy.ts",
  },
});
