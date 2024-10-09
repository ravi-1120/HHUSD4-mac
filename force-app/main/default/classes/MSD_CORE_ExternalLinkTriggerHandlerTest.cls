@isTest
public class MSD_CORE_ExternalLinkTriggerHandlerTest {
    @isTest
    static void testMethod1() {
        PW_Robot_User__c rob = new PW_Robot_User__c();
        rob.Name = 'RobotUserSetting';
        rob.External_ID__c = 'MSD-000001';
        rob.Robot_User__c = 'testuser@merck.com.invalid';
        insert rob;
        MSD_CORE_HEQ_External_Link__c rec = new MSD_CORE_HEQ_External_Link__c();
        rec.name = 'Hello Test';
        rec.MSD_CORE_HEQ_Description__c = 'Hello Test Description';
        rec.MSD_CORE_HEQ_URL__c = 'https://www.fb.com';
        INSERT rec;
        Map<Id, MSD_CORE_HEQ_External_Link__c> mspTemp = new Map<Id, MSD_CORE_HEQ_External_Link__c> {rec.Id=>rec};
        MSD_CORE_HEQ_ExternalLinkTriggerHandler.collectDeletedIds(mspTemp);
        MSD_CORE_HEQ_ExternalLinkTriggerHandler.updateContentVersion();
    }
}