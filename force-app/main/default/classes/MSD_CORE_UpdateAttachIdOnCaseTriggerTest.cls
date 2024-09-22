/*
* MSD_CORE_UpdateAttachIdOnCaseTriggerTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is a test class for the MSD_CORE_UpdateAttachmentIdOnCaseTrigger class
*/
@isTest
private class MSD_CORE_UpdateAttachIdOnCaseTriggerTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case ae = new Case();  
    private static Id aeRTID = null; 
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        aeRTID = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = :settings.Adverse_Event_Record_Type_MVN__c].Id; 
        ae.RecordTypeId = aeRTID;
        insert ae;
    }

    @isTest static void addAttachment() {
        Attachment a = new Attachment(); 
        a.Name = 'A1.txt'; 
        a.Body = Blob.valueOf('stuff');
        a.ParentId = ae.Id; 
        
        Test.startTest();
            insert a; 
        Test.stopTest();

        Case c = [SELECT Id, MSD_CORE_Attachment_IDs__c FROM Case WHERE Id = :ae.Id]; 
        System.assertEquals(a.Id, c.MSD_CORE_Attachment_IDs__c);
    }

    @isTest static void addTwoAttachment() {
        Attachment a = new Attachment(); 
        a.Name = 'A1.txt'; 
        a.Body = Blob.valueOf('stuff');
        a.ParentId = ae.Id; 

        Attachment b = new Attachment(); 
        b.Name = 'B1.txt'; 
        b.Body = Blob.valueOf('stuff');
        b.ParentId = ae.Id;
        
        Test.startTest();
            insert a; 
            insert b; 
        Test.stopTest();

        Case c = [SELECT Id, MSD_CORE_Attachment_Count__c, MSD_CORE_Attachment_Size__c FROM Case WHERE Id = :ae.Id]; 
        if(a.Bodylength>0 && b.Bodylength>0){
            Decimal mb1 = Decimal.ValueOf(a.BodyLength);
            mb1 = mb1.divide((1024*1024),2);
            Decimal mb2 = Decimal.ValueOf(b.BodyLength);
            mb2 = mb2.divide((1024*1024),2);
            System.assertEquals(c.MSD_CORE_Attachment_Size__c, (mb1+mb2)); 
            System.assertEquals(2, c.MSD_CORE_Attachment_Count__c); 
        }
    }

    @isTest static void addTwoDeleteOneAttachment() {
        Attachment a = new Attachment(); 
        a.Name = 'A1.txt'; 
        a.Body = Blob.valueOf('stuff');
        a.ParentId = ae.Id; 

        Attachment b = new Attachment(); 
        b.Name = 'B1.txt'; 
        b.Body = Blob.valueOf('stuff');
        b.ParentId = ae.Id;
        
        Test.startTest();
            insert a; 
            insert b;
            delete a;  
        Test.stopTest();

        Case c = [SELECT Id, MSD_CORE_Attachment_Count__c,MSD_CORE_Attachment_IDs__c FROM Case WHERE Id = :ae.Id]; 
        System.assertEquals(b.Id, c.MSD_CORE_Attachment_IDs__c);         
        System.assertEquals(1, c.MSD_CORE_Attachment_Count__c);
    }

    @isTest static void ignorePrefix() {
        Attachment a = new Attachment(); 
        a.Name = 'A1.txt'; 
        a.Body = Blob.valueOf('stuff');
        a.ParentId = ae.Id; 

        Attachment b = new Attachment(); 
        b.Name = 'PQC Details for Case #1515.txt'; 
        b.Body = Blob.valueOf('stuff');
        b.ParentId = ae.Id;
        
        Test.startTest();
            insert a; 
            insert b;
        Test.stopTest();

        Case c = [SELECT Id, MSD_CORE_Attachment_Count__c FROM Case WHERE Id = :ae.Id]; 
        System.assertEquals(2, c.MSD_CORE_Attachment_Count__c); 
    }
}