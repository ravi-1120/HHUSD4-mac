/*
* MSD_CORE_AddAEContactsToAETriggerTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is a test class for the MSD_CORE_AddAEContactsToAETrigger class
*/
@isTest
private class MSD_CORE_AddAEContactsToAETriggerTest {

    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case interaction = new Case(); 
    private static Account contact = new Account(); 
    private static Account referedBy = new Account(); 
    private static Address_vod__c address = new Address_vod__c(); 
    private static Id adverseEventRTId = null; 

    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        interaction.recordTypeId = [SELECT Id FROM RecordType WHERE  SObjectType = 'Case' and  DeveloperName = :settings.Interaction_Record_Type_MVN__c].Id; 
        insert interaction; 

        Id hcpRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' and DeveloperName = :settings.HCP_Record_Type_MVN__c].Id; 
        adverseEventRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' and DeveloperName = :settings.Combo_Case_Preview_Record_Type__c].Id; 

        contact.FirstName = 'Paul';
        contact.LastName = 'Jones';
        contact.Class_of_Trade_Sub_MRK__c = 'Stuff';
        contact.Credentials_vod__c = 'Nurse';
        contact.Phone = '12345678900';
        contact.Fax = '12345678901';
        contact.RecordTypeId = hcpRT; 

        insert contact; 

        address.Name = '211 Hero Street';
        address.Address_line_2_vod__c  = 'Apt 271';
        address.City_vod__c  = 'Chicago';
        address.Country_vod__c  = 'US';
        address.State_vod__c  = 'IL';
        address.Zip_vod__c  = '60610';
        address.Account_vod__c = contact.Id; 
        
        insert address;

        referedBy.FirstName = 'Randy';
        referedBy.LastName = 'Thomas';
        referedBy.Class_of_Trade_Sub_MRK__c = 'Stuff';
        referedBy.Credentials_vod__c = 'Nurse';
        referedBy.Phone = '12345678911';
        referedBy.Fax = '12345678910';
        referedBy.RecordTypeId = hcpRT; 

        insert referedBy; 

        interaction.AccountId = contact.Id; 
        interaction.Referred_By_MVN__c = referedBy.Id; 

        update interaction; 
    }


     @isTest static void createNewAEWithAddressFieldsOnRelatedAddress() {
        Case ae = interaction.clone(false, false, false, false); 
        ae.RecordTypeId = adverseEventRTId;
        ae.ParentId = interaction.Id;
        
        Test.startTest();
            insert ae; 
        Test.stopTest();

        List<MSD_CORE_AE_Contact__c> aeContacts = [SELECT Id, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c, MSD_CORE_Type__c, MSD_CORE_Credentials__c, MSD_CORE_Address_Line_1__c, MSD_CORE_Address_Line_2__c, MSD_CORE_City__c, MSD_CORE_Country__c, MSD_CORE_State_Province__c, MSD_CORE_Postal_Code__c, MSD_CORE_Phone__c, MSD_CORE_Fax__c FROM MSD_CORE_AE_Contact__c WHERE MSD_CORE_Adverse_Event__c = :ae.Id ORDER BY MSD_CORE_First_Name__c]; 
        
        System.assertEquals(2, aeContacts.size());
        System.assertEquals('Paul', aeContacts[0].MSD_CORE_First_Name__c);
        System.assertEquals('Jones', aeContacts[0].MSD_CORE_Last_Name__c);
        System.assertEquals('Stuff', aeContacts[0].MSD_CORE_Type__c);
        System.assertEquals('Nurse', aeContacts[0].MSD_CORE_Credentials__c);
        System.assertEquals('211 Hero Street', aeContacts[0].MSD_CORE_Address_Line_1__c);
        System.assertEquals('Apt 271', aeContacts[0].MSD_CORE_Address_Line_2__c);
        System.assertEquals('Chicago', aeContacts[0].MSD_CORE_City__c);
        System.assertEquals('US', aeContacts[0].MSD_CORE_Country__c);
        System.assertEquals('IL', aeContacts[0].MSD_CORE_State_Province__c);
        System.assertEquals('60610', aeContacts[0].MSD_CORE_Postal_Code__c);
        System.assertEquals('12345678900', aeContacts[0].MSD_CORE_Phone__c);
        System.assertEquals('12345678901', aeContacts[0].MSD_CORE_Fax__c);

        System.assertEquals('Randy', aeContacts[1].MSD_CORE_First_Name__c);
        System.assertEquals('Thomas', aeContacts[1].MSD_CORE_Last_Name__c);
        System.assertEquals('Stuff', aeContacts[1].MSD_CORE_Type__c);
        System.assertEquals('Nurse', aeContacts[1].MSD_CORE_Credentials__c);
        System.assertEquals(null, aeContacts[1].MSD_CORE_Address_Line_1__c);
        System.assertEquals(null, aeContacts[1].MSD_CORE_Address_Line_2__c);
        System.assertEquals(null, aeContacts[1].MSD_CORE_City__c);
        System.assertEquals('US', aeContacts[1].MSD_CORE_Country__c);
        System.assertEquals(null, aeContacts[1].MSD_CORE_State_Province__c);
        System.assertEquals(null, aeContacts[1].MSD_CORE_Postal_Code__c);
        System.assertEquals('12345678911', aeContacts[1].MSD_CORE_Phone__c);
        System.assertEquals('12345678910', aeContacts[1].MSD_CORE_Fax__c);

     }


    @isTest static void createNewAEWithAddressFieldsOnCaseAndAddress() {
        interaction.Case_AddressLine1_MVN__c = 'Tom Street'; 
        interaction.Case_AddressLine2_MVN__c = '2B'; 
        interaction.Case_City_MVN__c = 'NYC';
        interaction.Case_Country_MVN__c = 'US';  
        interaction.Case_State_MVN__c = 'NY'; 
        interaction.Case_Postal_Code_MVN__c = '11050'; 
        interaction.Case_Account_Phone_MVN__c = '2154155555'; 
        interaction.Case_Account_Fax_MVN__c = '2154155554'; 

        update interaction; 

        Address_vod__c referedByAddress = address.clone(false, false, false, false); 
        referedByAddress.Account_vod__c = referedBy.Id;
        insert referedByAddress; 

        Case ae = interaction.clone(false, false, false, false); 
        ae.RecordTypeId = adverseEventRTId;
        ae.ParentId = interaction.Id;
        
        Test.startTest();
            insert ae; 
        Test.stopTest();

        List<MSD_CORE_AE_Contact__c> aeContacts = [SELECT Id, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c, MSD_CORE_Type__c, MSD_CORE_Credentials__c, MSD_CORE_Address_Line_1__c, MSD_CORE_Address_Line_2__c, MSD_CORE_City__c, MSD_CORE_Country__c, MSD_CORE_State_Province__c, MSD_CORE_Postal_Code__c, MSD_CORE_Phone__c, MSD_CORE_Fax__c FROM MSD_CORE_AE_Contact__c WHERE MSD_CORE_Adverse_Event__c = :ae.Id ORDER BY MSD_CORE_First_Name__c]; 
        
        System.assertEquals(2, aeContacts.size());
        System.assertEquals('Paul', aeContacts[0].MSD_CORE_First_Name__c);
        System.assertEquals('Jones', aeContacts[0].MSD_CORE_Last_Name__c);
        System.assertEquals('Stuff', aeContacts[0].MSD_CORE_Type__c);
        System.assertEquals('Nurse', aeContacts[0].MSD_CORE_Credentials__c);
        System.assertEquals('Tom Street', aeContacts[0].MSD_CORE_Address_Line_1__c);
        System.assertEquals('2B', aeContacts[0].MSD_CORE_Address_Line_2__c);
        System.assertEquals('NYC', aeContacts[0].MSD_CORE_City__c);
        System.assertEquals('US', aeContacts[0].MSD_CORE_Country__c);
        System.assertEquals('NY', aeContacts[0].MSD_CORE_State_Province__c);
        System.assertEquals('11050', aeContacts[0].MSD_CORE_Postal_Code__c);
        System.assertEquals('2154155555', aeContacts[0].MSD_CORE_Phone__c);
        System.assertEquals('2154155554', aeContacts[0].MSD_CORE_Fax__c);

        System.assertEquals('Randy', aeContacts[1].MSD_CORE_First_Name__c);
        System.assertEquals('Thomas', aeContacts[1].MSD_CORE_Last_Name__c);
        System.assertEquals('Stuff', aeContacts[1].MSD_CORE_Type__c);
        System.assertEquals('Nurse', aeContacts[1].MSD_CORE_Credentials__c);
        System.assertEquals('211 Hero Street', aeContacts[1].MSD_CORE_Address_Line_1__c);
        System.assertEquals('Apt 271', aeContacts[1].MSD_CORE_Address_Line_2__c);
        System.assertEquals('Chicago', aeContacts[1].MSD_CORE_City__c);
        System.assertEquals('US', aeContacts[1].MSD_CORE_Country__c);
        System.assertEquals('IL', aeContacts[1].MSD_CORE_State_Province__c);
        System.assertEquals('60610', aeContacts[1].MSD_CORE_Postal_Code__c);
        System.assertEquals('12345678911', aeContacts[1].MSD_CORE_Phone__c);
        System.assertEquals('12345678910', aeContacts[1].MSD_CORE_Fax__c);

     }

     @isTest static void createMultipleAEsAtOnce() {
        List<Case> aeList = new List<Case>(); 
        aeList.add(interaction.clone(false, false, false, false)); 
        aeList.add(interaction.clone(false, false, false, false)); 
        aeList.add(interaction.clone(false, false, false, false)); 

        for(Case c: aeList)
        {
            c.RecordTypeId = adverseEventRTId;
            c.ParentId = interaction.Id;
        }

        Test.startTest();
            insert aeList;
        Test.stopTest(); 

        Set<Id> aeIds = new Set<Id>(); 
        for(Case c: aeList)
        {
            aeIds.add(c.Id); 
        }

        System.assertEquals(6, [SELECT Id FROM MSD_CORE_AE_Contact__c WHERE MSD_CORE_Adverse_Event__c IN :aeIds].size());
     }
}