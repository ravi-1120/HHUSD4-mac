@isTest(SeeAllData=true)
public class CaseControllerMVNTest {
    
    private static Case testCase = new Case();
    private static Account testAccount = new Account();
    private static User testuser = new User();
    private static List<CaseControllerMVN.CaseAERequiredFieldWrapper> fieldWrapperList = new List<CaseControllerMVN.CaseAERequiredFieldWrapper>();
    private static CaseControllerMVN.CustomerInfoWrapper testCustomerInfoWrapper = new CaseControllerMVN.CustomerInfoWrapper();
    private static CaseControllerMVN.InteractionWrapper testInteractionWrapper = new CaseControllerMVN.InteractionWrapper();
    
    static{
        testAccount = TestDataFactoryMVN.createTestPersonAccount();
        testCase = TestDataFactoryMVN.createTestCase(null, false);
        testuser = TestDataFactoryMVN.createTestUser();
    }
    
    @isTest static void testqueryCase(){
        Test.startTest();
        case resultcase = CaseControllerMVN.queryCase(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testqueryCaseFields(){
        Test.startTest();
        fieldWrapperList = CaseControllerMVN.queryCaseFields(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testFieldWrapper(){
        Test.startTest();
        CaseControllerMVN.FieldWrapper testclassFieldWrapper = new CaseControllerMVN.FieldWrapper('FNamel', 'FLabel', true, false, 'Type');
        Test.stopTest();
    }
    
    @isTest static void testgetAEFieldsData(){
        Test.startTest();
        case testcaseAEData = CaseControllerMVN.getAEFieldsData(testCase.id);
        Test.stopTest();
    }
    
    @isTest static void testgetRequestFieldsData(){
        Test.startTest();
        case testcaseRFData = CaseControllerMVN.getRequestFieldsData(testCase.id);
        Test.stopTest();
    }
    
    @isTest static void testqueryAERequiredFields(){
        Test.startTest();
        fieldWrapperList = CaseControllerMVN.queryAERequiredFields(testCase.id);
        Test.stopTest();
    }
    
    @isTest static void testupdateCaseStatus(){
        Test.startTest();
        string returnStatus = CaseControllerMVN.updateCaseStatus(testCase.id, 'Open');
        string returnStatus2 = CaseControllerMVN.updateCaseStatus(testCase.id, 'Closed');
        Test.stopTest();
    }
    
    @isTest static void testgetSendEmailData(){
        Test.startTest();
        CaseControllerMVN.SendEmailWrapper testSendEmailWrapper =new CaseControllerMVN.SendEmailWrapper();
        testSendEmailWrapper = CaseControllerMVN.getSendEmailData(testCase.id);
        Test.stopTest();
    }
    
    @isTest static void testgetSessionIdFromVFPage(){
        Test.startTest();
        //string testSessionId = CaseControllerMVN.getSessionIdFromVFPage();
        Test.stopTest();
    }
    
    @isTest static void testgetValidCase(){
        Test.startTest();
        case testcase =  [select Id from case limit 1];
        boolean testvalid = CaseControllerMVN.getValidCase(testCase.id);
        Test.stopTest();
    }
    
    @isTest static void testgetEmailTemplateList(){
        Test.startTest();
        List<EmailTemplate> testEmailTemplateList = new List<EmailTemplate>();
        List<EmailTemplate> testreturnList = [select Id from EmailTemplate where IsActive = true limit 1];
        List<EmailTemplate> testreturnEmailTemplateList = CaseControllerMVN.getEmailTemplateList(testreturnList[0].Id);
        Test.stopTest();
    }
    
    @isTest static void testgetEmailBody(){
        Test.startTest();
        List<EmailTemplate> testEmailTemplate = [SELECT Id FROM EmailTemplate limit 1];
        string emailSubject = CaseControllerMVN.getEmailBody(testCase.id, testEmailTemplate[0].Id);
        Test.stopTest();
    }
    
    @isTest static void testSendMail(){
        CaseControllerMVN.SendEmailWrapper testSendEmailWrapper =new CaseControllerMVN.SendEmailWrapper();
        List<Contact> testcontactList = new List<Contact>();
        testcontactList = [select id, Email from Contact where Email != null limit 50];
        List<Attachment> testattList = new  List<Attachment>();
        testattList = [SELECT Id FROM Attachment limit 2];
        list<Id> listattId = new list<Id> ();
        for(Attachment a : testattList){
            listattId.add(a.Id); 
        }
        Test.startTest();
        string returnstatus = CaseControllerMVN.SendMail (testSendEmailWrapper , 'testto@email.com', 'testcc@email.com' , testcontactList[0].Id, listattId );
        Test.stopTest();
    }
    
    @isTest static void testgetTypeSelectOptions(){
        Test.startTest();
        List<String> returnSelectOptions = new List<String>();
        returnSelectOptions = CaseControllerMVN.getTypeSelectOptions(true);
        returnSelectOptions = CaseControllerMVN.getTypeSelectOptions(false);
        Test.stopTest();
    }
    
    @isTest static void testtypeSelected(){
        Test.startTest();
        string resulttypeSelected = CaseControllerMVN.typeSelected(' hcpType ');
        string resulttypeSelected2 = CaseControllerMVN.typeSelected(' Type ');
        Test.stopTest();
    }
    
    @isTest static void testupdateCaseWithAccount(){
        Test.startTest();
        Account testAccount = new Account();
        testAccount = TestDataFactoryMVN.createBusiness();
        Address_vod__c testadress = new Address_vod__c();
        testadress = [select id from Address_vod__c where Address_Type_MRK__c != 'Physical' and Inactive_vod__c = true limit 1];
        string resulttypeSelected = CaseControllerMVN.updateCaseWithAccount(testcase.Id, testAccount.Id, testadress.Id, 'Business' );
        Test.stopTest();
    }
    
    @isTest static void testcreateRepFollowup(){
        Test.startTest();
        string resultRepFollowup = CaseControllerMVN.createRepFollowup(testCase.Id, testAccount.Id, 'Business');
        Test.stopTest();
    }
    
    @isTest static void testqueryCaseInformations(){
        Test.startTest();
        case resultcase = CaseControllerMVN.queryCaseInformations(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testgetCustomerInfo(){
        Test.startTest();
        testCustomerInfoWrapper = CaseControllerMVN.getCustomerInfo(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testgetCustomerInfo2(){
        Test.startTest();
        testCustomerInfoWrapper = CaseControllerMVN.getCustomerInfo2(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testgetFieldsMapPicklists(){
        Test.startTest();
        Map<String,Map<String,String>> testresultmap = new Map<String,Map<String,String>>(); 
        testresultmap = CaseControllerMVN.getFieldsMapPicklists(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testdedupeEmailPicklists(){
        Test.startTest();
        Set<String> resultemails = new Set<String>();
        resultemails = CaseControllerMVN.dedupeEmailPicklists(testAccount);
        Test.stopTest();
    }
    
    @isTest static void testremoveSelectedCustomer(){
        Test.startTest();
        CaseControllerMVN.removeSelectedCustomer(testcase.Id);
        Test.stopTest();
    }    
    
    @isTest static void testremoveSelectedReferredBy(){
        Test.startTest();
        CaseControllerMVN.removeSelectedReferredBy(testcase.Id);
        Test.stopTest();
    }    
    
    @isTest static void testremoveSelectedBusiness(){
        Test.startTest();
        CaseControllerMVN.removeSelectedBusiness(testcase.Id);
        Test.stopTest();
    }
    
    @isTest static void testupdateAddress(){
        Address_vod__c testadd = [select Id from Address_vod__c limit 1];
        Test.startTest();
        CaseControllerMVN.updateAddress(testcase.Id, testadd.Id);
        Test.stopTest();
    }
    
    @isTest static void testupdatePhone(){
        Test.startTest();
        CaseControllerMVN.updatePhone(testcase.Id, '9923654525');
        Test.stopTest();
    }
    
    @isTest static void testupdateEmail(){
        Test.startTest();
        CaseControllerMVN.updateEmail(testcase.Id, 'test@email.com');
        Test.stopTest();
    }
    
    @isTest static void testupdateFax(){
        Test.startTest();
        CaseControllerMVN.updateFax(testcase.Id, '9923654525');
        Test.stopTest();
    }
    
    @isTest static void testcreateEmail(){
        Test.startTest();
        string result = CaseControllerMVN.createEmail(testcase.Id, 'test@email.com');
        Test.stopTest();
    }
    
    @isTest static void testcreatePhone(){
        Test.startTest();
        string result = CaseControllerMVN.createPhone(testcase.Id, '9874561233');
        Test.stopTest();
    }
    
    @isTest static void testcreateFax(){
        Test.startTest();
        string result = CaseControllerMVN.createFax(testcase.Id, '9874561233');
        Test.stopTest();
    }
    
    @isTest static void testcreateAddress(){
        Test.startTest();
        Address_vod__c testadress = new Address_vod__c();
        CaseControllerMVN.createAddress(testcase.Id, testaccount.Id, testadress);
        Test.stopTest();
    }
    
    @isTest 
    Public static void testcheck(){
        Test.startTest();
        Address_vod__c Add = new Address_vod__c();
        CaseControllerMVN.check(Add); 
        Test.stopTest();
    }
    
    @isTest 
    Public static void testreadOnlyCheck(){
        Test.startTest();
        User u = new User();
        CaseControllerMVN.readOnlyCheck(); 
        Test.stopTest();
    }
    
    @isTest static void testgetCaseStatusPage(){
        Test.startTest();
        testCustomerInfoWrapper = CaseControllerMVN.getCaseStatusPage(testcase.Id);
        Test.stopTest();
    }
    
    @isTest static void testgetCaseInfo(){
        Test.startTest();
        testInteractionWrapper = CaseControllerMVN.getCaseInfo(testcase.Id);
        Test.stopTest();
    }
    
    @isTest static void testqueryZipCodes(){
        Test.startTest();
        List<pw_ccpro__ZipCode__c> resultList = new List<pw_ccpro__ZipCode__c>();
        resultList = CaseControllerMVN.queryZipCodes('235456');
        Test.stopTest();
    }
    
}