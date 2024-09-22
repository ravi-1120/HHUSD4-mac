/*
* MSD_CORE_TrackTimeWithOwnerTriggerTest
* Created By:    Roman Lerman
* Created Date:  7/14/2015
* Description:   This is a test class for the MSD_CORE_TrackTimeWithOwnerTrigger
*                class, which is used to track the time a Case spends with an owner.
*/
@isTest
private class MSD_CORE_TrackTimeWithOwnerTriggerTest {

    static Group queue;
    static User callCenterUser;
    static Case newCase;
    static Case newCase2;
    static Account testAccount;

    static {
        Profile p = [select Id from Profile where Name='MSD_CORE Contact Center - Contact Center Agent'];
        callCenterUser = new User(Alias = 'heiditst', Email='heidibergen@example.com',
                            EmailEncodingKey='UTF-8', FirstName = 'Heidi', LastName='Bergen', LanguageLocaleKey='de',
                            LocaleSidKey='de', ProfileId = p.Id,
                            TimeZoneSidKey='Europe/Berlin', UserName='heidibergen.example@merck.com');

        insert callCenterUser;

        System.runAs(callCenterUser){
            TestDataFactoryMVN.createSettings(true);

            queue = new Group();
            queue.Type = 'Queue';

            queue.Name = 'Test Queue';

            insert queue;

            QueueSobject queueSObject = new queueSobject();
            queueSObject.QueueId = queue.Id;
            queueSObject.SobjectType = 'Case';

            insert queueSObject;

            GroupMember queueMember = new GroupMember();
            queueMember.UserOrGroupId = callCenterUser.Id;
            queueMember.GroupId = queue.Id;
            insert queueMember;

            testAccount = TestDataFactoryMVN.createTestHCP();
            newCase = TestDataFactoryMVN.createTestCase(testAccount.Id,[select PersonContactId from Account where Id = :testAccount.Id].PersonContactId);
            newCase2 = TestDataFactoryMVN.createTestCase(testAccount.Id,[select PersonContactId from Account where Id = :testAccount.Id].PersonContactId);
        
            newCase.OwnerId = queue.Id;
            newCase.case_Country_MVN__c = 'US';

            newCase2.OwnerId = queue.Id;
            newCase2.case_Country_MVN__c = 'US';

            List<Case> cases = new List<Case>();
            cases.add(newCase);
            cases.add(newCase2);

            update cases;
        }
    }

    @isTest static void testChangeCaseOwnership() {
        System.runAs(callCenterUser){
            newCase.OwnerId = UserInfo.getUserId();
            newCase.case_Country_MVN__c = 'US';

            newCase2.OwnerId = UserInfo.getUserId();
            newCase2.case_Country_MVN__c = 'US';

            List<Case> cases = new List<Case>();
            cases.add(newCase);
            cases.add(newCase2);

            Test.startTest();
                update cases;
            Test.stopTest();

            List<MSD_CORE_Time_with_Owner__c> timeWithOwnerList = [select MSD_CORE_Queue_Name__c, MSD_CORE_Time_in_Hours__c 
                                                                      from MSD_CORE_Time_with_Owner__c where MSD_CORE_Queue_Name__c = :queue.Name];

            System.assertEquals(2, timeWithOwnerList.size());

            for(MSD_CORE_Time_with_Owner__c timeWithOwner:timeWithOwnerList){
                System.assertEquals(queue.Name, timeWithOwner.MSD_CORE_Queue_Name__c);
                System.assertNotEquals(null, timeWithOwner.MSD_CORE_Time_in_Hours__c);
            }
        }
    }

    @isTest static void testCaseClosed() {
        newCase.MSD_CORE_AE_PQC_Company_Awareness_Date__c = Date.today();
        newCase2.MSD_CORE_AE_PQC_Company_Awareness_Date__c = Date.today();

        newCase.Status = 'Closed';
        newCase2.Status = 'Closed';

        List<Case> cases = new List<Case>();
        cases.add(newCase);
        cases.add(newCase2);
        update cases;

        System.runAs(callCenterUser){
            List<MSD_CORE_Time_with_Owner__c> timeWithOwnerForNewCase = [select MSD_CORE_User__c, MSD_CORE_Time_in_Hours__c 
                                                                            from MSD_CORE_Time_with_Owner__c where MSD_CORE_Case__c =: newCase.Id and MSD_CORE_User__c != null order by CreatedDate desc];

            List<MSD_CORE_Time_with_Owner__c> timeWithOwnerForNewCase2 = [select MSD_CORE_User__c, MSD_CORE_Time_in_Hours__c 
                                                                            from MSD_CORE_Time_with_Owner__c where MSD_CORE_Case__c =: newCase2.Id and MSD_CORE_User__c != null order by CreatedDate desc];
            
            System.assertEquals(1, timeWithOwnerForNewCase.size());
            System.assertEquals(1, timeWithOwnerForNewCase2.size());

            System.assertEquals(UserInfo.getUserId(), timeWithOwnerForNewCase[0].MSD_CORE_User__c);
            System.assertNotEquals(null, timeWithOwnerForNewCase2[0].MSD_CORE_Time_in_Hours__c);

            System.assertEquals(UserInfo.getUserId(), timeWithOwnerForNewCase2[0].MSD_CORE_User__c);
            System.assertNotEquals(null, timeWithOwnerForNewCase2[0].MSD_CORE_Time_in_Hours__c);
        }
    }
}