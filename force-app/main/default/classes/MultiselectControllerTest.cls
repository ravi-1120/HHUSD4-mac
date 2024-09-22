//This is a test class.
@isTest
private class MultiselectControllerTest {
    Set<String> leftOptions = new Set<String>();
    @isTest static void testMoveToLeft(){
        Test.startTest();
        try{
        MultiselectController mulSelCon = new MultiselectController(); 
            mulSelCon.selectedOp ='selectedOpt';
        mulSelCon.moveToLeft();
        }catch(exception e){}
        Test.stopTest();  
    }
    
    @isTest static void testMoveToRight(){
        Test.startTest();
        try{
        MultiselectController mulSelCon = new MultiselectController();
            mulSelCon.selectedOp ='selectedOpt';
        mulSelCon.moveToRight();
        }catch(exception e){}
        Test.stopTest();  
    }
    @isTest
    static List<SelectOption> getselectedValues(){
        List<SelectOption> options = new List<SelectOption>();
        List<String> objList = new List<String>();
        Set<String> leftOptions = new Set<String>();
        objList.addAll(leftOptions);
        objList.sort();
        for(String s : objList){
            options.add(new SelectOption(s,s));
        }
        return options;
    }
    @isTest static void testGetKnowledgeList(){ 
        MultiselectController mulSelCon = new MultiselectController();
        List<Knowledge__kav> knowledgeList2 = new List<Knowledge__kav>();
        Knowledge__kav kRecord = new knowledge__kav();
        for(integer i=0; i<4; i++)
        {
            kRecord.Title = 'Testing the Knowledge Comment and Conversation flow' + i;
            kRecord.UrlName = 'Testing-the-Knowledge-Comment-and-Conversation-flow';
            kRecord.MSD_CORE_Audience__c = 'CONSUMER';
            kRecord.MSD_CORE_KnwlArtCat__c = 'NSC';
            knowledgeList2.add(kRecord);
        }
        //insert knowledgeList2;
        List<Id> memIds = new List<Id>();
		List<Id> userIds = new List<Id>();
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        //ProcessSubmitRequest process = new ProcessSubmitRequest();
        Test.startTest();
        mulSelCon.knowledgeList = knowledgeList2;
        mulSelCon.memIds =memIds;
        mulSelCon.comment = 'comment2';
        mulSelCon.submitAndProcessApprovalRequest();
        Test.stopTest();  
    }
    	
     }