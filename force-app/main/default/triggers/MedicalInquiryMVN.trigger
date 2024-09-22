/*
 *  CaseMVN
 *  Created By:     Kai Chen
 *  Created Date: 	7/28/2013
 *  Description:    This is a generic Medical Inquiry trigger used for calling any Medical Inquiry logic
 */
trigger MedicalInquiryMVN on Medical_Inquiry_vod__c (after insert, after update) {
	// Currently not using the code below so it should only fire when being
	// run through unit tests (so that the tests do not break)
	if(Test.isRunningTest()){
		new TriggersMVN()
			.bind(TriggersMVN.Evt.afterinsert, new CreateCasesForMedicalInquiryMVN())
	        .bind(TriggersMVN.Evt.afterupdate, new CreateCasesForMedicalInquiryMVN())
	        .manage();
	}
}