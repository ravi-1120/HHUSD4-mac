/*
* Test Class: PDS_AddProductsControllerTest
* Description: Used for PDS_AddProductsController class
* Author: Gopi Chintamaneni
* Created On: 03/14/2024
* Last Modified: 03/14/2024
* Version: Initial
*/
@isTest
private class PDS_AddProductsControllerTest {

    @isTest
    static void testFetchActiveProducts() {
        List<PDS_Product__c> products = new List<PDS_Product__c>();
        for(Integer i = 0; i < 5; i++) {
            PDS_Product__c product = new PDS_Product__c(
                Name = 'Test Product ' + i,
                PDS_Is_Active__c = true
            );
            products.add(product);
        }
        insert products;
        
        //Create a proposal
        PDS_Proposal__c proposal = new PDS_Proposal__c(Name = 'Test Proposal',PDS_Donation_Type__c = 'Excess Product Donation');
        insert proposal;
        
        //Create Reated Product
        PDS_Related_Product__c relatedProduct = new PDS_Related_Product__c(PDS_Product__c=products[0].Id, PDS_Proposal__c=proposal.Id);
      	insert relatedProduct;
        
        
        Test.startTest();
        List<PDS_Product__c> fetchedProducts = PDS_AddProductsController.fetchActiveProducts(proposal.Id,'Annual Allotment');
        Test.stopTest();

        // Assertion
        System.assertEquals(4, fetchedProducts.size(), 'Incorrect number of active products fetched.');
        
    }
    
    @isTest
    static void testGetProposal() {
        // Create a test proposal record
        PDS_Proposal__c testProposal = new PDS_Proposal__c(
            PDS_Donation_Type__c = 'Annual Allotment'
        );
        insert testProposal;
        
        // Fetch the proposal using the controller method
        Test.startTest();
        List<PDS_Proposal__c> result = PDS_AddProductsController.getProposal(testProposal.Id);
        Test.stopTest();
        
    }

    @isTest
    static void testGetFields() {
        Test.startTest();
        List<PDS_AddProductsController.FieldWrapper> fieldsProduct = PDS_AddProductsController.getFields('Product');
        List<PDS_AddProductsController.FieldWrapper> fieldsRelatedProduct = PDS_AddProductsController.getFields('RelatedProduct');
        Test.stopTest();

        // Assertion
        System.assertNotEquals(null, fieldsProduct, 'Fields for Product not retrieved.');
        System.assertNotEquals(null, fieldsRelatedProduct, 'Fields for RelatedProduct not retrieved.');
    }

    @isTest
    static void testCreateRelatedProducts() {
        //Create Products
        List<PDS_Product__c> products = new List<PDS_Product__c>();
        for(Integer i = 0; i < 3; i++) {
            PDS_Product__c product = new PDS_Product__c(
                Name = 'Test Product ' + i
            );
            products.add(product);
        }
        insert products;
        
        //Create Proposal
        PDS_Proposal__c proposal = new PDS_Proposal__c(
                Name = 'Test Proposal',
            	PDS_Donation_Type__c = 'Misc'
            );
        insert proposal;
    
        PDS_Related_Product__c insertToUpdate = new PDS_Related_Product__c(PDS_Product__c = products[1].Id,PDS_Proposal__c = proposal.Id,PDS_Available_Quantity__c=600);
        insert insertToUpdate;
        
        List<PDS_Related_Product__c> relatedProducts = new List<PDS_Related_Product__c>();
        for(Integer i = 0; i < 3; i++) {
            PDS_Related_Product__c relatedProduct = new PDS_Related_Product__c(
               	PDS_Product__c = (i == 1) ? products[1].Id : products[i].Id,
                PDS_Proposal__c = proposal.Id,
                PDS_Available_Quantity__c=600+i
            );
            relatedProducts.add(relatedProduct);
        }
    
        Test.startTest();
        PDS_AddProductsController.createRelatedProducts(relatedProducts, proposal.Id);
        Test.stopTest();
    
        // Query related products by proposal Id
        List<PDS_Related_Product__c> relatedProductsByProposalId = [SELECT Id FROM PDS_Related_Product__c WHERE PDS_Proposal__c = :proposal.Id];
    
        
    }

}