/*
* MSD_CORE_UpdateInteractionSourceTriTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is a test class for the MSD_CORE_UpdateInteractionSourceTrigger class
*/
@isTest
private class MSD_CORE_UpdateInteractionSourceTriTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case interaction;
    private static MSD_CORE_Source__c source; 

    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        interaction = new Case(); 
        interaction.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName =: settings.Interaction_Record_Type_MVN__c].Id;
        interaction.Origin = settings.MSD_CORE_Case_Origin_Email__c; 
        insert interaction; 

        source = new MSD_CORE_Source__c(); 
        source.Name = 'Source';
        source.MSD_CORE_External_Id__c = 'jimmy@gmail.com';
        source.MSD_CORE_Active__c = true;

        insert source; 
    }

    @isTest static void addEmailToCase() {
        EmailMessage em = new EmailMessage(); 
        em.ToAddress = 'jimmy@gmail.com';
        em.FromAddress = 'Paul@gmail.com';
        em.ParentId = interaction.Id; 

        Test.startTest(); 
        insert em; 
        Test.stopTest(); 

        Case c = [SELECT Id, MSD_CORE_Source__c FROM Case WHERE Id =: interaction.Id]; 
        System.assertEquals(source.Id, c.MSD_CORE_Source__c);
    }
}