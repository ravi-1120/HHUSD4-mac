/*
* MSD_CORE_AddNoteToAEPQCTriggerTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is a test class for the MSD_CORE_AddNoteToAEPQCTrigger class
*/
@isTest
private class MSD_CORE_AddNoteToAEPQCTrigTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case closedAE = new Case();  
    private static Case closedPQC = new Case(); 
    private static Id adverseEventRecordTypeId = null; 
    private static Id closedAdverseEventRecordTypeId = null; 
    private static Id closedPQCRecordTypeId = null;
    private static Id pqcRecordTypeId = null;
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        adverseEventRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Adverse_Event_Record_Type_MVN__c].Id; 
        closedAdverseEventRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c].Id; 
        closedPQCRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c].Id; 
        pqcRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Product_Complaint_Record_Type_MVN__c].Id; 

        closedAE.RecordTypeId = closedAdverseEventRecordTypeId;
        closedAE.Status = settings.Closed_Status_MVN__c; 

        insert closedAE;

        closedPQC.RecordTypeId = closedPQCRecordTypeId;
        closedPQC.Status = settings.Closed_Status_MVN__c; 
        closedPQC.MSD_CORE_PQC_Lot_Numbers__c = '14'; 
        closedPQC.MSD_CORE_PQC_Description__c = 'describe'; 
        insert closedPQC;
    }

    @isTest static void testAddAttachment() {
        Test.startTest();
            Attachment aeAttachment = new Attachment(); 
            aeAttachment.ParentId = closedAE.Id; 
            aeAttachment.Name = 'test'; 
            aeAttachment.Body =  Blob.valueOf('stuff'); 
            insert aeAttachment; 

            Attachment pqcAttachment = new Attachment(); 
            pqcAttachment.ParentId = closedPQC.Id; 
            pqcAttachment.Name = 'test'; 
            pqcAttachment.Body = Blob.valueOf('stuff');
            insert pqcAttachment;
        Test.stopTest();

        List<MSD_CORE_Note__c> notes = [SELECT Id, MSD_CORE_Note__c, MSD_CORE_Case__c 
                                            FROM MSD_CORE_Note__c 
                                            WHERE MSD_CORE_Case__c =: closedAE.Id 
                                            OR MSD_CORE_Case__c =: closedPQC.Id 
                                            ORDER BY CreatedDate];

        System.assertEquals(2, notes.size()); 
        System.assertEquals(closedAE.Id, notes[0].MSD_CORE_Case__c);
        System.assertEquals(closedPQC.Id, notes[1].MSD_CORE_Case__c);
    }

    @isTest static void testAddSecondAttachment() {
        Test.startTest();
            Attachment aeAttachment = new Attachment(); 
            aeAttachment.ParentId = closedAE.Id; 
            aeAttachment.Name = 'test'; 
            aeAttachment.Body =  Blob.valueOf('test'); 
            insert aeAttachment; 

            aeAttachment = new Attachment(); 
            aeAttachment.ParentId = closedAE.Id; 
            aeAttachment.Name = 'test'; 
            aeAttachment.Body =  Blob.valueOf('test'); 
            insert aeAttachment;

            Attachment pqcAttachment = new Attachment(); 
            pqcAttachment.ParentId = ClosedPQC.Id; 
            pqcAttachment.Name = 'test'; 
            pqcAttachment.Body = Blob.valueOf('test');
            insert pqcAttachment; 

            pqcAttachment = new Attachment(); 
            pqcAttachment.ParentId = ClosedPQC.Id; 
            pqcAttachment.Name = 'test'; 
            pqcAttachment.Body = Blob.valueOf('test');
            insert pqcAttachment;
        Test.stopTest();

        List<MSD_CORE_Note__c> notes = [SELECT Id, MSD_CORE_Note__c, MSD_CORE_Case__c FROM MSD_CORE_Note__c WHERE MSD_CORE_Case__c =: closedAE.Id OR MSD_CORE_Case__c =: ClosedPQC.Id ORDER BY CreatedDate];

        System.assertEquals(4, notes.size()); 
        System.assertEquals(closedAE.Id, notes[0].MSD_CORE_Case__c);
        System.assertEquals(closedAE.Id, notes[1].MSD_CORE_Case__c);
        System.assertEquals(ClosedPQC.Id, notes[2].MSD_CORE_Case__c);
        System.assertEquals(ClosedPQC.Id, notes[3].MSD_CORE_Case__c);
    }

    @isTest static void testAddAttachmentToOpenCase() {
        Case adverseEvent = new Case(); 
        adverseEvent.RecordTypeId = adverseEventRecordTypeId;

        Case pqc = new Case(); 
        pqc.RecordTypeId = adverseEventRecordTypeId;

        List<Case> aePqcList = new List<Case>();
        aePQCList.add(adverseEvent);
        aePQCList.add(pqc);

        insert aePQCList;

        Test.startTest();
            Attachment aeAttachment = new Attachment(); 
            aeAttachment.ParentId = adverseEvent.Id; 
            aeAttachment.Name = 'test'; 
            aeAttachment.Body =  Blob.valueOf('test'); 
            insert aeAttachment; 

            Attachment pqcAttachment = new Attachment(); 
            pqcAttachment.ParentId = pqc.Id; 
            pqcAttachment.Name = 'test'; 
            pqcAttachment.Body = Blob.valueOf('test');
            insert pqcAttachment;
        Test.stopTest();

        List<MSD_CORE_Note__c> notes = [SELECT Id, MSD_CORE_Note__c, MSD_CORE_Case__c 
                                            FROM MSD_CORE_Note__c 
                                            WHERE MSD_CORE_Case__c =: closedAE.Id 
                                            OR MSD_CORE_Case__c =: ClosedPQC.Id 
                                            ORDER BY CreatedDate];
        System.assertEquals(0, notes.size()); 
    }
}