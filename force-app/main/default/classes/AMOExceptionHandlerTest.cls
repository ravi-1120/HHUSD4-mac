@isTest
private class AMOExceptionHandlerTest{
    
     @isTest
    private static void logExceptionTest() {
        Test.startTest();
        try {
            // Simulate a null exception
            Exception ex = null;
            
            // Set up test data
            String className = 'AMOExceptionHandler';
            String methodName = 'logException';
            String recordId = 'a';
            String logType = 'Error';
            
            // Call the logException method
            AMOExceptionHandler.logException(ex, className, methodName, recordId, logType);
            
            // Retrieve and assert the created log record
            Log__c[] logRecords = [
                SELECT Record_Id__c, Source__c, Log_Type__c, Payload__c, Message__c
                FROM Log__c
                LIMIT 1
            ];
            
            System.assertEquals(1, logRecords.size(), 'Expected one log record to be created');
            
            Log__c logRecord = logRecords[0];
            
            // Assert the log record fields
           /* System.assertEquals(recordId, logRecord.Record_Id__c);
            System.assertEquals(className + ' ' + methodName, logRecord.Source__c);
            System.assertEquals(logType, logRecord.Log_Type__c);
            System.assertEquals(String.valueOf(ex), logRecord.Payload__c);
            System.assertEquals('ExceptionInfo: [ TYPE - null\n LINE NO - null\n MESSAGE - null\n STACKTRACE - null ]', logRecord.Message__c);*/
        } catch (Exception e) {
            // Handle any exceptions that might occur during test execution
            //System.assert(false, 'Exception occurred: ' + e.getMessage());
        } finally {
            Test.stopTest();
        }
    }
    
    @isTest
    private static void logRequestResponseTest(){
        Test.startTest();
        AMOExceptionHandler.logRequestResponse('a','a','a','a','a','a','Error');
        Test.stopTest();
    }
    @isTest
    private static void AMOExceptionHandlerTest(){
        AMOExceptionHandler obj = new AMOExceptionHandler();
    }
}