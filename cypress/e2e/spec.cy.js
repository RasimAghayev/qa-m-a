describe('template spec', () => {
  it('passes', () => {
    cy.visit('/')
    // cy.get('.gLFyf').type('Test')
    cy.get('textarea[name="q"]').type('test')
  })
})