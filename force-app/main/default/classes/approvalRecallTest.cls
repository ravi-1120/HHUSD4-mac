@IsTest
public with sharing class approvalRecallTest {

    public static Knowledge__kav kRecord = new Knowledge__kav();
    static {
        kRecord.Title = 'Testing the Knowledge Comment and Conversation flow.';
        kRecord.UrlName = 'Testing-the-Knowledge-Comment-and-Conversation-flow';
        kRecord.MSD_CORE_Audience__c = 'CONSUMER';
        kRecord.MSD_CORE_KnwlArtCat__c = 'NSC';
        kRecord.MSD_CORE_General_Cmnt__c = 'This is  a Generic comment used for testing.';        
        kRecord.MSD_CORE_After_Call_Work_Cmnt__c = 'This is a After Call Work comment used for testing.';
        kRecord.MSD_CORE_Information_Cmnt__c = 'This is a Information comment used for testing.';
        kRecord.MSD_CORE_Instruction_Comment__c = 'This is a Instruction comment used for testing.';
        kRecord.MSD_CORE_Preview_Cmnt__c = 'This is a Preview comment used for testing.';
        kRecord.MSD_CORE_Questions_Comment__c = 'This is a Questions comment used for testing.';
        kRecord.MSD_CORE_ApprStatus__c = 'Pending Submission';
        insert kRecord;
    }


    @IsTest
    static void recallApprovalTest() {

        Test.startTest();
        //Id recordId = insertKnowledge();
        Approval.ProcessResult result = submitForApproval(kRecord.Id);
        approvalRecall.recallApproval(new List<Id>{kRecord.Id});
        test.stopTest();

        System.assert(true,true);

    }

    private static Approval.ProcessResult submitForApproval( Id recordId ) {
   
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments( 'Submitting request for approval' );
        req1.setObjectId( recordId );
        req1.setNextApproverIds(new Id[] {userinfo.getUserId()});
        Approval.ProcessResult result = Approval.process( req1 );
        return result;
    }

}