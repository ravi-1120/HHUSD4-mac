/*
* Class		    : 	MSD_CORE_HEQ_AuthenticationHelper
* Author		:	Ambadas Joshi (joshi.ambadas@merck.com)
* Purpose		: 	This class handles the authentication to the API integration with Hibbert (print vendor)
* Date Created	:	03-Oct-2024
*/
public class MSD_CORE_HEQ_AuthenticationHelper {

    /*To obtain the access token to be used in subsequent requests*/
	public Static String generateAccessToken() {
        HttpResponse response;
        
        try {
            System.debug('CALLED');            
            MSD_CORE_HEQ_Integration_Creds__c Creds = [SELECT MSD_CORE_HEQ_App_Id__c, MSD_CORE_HEQ_Company_Number__c,
														MSD_CORE_HEQ_Endpoint_URL__c, MSD_CORE_HEQ_User_Name__c,
														MSD_CORE_HEQ_Password__c, MSD_CORE_Division_Number__c, MSD_CORE_HEQ_Session_Timeout__c
														FROM MSD_CORE_HEQ_Integration_Creds__c WHERE 
														MSD_CORE_HEQ_Setting_Name__c = 'Hibbert_Integration'];
			//;MSD_CORE_HEQ_Integration_Creds__c.getValues('Hibbert_Integration');
			String appId = Creds.MSD_CORE_HEQ_App_Id__c;
			String companyNumber = Creds.MSD_CORE_HEQ_Company_Number__c;
			String endpointURL = Creds.MSD_CORE_HEQ_Endpoint_URL__c;		
            String userName = Creds.MSD_CORE_HEQ_User_Name__c;
            String password = Creds.MSD_CORE_HEQ_Password__c;
			String divisionNumber = Creds.MSD_CORE_Division_Number__c;
			String sessionTimeoutInMinutes = Creds.MSD_CORE_HEQ_Session_Timeout__c;

			map<String, String> requestMap = new map<String, String>();
			requestMap.put('appId', appId);
			requestMap.put('username', userName);
			requestMap.put('password', password);
			requestMap.put('companyNumber', companyNumber);
			requestMap.put('sessionTimeoutInMin', sessionTimeoutInMinutes);
			requestMap.put('divisionNumber', divisionNumber);
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointURL);
            request.setMethod('POST');
			request.setBody(JSON.Serialize(requestMap));
            request.setHeader('Content-Type', 'application/json');
			request.setTimeOut(120000);
            //request.setHeader('Accept', 'application/json');            
            system.debug('Request JSON: ' + JSON.Serialize(requestMap));
			response = http.send(request);
			System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus() + '' + response.getBody());
			
            if (response.getStatusCode() != 200) {
            	System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus() + '' + response.getBody());
            //     System.debug('response;-' + response);
            //     Map < String,Object > results = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
            //     //authPOJO.setSession(String.valueOf(results.get('sessionId')));
            //     //authPOJO.setuserId(String.valueOf(results.get('userId')));
             }
            else {
            		System.debug('Success??' + response.getBody());
            }
        } catch(DmlException e) {
            System.debug('Error' + e);
        }
        return response.getBody();
    }

    
}