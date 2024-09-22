@isTest
public class MSD_CORE_CommentTriggerHandlerTest {
    public static MSD_CORE_Comments__c cmnts = new MSD_CORE_Comments__c();
    public static List<MSD_CORE_Comments__c> newList = new List<MSD_CORE_Comments__c>();
    
    static{
       /*mntS.MSD_CORE_Knowledge__c = 'test';
        cmntS.MSD_CORE_Type__c =  'After Call Work';
        
        insert cmnts; */
    }
    @isTest static void testCreateLotDetails(){
        Test.startTest();  
        MSD_CORE_CommentTriggerHandler.UpdateConverstions(newList);
        Test.stopTest();  
    }
}