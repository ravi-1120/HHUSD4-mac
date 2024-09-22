/*
* CloseChildCasesWhenInteractClosedTestMVN
* Created By:    Kai Chen
* Created Date:  10/9/2014
* Description:   This is the test class for the CloseChildCasesWhenInteractClosedMVN class
*
*/
@isTest
private class CloseChildCasesWhenInteractClosedTestMVN {

    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
	
	static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance(); 
    }

    @isTest static void testCloseInteraction() {
        Case interaction = new Case();
        interaction.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName =: settings.Interaction_Record_Type_MVN__c].Id; 
        interaction.Status = 'Open';

        insert interaction;

        Product_vod__c product = new Product_vod__c(Name='Test Product', 
                                                    External_ID_vod__c = 'testid',
                                                    Product_Type_vod__c = 'Family',
                                                    Active_MRK__c = true);
        insert product;

        Case request = new Case();
        request.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName =: settings.Request_Record_Type_MVN__c].Id; 
        request.Status = 'Open';
        request.ParentId = interaction.Id;
        request.Type = 'General';
        request.Category_MVN__c = 'Other';
        request.Product_MVN__c = product.Id;

        insert request;

        Fulfillment_MVN__c fulfillment = new Fulfillment_MVN__c();

        fulfillment.Case_MVN__c = interaction.Id;
        fulfillment.Status_MVN__c = 'Open';

        insert fulfillment;

        Test.startTest();
            interaction.Status = 'Cancelled';

            update interaction;
        Test.stopTest();

        request = [select Id, Status from Case where Id = :request.Id];

        System.assertEquals('Cancelled', request.Status);

        fulfillment = [select Id, Status_MVN__c from Fulfillment_MVN__c where Id = :fulfillment.Id];

        System.assertEquals('Cancelled', fulfillment.Status_MVN__c);
    }
}