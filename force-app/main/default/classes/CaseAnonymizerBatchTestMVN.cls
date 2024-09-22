/*
 * CaseAnonymizerBatchMVN
 * Created By:      Thomas Hajcak
 * Created Date:    6/10/2013
 * Description:     This is a test class for CaseAnonymizerBatchTestMVN.
 */
@isTest
private class CaseAnonymizerBatchTestMVN {

    static List<Case> interactions;

    static {
        TestDataFactoryMVN.createSettings(true);

        interactions = TestDataFactoryMVN.createInteractions();
    }

    @isTest static void verifyScheduleJobWorks() {
        String jobId;
        Test.startTest();
        try {
      		jobId = CaseCloserBatchMVN.scheduleHourlyJob();
	    } catch(System.AsyncException ex) {
	      System.debug('Job already scheduled');
	      return;
	    }
    	Test.stopTest();

	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

	    //The next execution should be at the top of the hour. Need to create that time stampe to compare to and account
	    //for the rare chance that the tests execute between 23:00 and 0:00 GMT
	    Integer hour = DateTime.now().hour() == 23 ? 0 : DateTime.now().hour() + 1;
	    Date nextDate = DateTime.now().hour() == 23 ? Date.today() + 1 : Date.today();
	    Time nextHour = Time.newInstance(hour, 0, 0, 0 );

	    System.assert(ct.NextFireTime == DateTime.newInstance(nextDate, nextHour), 'Job not scheduled for the next hour');
	    System.assert(0 == ct.TimesTriggered, 'Batch job already fired... not good');
  	}

    @isTest static void verifyAnonymizerScheduleJobWorks() {
        String jobId;
        Test.startTest();
        try {
            jobId = CaseAnonymizerBatchMVN.scheduleHourlyJob();
        } catch(System.AsyncException ex) {
          System.debug('Job already scheduled');
          return;
        }
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        //The next execution should be at the top of the hour. Need to create that time stampe to compare to and account
        //for the rare chance that the tests execute between 23:00 and 0:00 GMT
        Integer hour = DateTime.now().hour() == 23 ? 0 : DateTime.now().hour() + 1;
        Date nextDate = DateTime.now().hour() == 23 ? Date.today() + 1 : Date.today();
        Time nextHour = Time.newInstance(hour, 0, 0, 0 );

        System.assert(ct.NextFireTime == DateTime.newInstance(nextDate, nextHour), 'Job not scheduled for the next hour');
        System.assert(0 == ct.TimesTriggered, 'Batch job already fired... not good');
    }

    @isTest static void verifyConsumer_Anonymize_Delete() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccountByCountry('US');
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);

        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(null, interaction.AccountId);
            system.AssertEquals(null, interaction.ContactId);
            system.AssertEquals(null, interaction.Address_MVN__c);
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertEquals(0, accountCount);
    }

    @isTest static void verify_NotAnonymizeCountry_Consumer_NoAnonymize_NoDelete() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccountByCountry('UK');
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddressByCountry(consumerAccount, 'UK');

        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();
        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(consumerAccount.Id, interaction.AccountId);
            system.AssertEquals(consumerAccount.PersonContactId, interaction.ContactId);
            system.AssertEquals(testAddress.Id, interaction.Address_MVN__c);
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertEquals(1, accountCount);
    }

    @isTest static void verify_NotAnonymizeCountry_ConsumerWithAnonymize_Anonymize_Delete() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccountForAnonymization('UK');
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddressByCountry(consumerAccount, 'UK');

        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(null, interaction.AccountId);
            system.AssertEquals(null, interaction.ContactId);
            system.AssertEquals(null, interaction.Address_MVN__c);
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertEquals(0, accountCount);
    }

    @isTest static void verifyConsumer_Anonymize_Delete_With_Fulfillments() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccountByCountry('US');
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);

        List<Fulfillment_MVN__c> fulfillments = new List<Fulfillment_MVN__c>();
        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            interaction.Status = 'Closed';

            fulfillments.add(new Fulfillment_MVN__c(Case_MVN__c = interaction.Id,
                                                    Account_Name_MVN__c = interaction.AccountId,
                                                    Status_MVN__c='Closed'));
        }
        update interactions;
        insert fulfillments;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c, (select Id, Account_Name_MVN__c from Fulfillment__r) FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(null, interaction.AccountId);
            system.AssertEquals(null, interaction.ContactId);
            system.AssertEquals(null, interaction.Address_MVN__c);

            for(Fulfillment_MVN__c fulfill:interaction.Fulfillment__r){
                system.AssertEquals(null, fulfill.Account_Name_MVN__c);
            }
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertEquals(0, accountCount);
    }

    @isTest static void verifyConsumer_Delete_With_Email_And_Task() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccountByCountry('US');
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);

		List<EmailMessage> emailMessages = new List<EmailMessage>();
		List<Task> tasks = new List<Task>();
        List<Fulfillment_MVN__c> fulfillments = new List<Fulfillment_MVN__c>();
        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;

            emailMessages.add(new EmailMessage(ParentId = interaction.Id));
            tasks.add(new Task(Subject='Test', WhatId = interaction.Id));

            fulfillments.add(new Fulfillment_MVN__c(Case_MVN__c = interaction.Id,
                                                    Account_Name_MVN__c = interaction.AccountId,
                                                    Status_MVN__c='Closed'));
        }
        update interactions;
        insert fulfillments;
        insert emailMessages;
        insert tasks;

        for(Case interaction : interactions){
        	interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c,
        					(select Id, Account_Name_MVN__c from Fulfillment__r),
        					(select Id from Tasks),
        					(select Id from EmailMessages) FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(null, interaction.AccountId);
            system.AssertEquals(null, interaction.ContactId);
            system.AssertEquals(null, interaction.Address_MVN__c);

            for(Fulfillment_MVN__c fulfill:interaction.Fulfillment__r){
                system.AssertEquals(null, fulfill.Account_Name_MVN__c);
            }

            system.AssertEquals(0, interaction.Tasks.size());
            system.AssertEquals(0, interaction.EmailMessages.size());
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertEquals(0, accountCount);
    }

    @isTest static void verifyNonConsumer_NoAnonymize_NoDelete() {
        Account hcpAccount = TestDataFactoryMVN.createTestHCP();
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(hcpAccount);
        hcpAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :hcpAccount.Id];

        for (Case interaction : interactions) {
            interaction.AccountId = hcpAccount.Id;
            interaction.ContactId = hcpAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(hcpAccount.Id, interaction.AccountId);
            system.AssertEquals(hcpAccount.PersonContactId, interaction.ContactId);
            system.AssertEquals(testAddress.Id, interaction.Address_MVN__c);
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :hcpAccount.Id];
        System.AssertNotEquals(0, accountCount);
    }

    @isTest static void verifyNotClosed_NoAnonymize_NoDelete() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccount();
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];

        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            system.AssertEquals(consumerAccount.Id, interaction.AccountId);
            system.AssertEquals(consumerAccount.PersonContactId, interaction.ContactId);
            system.AssertEquals(testAddress.Id, interaction.Address_MVN__c);
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertNotEquals(0, accountCount);
    }

    @isTest static void verifyNotAllClosed_AnonymizeSome_NoDelete() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccount();
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];

        Boolean closeCase = false;
        Id openCaseId;
        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            if (closeCase) {
                interaction.Status = 'Closed';
                openCaseId = interaction.Id;
            }
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];

        for (Case interaction : interactions) {
            if (interaction.Id == openCaseId) {
                system.AssertEquals(consumerAccount.Id, interaction.AccountId);
                system.AssertEquals(consumerAccount.PersonContactId, interaction.ContactId);
                system.AssertEquals(testAddress.Id, interaction.Address_MVN__c);
            } else {
                system.AssertEquals(consumerAccount.Id, interaction.AccountId);
                system.AssertEquals(consumerAccount.PersonContactId, interaction.ContactId);
                system.AssertEquals(testAddress.Id, interaction.Address_MVN__c);
            }
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id];
        System.AssertNotEquals(0, accountCount);
    }

    @isTest static void verifyCasesInsideTheTempWindowDoNotGetAnonymized() {
        Service_Cloud_Settings_MVN__c scs = [SELECT Temporary_Account_Hold_Period_Days_MVN__c from Service_Cloud_Settings_MVN__c limit 1];
        scs.Temporary_Account_Hold_Period_Days_MVN__c = 15;
        update scs;

        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccount();
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);

        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;
            interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
        Database.executeBatch(new CaseAnonymizerBatchMVN());
        Test.stopTest();

        interactions = [SELECT Id, AccountId, ContactId, Address_MVN__c FROM Case where Id IN :interactions];
        System.assertEquals(TestDataFactoryMVN.TEST_DATA_SIZE, interactions.size());

        for (Case interaction : interactions) {
            system.AssertEquals(consumerAccount.Id, interaction.AccountId);
            system.AssertEquals(consumerAccount.PersonContactId, interaction.ContactId);
            system.AssertEquals(testAddress.id, interaction.Address_MVN__c);
        }

        System.AssertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :consumerAccount.Id]);
    }

    @isTest static void exerciseSendEmailFunctionaltiy() {
        Account consumerAccount = TestDataFactoryMVN.createTestPersonAccountByCountry('US');
        consumerAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :consumerAccount.Id];
        Address_vod__c testAddress = TestDataFactoryMVN.createTestAddress(consumerAccount);

        List<EmailMessage> emailMessages = new List<EmailMessage>();
        List<Task> tasks = new List<Task>();
        List<Fulfillment_MVN__c> fulfillments = new List<Fulfillment_MVN__c>();
        for (Case interaction : interactions) {
            interaction.AccountId = consumerAccount.Id;
            interaction.ContactId = consumerAccount.PersonContactId;
            interaction.Address_MVN__c = testAddress.Id;

            emailMessages.add(new EmailMessage(ParentId = interaction.Id));
            tasks.add(new Task(Subject='Test', WhatId = interaction.Id));

            fulfillments.add(new Fulfillment_MVN__c(Case_MVN__c = interaction.Id,
                                                    Account_Name_MVN__c = interaction.AccountId,
                                                    Status_MVN__c='Closed'));
        }
        update interactions;
        insert fulfillments;
        insert emailMessages;
        insert tasks;

        for(Case interaction : interactions){
            interaction.Status = 'Closed';
        }
        update interactions;

        Test.startTest();
            try{
                Messaging.reserveSingleEmailCapacity(1);
                CaseAnonymizerBatchMVN batch = new CaseAnonymizerBatchMVN();
                CaseAnonymizerBatchMVN.testSendEmail = true;
                Database.executeBatch(batch);
            }catch(Exception e){
                // An exception here generally indicates that user email
                // is not permitted in the org.
                System.debug('Exception while sending email: ' + e.getMessage());
            }
        Test.stopTest();
    }

}