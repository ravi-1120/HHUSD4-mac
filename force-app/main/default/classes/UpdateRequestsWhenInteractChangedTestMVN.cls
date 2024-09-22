/*
* UpdateRequestsWhenInteractChangedTestMVN
* Created By:    Roman Lerman
* Created Date:  3/4/2013
* Description:   This is the test class for UpdateRequestsWhenInteractionChangedMVN
*/
@isTest
private class UpdateRequestsWhenInteractChangedTestMVN {
	static Case cs;
	static Case request;
	static Case request2;

	static Case cs2;
	static Case request3;
	static Case request4;

	static List<Case> requestList;

	static Account personAccount;

	static{
		TestDataFactoryMVN.createSettings(true);

		requestList = new List<Case>();

		cs = TestDataFactoryMVN.createTestCase();
		request = TestDataFactoryMVN.createTestRequest(cs);
		request2 = TestDataFactoryMVN.createTestRequest(cs);

		requestList.add(request);
		requestList.add(request2);

		personAccount = TestDataFactoryMVN.createTestPersonAccount();
	}

	static testMethod void testRequestUpdate(){
		Id personContactId = [select PersonContactId from Account where Id = :personAccount.Id].PersonContactId;
		Id addressId = TestDataFactoryMVN.createTestAddress(personAccount).Id;

		String email = 'johnsmith@test.com';
		String fax = '123-123-1221';
		String phone = '123-345-2323';

		cs.AccountId = personAccount.Id;
		cs.ContactId = personContactId;
		cs.Address_MVN__c = addressId;

		cs.case_Account_Email_MVN__c = email;
		cs.case_Account_Fax_MVN__c = fax;
		cs.case_Account_Phone_MVN__c = phone;

		Test.startTest();
			update cs;
		Test.stopTest();

		for(Case req:[select AccountId, ContactId, Parent.AccountId, Parent.ContactId, Address_MVN__c,
							 case_Account_Email_MVN__c, case_Account_Fax_MVN__c, case_Account_Phone_MVN__c
							 from Case where Id in :requestList]){
			System.assertEquals(req.AccountId, personAccount.Id);
			System.assertEquals(req.ContactId, personContactId);
			System.assertEquals(req.Address_MVN__c, addressId);

			System.assertEquals(req.case_Account_Email_MVN__c, email);
			System.assertEquals(req.case_Account_Fax_MVN__c, fax);
			System.assertEquals(req.case_Account_Phone_MVN__c, phone);
		}
	}
}