@isTest
public class NiceInContactControllerTest {
	@testSetup
    static void testData(){
        
    }
    
    @isTest
    static void test_getAccessToken(){
        Test.setMock(HttpCalloutMock.class, new AuthTokenMock());
        NiceInContactController.getAccessToken();
    }
    
    @isTest
    static void test_callMeNowHttpRequest(){
        String scheduleString = JSON.serialize(TestDataFactory_MODTest.schedulerSaveResponseTest());
    	Test.setMock(HttpCalloutMock.class, new ContactIdMock());
        Test.startTest();
        	NiceInContactController.callMeNowHttpRequest(scheduleString,'1234');
        	NiceInContactController.scheduleCallbackHttpRequest(scheduleString,'1234');
        Test.stopTest();        
    }
    
    @isTest
    static void test_callMeNowHttpRequest1(){
        String scheduleString = JSON.serialize(TestDataFactory_MODTest.schedulerSaveResponseTest());
    	Test.setMock(HttpCalloutMock.class, new ContactIdMock1());
        Test.startTest();
        	NiceInContactController.callMeNowHttpRequest(scheduleString,'1234');
        	NiceInContactController.scheduleCallbackHttpRequest(scheduleString,'1234');
        Test.stopTest();        
    }
    
    @isTest
   public static void test_getAgentAvilability(){
        String scheduleString = JSON.serialize(TestDataFactory_MODTest.schedulerSaveResponseTest1()); 
    	Map<String,Object> schMap = (Map <String,Object> ) JSON.deserializeUntyped(scheduleString);
        Test.setMock(HttpCalloutMock.class, new AgentAvailabilityMock());
        Test.startTest();
        	NiceInContactController.getAgentAvilability(schMap);
        Test.stopTest();        
    }
    
    private class AuthTokenMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('{"access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9. eyJpY0JVSWQiOjQ1OTc5NzIsIm5hbWUiOiJ","token_type": "bearer","expires_in":3600,"refresh_token":"2COGx6Rn1EGEKf3KeBxmyg==","scope": "RealTimeApi AdminApi PatronApiReportingApi","resource_server_base_uri":"https://apib2.incontact.com/inContactAPI/","refresh_token_server_uri": "https://apib2.incontact.com/InContactAuthorizationServer/Token","agent_id": 15324003,"team_id": 412596,"bus_no": 4597972}');
            res.setStatusCode(200);
            return res;
        }
    }//End of AuthTokenMock class
    
    private class ContactIdMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('<body><div><span id="lblSpawn"><strong>Script spawned. Contact ID:129730144568</strong></span></div></form></body>');
            res.setStatusCode(200);
            return res;
        }
    }//End of ContactIdMock class
    
    private class ContactIdMock1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('<body><div><span id="lblSpawn"><strong>Script spawned. Contact ID:129730144568</strong></span></div></form></body>');
            res.setStatusCode(400);
            return res;
        }
    }
    
    private class AgentAvailabilityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            String response = '{"lastPollTime": "2020-10-28T18y23y18.047Z","skillActivity": [{"serverTime": "2020-10-28T18y21y20.000Z","businessUnitId": 4597972,"agentsACW": 0,"agentsAvailable": 0,"agentsIdle": 0,"agentsLoggedIn": 1,"agentsUnavailable": 1,"agentsWorking": 0,"campaignId": 2570145,"campaignName": "MVCC","contactsActive":0,"earliestQueueTime": null,"emailFromAddress": ""}]}';
    		res.setBody(response);
            res.setStatusCode(200);
            return res;
        }
    }
}