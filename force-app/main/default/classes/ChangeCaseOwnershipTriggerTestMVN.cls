/*
  * ChangeCaseOwnershipTriggerTestMVN
  *    Created By:     Kai Chen
  *    Created Date:   September 26, 2013
  *    Description:    Unit tests for CaseCaseOwnershipTriggerMVN class.
 */
@isTest
private class ChangeCaseOwnershipTriggerTestMVN {

    static Group queue;
    static User callCenterUser;
    static Case newCase;
    static Account testAccount;

    static {
        Profile p = [select Id from Profile where Name='MSD_CORE Contact Center - Contact Center Agent'];
        callCenterUser = new User(Alias = 'heiditst', Email='heidibergen@example.com',
                                EmailEncodingKey='UTF-8', FirstName = 'Heidi', LastName='Bergen', LanguageLocaleKey='de',
                                LocaleSidKey='de', ProfileId = p.Id,
                                TimeZoneSidKey='Europe/Berlin', UserName='heidibergen.test@merck.com');

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
        }
    }

    @isTest static void changeOwnershipFromQueueToUser() {
        System.runAs(callCenterUser){

            newCase.OwnerId = queue.Id;
            newCase.case_Country_MVN__c = 'US';

            update newCase;

            newCase.Interaction_Notes_MVN__c = 'TEST NOTES';

            Test.startTest();
                update newCase;
            Test.stopTest();

            Case resultCase = [select Id, Owner.Type from Case where Id = :newCase.Id];

            System.assertEquals(callCenterUser.Id, resultCase.OwnerId);
        }
    }

    @isTest static void dontChangeOwnershipIfOwnerDifferent() {
        System.runAs(callCenterUser){
              newCase.OwnerId = queue.Id;
              newCase.Interaction_Notes_MVN__c = 'TEST NOTES';
              newCase.case_Country_MVN__c = 'US';

              Test.startTest();
              update newCase;
              Test.stopTest();

              Case resultCase = [select Id, Owner.Type from Case where Id = :newCase.Id];

              System.assertEquals('Queue', resultCase.Owner.Type);
        }
    }
}