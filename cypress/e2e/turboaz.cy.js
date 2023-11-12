describe('TurboAz axtarış bölməsinin analizi', () => {
    beforeEach(() => {
        cy.visit('https://turbo.az')
    });
    it("Saytın yüklənməsi", function() {
        //Check URL
        cy.url().should('include','https://turbo.az');

        //Check Title
        cy.title("Turbo.Az - Avtomobilləri burada seçirlər");

        //Check logo
        cy.get('img[alt="turbo.az"]').should('be.visible')

        //Select mark
        cy.get('[data-id="q_make"]').click()
        // cy.contains('Mercedes Benz').click();
        cy.get('[data-id="q_make"] .tz-dropdown__list .tz-dropdwon__option .tz-dropdown__option-label span').should('have.length',172).and('contain','BMW')
        cy.get('[data-id="q_make"]').type('BMW')
        cy.get('[data-id="q_make"] .tz-dropdown__list .tz-dropdwon__option[data-val="3"]').click()
        cy.get('[data-id="q_make"] .tz-dropdown__values').should('contain','BMW')

        //Select model
        cy.get('[data-id="q_model"]').click()
        cy.get('[data-id="q_model"] .tz-dropdown__list [data-val]').should('have.length',83)
        cy.get('[data-id="q_model"] .tz-dropdown__list [data-val="33"]').click()
        cy.get('[data-id="q_model"] .tz-dropdown__values').should('contain','330')
        
        //Type price from
        cy.get('label[for="q_price_from"]').clear()
        cy.get('label[for="q_price_from"]').type(10000)
        
        //Type price to
        cy.get('label[for="q_price_to"]').clear()
        cy.get('label[for="q_price_to"]').type(20000)

        //Click submit button
        cy.get('button[type="submit"]').should('not.be.disabled').click()

        //check result
        cy.get('.section-title-container .section-title_name').should('have.text','ELANLAR')

        //Check title amount
        cy.get('.products-title .products-title-amount').should('have.text','5 elan')

        //check products amount
        cy.get('.products .products-i').should('have.length',5)
    })
});