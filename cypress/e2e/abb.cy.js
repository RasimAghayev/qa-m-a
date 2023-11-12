describe('it', () => {
  it('open bank', () => {
    cy.visit('https://abb-bank.az/')
    // cy.url().should('include','abb');
    // cy.url().should('eq','https://abb-bank.az/')
    // cy.url().should('contain','bank')
    
    // cy.url().should('include','abb')
    //         .should('eq','https://abb-bank.az/')
    //         .should('contain','bank');
    
    cy.url().should('include','abb')
            .and('eq','https://abb-bank.az/')
            .and('contain','bank');
  });
})
