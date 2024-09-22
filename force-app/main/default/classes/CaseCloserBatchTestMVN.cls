/*
 * CaseCloserBatchTestMVN
 * Created By:      Roman Lerman
 * Created Date:    6/21/2013
 * Description:     Test class for the CaseCloserBatchMVN class
 */

@isTest
private class CaseCloserBatchTestMVN {
    static List<Case> interactions;
    static List<Case> requests = new List<Case>();

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

  	@isTest static void verifyCleanupWorksWhenAllChildrenClosed() {
	    List<Case> childCases = TestDataFactoryMVN.createrequests(interactions, 'Open');
	    for (Case c : childCases) {
	      c.Status = CaseCloserBatchMVN.closedStatus;
	    }
	    update childCases;

	    Test.startTest();
        Database.executeBatch(new CaseCloserBatchMVN());
	    Test.stopTest();

	    assertParentStatusesAre(CaseCloserBatchMVN.closedStatus, 'Case Status not set to Closed.');
  	}

  	@isTest static void verifyCleanupDoesNoAffectParentsWithAllChildrenNotClosed() {

		TestDataFactoryMVN.createrequests(interactions, 'Open');

	    Test.startTest();
        CaseCloserBatchMVN caseCloserBatch = new CaseCloserBatchMVN();
        caseCloserBatch.execute(null);
	    Test.stopTest();

	    assertParentStatusesAre('Open', 'Case Status was changed.');
	}

 	@isTest static void verifyCleanupDoesNotAffectParentsWithoutChildren() {

    	Test.startTest();
        CaseCloserBatchMVN caseCloserBatch = new CaseCloserBatchMVN();
        caseCloserBatch.execute(null);
    	Test.stopTest();

    	assertParentStatusesAre('Open', 'Case Status was changed.');
 	}

  	@isTest static void exerciseSendEmailFunctionaltiy() {

    	List<Case> childCases = TestDataFactoryMVN.createrequests(interactions, CaseCloserBatchMVN.closedStatus);
    	for (Case c : childCases) {
      	c.Status = CaseCloserBatchMVN.closedStatus;
    	}
    	update childCases;

	    Test.startTest();
            try{
                Messaging.reserveSingleEmailCapacity(1);
    	        CaseCloserBatchMVN batch = new CaseCloserBatchMVN();
    	        CaseCloserBatchMVN.testSendEmail = true;
    	        Database.executeBatch(batch);
            }catch(Exception e){
                // An exception here generally indicates that user email
                // is not permitted in the org.
                System.debug('Exception while sending email: ' + e.getMessage());
            }
	    Test.stopTest();
  	}

  	static void assertParentStatusesAre(String status, String error) {
    	interactions = [SELECT Id, Status FROM Case where Id IN :interactions and Status = :status];
    	System.assert(interactions.size() == TestDataFactoryMVN.TEST_DATA_SIZE, 'Something happened to the parent cases, should be 25 but there are : ' + interactions.size());
  	}
}