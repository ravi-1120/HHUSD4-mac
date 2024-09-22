/*
* ReopenParentCaseWhenChildReopenedTestMVN
* Created By:    Kai Amundsen
* Created Date:  6/23/2013
* Description:   This is the test class for ReopenParentCaseWhenChildReopenedMVN
*/
@isTest
private class ReopenParentCaseWhenChildReopenedTestMVN {

	static Case parent1;
	static Case child1;
	static Case child2;

	static List<Case> casesList;

	static {
		TestDataFactoryMVN.createSettings(true);

		parent1 = TestDataFactoryMVN.createClosedTestCase();
		child1 = parent1.clone(false, true, false, false); 
		child1.ParentId = parent1.Id;

		child1.recordTypeId = TestDataFactoryMVN.requestRecordTypeId; 
		child2 = child1.clone(false, true, false, false);

		casesList = new List<Case> {parent1, child1, child2};
		upsert casesList; 
	}

	static void updateCases() {
		for (Case thisCase : [SELECT Id, Status, RecordType.Id FROM Case WHERE Id in :casesList]) {
			if (thisCase.Id == parent1.Id) {
				parent1 = thisCase;
			} else if (thisCase.Id == child1.Id) {
				child1 = thisCase;
			} else if (thisCase.Id == child2.Id) {
				child2 = thisCase;
			}
		}
	}

	@isTest static void verifyParentOneReopened() {
		for (Case thisCase : casesList) {
			System.AssertEquals('Closed', thisCase.Status);
		}

		Test.startTest();
		child1.Status = 'Open';
		update child1;

		updateCases();
		Test.stopTest();

		System.AssertEquals('Open', parent1.Status);
		System.AssertEquals(TestDataFactoryMVN.interactionRecordTypeId, parent1.RecordTypeId);
		System.AssertEquals('Open', child1.Status);
		System.AssertEquals('Closed', child2.Status);
	}
}