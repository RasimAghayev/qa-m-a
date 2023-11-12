describe("template spec", () => {
  it("passes", () => {
    cy.visit("/");
    cy.url("https://turbo.az/");
    cy.title("Turbo.Az - Avtomobilləri burada seçirlər");
    cy.get('form > .tz-container > .main-search__row-4 > .main-search__item:nth-child(1) > .tz-dropdown > .tz-dropdown__selected--bordered > .tz-dropdown__values')
      .should('have.text','Markanı yazın')
    cy.get('form > .tz-container > .main-search__row-4 > .main-search__item:nth-child(1) > .tz-dropdown > .tz-dropdown__selected--bordered > .tz-dropdown__label')
    .click()
    cy.get('form > .tz-container > .main-search__row-4 > .main-search__item:nth-child(1) > .tz-dropdown > .tz-dropdown__selected--bordered > .tz-dropdown__search')
    .type('Audi')
    // .get('.tz-dropdown__option > .tz-dropdown__option-label > span').should('have.text','Audi')
  });
});
