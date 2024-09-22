/*
* MSD_CORE_CasePopulateLegalAEPQCTrigTest
* Created By:    Samuel Rosen
* Created Date:  5/20/2015
* Description:   This is a test class for the MSD_CORE_CasePopulateLegalAEPQCTrigger class
*/
@isTest
private class MSD_CORE_CasePopulateLegalAEPQCTrigTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case interaction = new Case(); 
    private static Id pqcId = null;
    private static Id aeId = null;
    private static Id requestId = null; 
    private static Id crId = null;
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        interaction.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Interaction_Record_Type_MVN__c].Id; 
        pqcId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Product_Complaint_Record_Type_MVN__c].Id; 
        aeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Adverse_Event_Record_Type_MVN__c].Id; 
        requestId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Request_Record_Type_MVN__c].Id; 
        crId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.MSD_CORE_Compensation_Req_Record_Type__c].Id; 
        insert interaction; 
    }

    @isTest static void addPQCThenCancelIt() {
        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        
        Case pqc = new Case();
        pqc.ParentId = interaction.Id; 
        pqc.RecordTypeId = pqcId; 
        insert pqc; 

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(true, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);

        Test.startTest();
            pqc.Status = 'Cancelled'; 
            update pqc; 
        Test.stopTest();

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
    }

    @isTest static void addAEThenCancelIt() {
        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        
        Case ae = new Case();
        ae.ParentId = interaction.Id; 
        ae.RecordTypeId = aeId; 
        insert ae; 

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(true, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);

        ae.Status = 'Cancelled'; 
        ae.Type = 'a type'; 
        
        Test.startTest();
            update ae; 
        Test.stopTest();

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
    }

    @isTest static void addLegalRequestThenChangeCategory() {
        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        
        Case lr = new Case();
        lr.ParentId = interaction.Id; 
        lr.RecordTypeId = requestId; 
        lr.MSD_CORE_Legal_Alert__c = true;
        insert lr; 

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(true, interaction.MSD_CORE_Legal_Alert_Present__c);

        lr.Status = 'Cancelled'; 
        lr.MSD_CORE_Legal_Alert__c = false;
        
        Test.startTest();
            update lr; 
        Test.stopTest();

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
    }

    @isTest static void addCRRequestThenCancelIt() {
        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, Case.MSD_CORE_CR_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_CR_Present__c);
        
        Case cr = new Case();
        cr.ParentId = interaction.Id; 
        cr.RecordTypeId = crId; 
        insert cr; 

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, MSD_CORE_CR_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        System.assertEquals(true, interaction.MSD_CORE_CR_Present__c);

        cr.Status = 'Cancelled'; 
        
        Test.startTest();
            update cr; 
        Test.stopTest();

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, Case.MSD_CORE_CR_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
    }

    @isTest static void addMultipleRequestsAndThenCancelThem() {
        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, Case.MSD_CORE_CR_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        
        Case lr = new Case();
        lr.ParentId = interaction.Id; 
        lr.RecordTypeId = requestId; 
        lr.MSD_CORE_Legal_Alert__c = true;

        Case ae = new Case();
        ae.ParentId = interaction.Id; 
        ae.RecordTypeId = aeId; 

        Case pqc = new Case();
        pqc.ParentId = interaction.Id; 
        pqc.RecordTypeId = pqcId; 

        Case cr = new Case();
        cr.ParentId = interaction.Id; 
        cr.RecordTypeId = crId; 
        
        List<Case> caseList = new List<Case>();
        caseList.add(lr);
        caseList.add(ae);
        caseList.add(pqc);
        caseList.add(cr);

        insert caseList; 

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, Case.MSD_CORE_CR_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(true, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(true, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(true, interaction.MSD_CORE_Legal_Alert_Present__c);
        System.assertEquals(true, interaction.MSD_CORE_CR_Present__c);

        lr.Status = 'Cancelled'; 
        lr.MSD_CORE_Legal_Alert__c = false;

        ae.Status = 'Cancelled'; 
        ae.Type = 'a type'; 

        pqc.Status = 'Cancelled'; 

        cr.Status = 'Cancelled';
        
        Test.startTest();    
            update caseList;
        Test.stopTest(); 

        interaction = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, Case.MSD_CORE_CR_Present__c FROM Case WHERE Id = :interaction.Id]; 
        System.assertEquals(false, interaction.MSD_CORE_PQC_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_AE_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_Legal_Alert_Present__c);
        System.assertEquals(false, interaction.MSD_CORE_CR_Present__c);
    }
}