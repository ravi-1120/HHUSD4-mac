@isTest
public with sharing class ExceptionHandlerTest {

    @IsTest
    static void test1() {
        
        Test.startTest();        
        MHEEExceptionHandler.futureLogException('test','testclass','testmethod','testfeature');        
        MHEEExceptionHandler.logException(new System.DmlException(),'testclass','testmethod');
        MHEEExceptionHandler.logException(new System.DmlException(),'testclass','testmethod','testfeature');
        MHEEExceptionHandler.logException(new System.DmlException());
        Test.stopTest();
        System.assert(MHEEExceptionHandler.CLASS_NAME == 'MHEEPortalExceptionHandler',true);
    }   

    @IsTest
    static void test2() {
        
        Test.startTest();      
        GenericException generic = new GenericException('testerrorcode','testerrormsg');  
        generic.getErrorMsg();
        generic.getReasonCode();        
        Test.stopTest();
        System.assert(generic.getErrorMsg() == 'testerrormsg',true);
    }
}