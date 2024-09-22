/* KRB  9/2021 - REST API Class containing the POST Method used to interface with the 
 * 				High Temp Excursion Calculator. 
    
   //KRB 22R3.1 8/12/2022 Added Germany Market Code (DE) to Market Validation Code
   //KRB 23R2.0 4/19/2023 Added Switzerland Market Code (CH) to Market Validation Code
   //KRB 23R4.0 9/11/2023 Added Brazil Market Code (BR) to Market Validation Code
   //KRB 23R4.0 9/26/2023 Added Singapore Market Code (SG) to Market Validation Code
   //KRB 23R4.0 9/26/2023 Added United Kingdom Market Code (GB) to Market Validation Code
   //KRB 23R4.0 10/11/2023 Added Korea Market Code (KR) to Market Validation Code
   //KRB 23R4.1 11/27/2023 Added Australia Market Code (AU) to Market Validation Code
   //KRB 24R1.0 1/3/2024 Added Israel Market Code (IL) to Market Validation Code
   //KRB 24R1.0 1/31/2024 Added Italy and Canada Market Codes (IT, CA) to Market Validation Code
   //KRB 24R1.0 2/2024 Added France Market Code (FR) to Market Validation Code
   
   For Testing: 

   In Workbench: Go to REST Explorer and enter the following: 

   Execute POST to /services/apexrest/msdcore/v1/MSD_CORE_HighTempExAssessmentService/

   JSON Body of POST:
   {
      "market" : "EU",
      "brandNameProduct" : "BRENZYS",
      "temperatureUnit" : "C",
      "exposureDetails": [{
        "MSD_CORE_hours__c": 2,
        "MSD_CORE_Min__c": 3,
        "MSD_CORE_Seconds__c": 4,
        "MSD_CORE_Temp__c": 21
      }, {
        "MSD_CORE_hours__c": 5,
        "MSD_CORE_Min__c": 6,
        "MSD_CORE_Seconds__c": 7,
        "MSD_CORE_Temp__c": 32
      }]
}

    Calling from a different Salesforce Org:

	1. Make sure to add 2 new Remote Site Records in the Calling Org:
		For Example, if calling from HHUSD3, make sure to add 
		each of these as a New Remote Site Record in HHUSD3: 
		https://test.salesforce.com
		https://msdlogin-hhusd4.my.salesforce.com

    2. Make sure the API User in the Environment where the User was created has access to this APEX Class in their Profile. 

	3. Create a Class to call the Service (see notes at bottom of Class for an example Class):
		
*/

@RestResource(urlMapping='/msdcore/v1/MSD_CORE_HighTempExAssessmentService/*')
global with sharing class MSD_CORE_HighTempExAssessmentService {
   
    @HttpPost
    global static String calculateHighTempAssessment( String market, 
                                                      String brandNameProduct, 
                                                      String temperatureUnit,  
                                                      MSD_CORE_TempExcurExposDetail__c[] exposureDetails) {
        	    
         MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();
                                                          
         System.debug('MSD_CORE_TempExAssessmentService: Details from POST: market:' + market + 
                       ' brandNameProduct:' + brandNameProduct + 
                       ' temperatureUnit:' + temperatureUnit);     
                                                         
         //Validate input - quick return if invalid
         if (String.isEmpty(market) 
             || String.isEmpty(brandNameProduct) 
             || String.isEmpty(temperatureUnit) 
             || (temperatureUnit != 'F' && temperatureUnit != 'C')
             || (market != 'US' && market != 'EU' && market != 'DE' && market != 'CH' && market != 'BR' && market != 'SG' && market != 'GB' && market != 'KR' && market != 'AU' && market != 'IL' && market != 'IT' && market != 'CA' && market != 'FR')   //Added DE for 22R3.1 8/1/22 KRB - Added CH for 23R2.0
             || (exposureDetails == null  || exposureDetails.size() == 0 )
            ){
                results.supportIndicator = 'ERROR: Invalid Data Provided to REST API Service';
                return JSON.serialize(results);
         } 
                                                          
         //validate the Values passed in as Excursions:
         for (MSD_CORE_TempExcurExposDetail__c exdtl : exposureDetails) {
             
            boolean error = false;
                        
            if(exdtl.MSD_CORE_hours__c == null     //Validate no nulls
               || exdtl.MSD_CORE_Min__c == null
               || exdtl.MSD_CORE_Seconds__c == null
               || exdtl.MSD_CORE_Temp__c == null 
               || exdtl.MSD_CORE_hours__c.round(System.roundingMode.FLOOR) <> exdtl.MSD_CORE_hours__c //Validate no Decimal Places
               || exdtl.MSD_CORE_Min__c.round(System.roundingMode.FLOOR) <> exdtl.MSD_CORE_Min__c
               || exdtl.MSD_CORE_Seconds__c.round(System.roundingMode.FLOOR) <> exdtl.MSD_CORE_Seconds__c
             //  || exdtl.MSD_CORE_Temp__c.round(System.roundingMode.FLOOR) <> exdtl.MSD_CORE_Temp__c //Removed 22R3.0 KRB 7/12/2022
               || exdtl.MSD_CORE_hours__c < 0 									//Validate correct values passed
               || (exdtl.MSD_CORE_Min__c < 0 || exdtl.MSD_CORE_Min__c > 59 )
               || (exdtl.MSD_CORE_Seconds__c < 0 || exdtl.MSD_CORE_Seconds__c > 59 )
               
              ){
                 error = true;
             }
             
             if (error){
                results.supportIndicator = 'ERROR: Invalid Data Provided to REST API Service';
                return JSON.serialize(results);
             }
        
         }
                                                          
         String defaultGenericNameProduct = ''; //Not yet used in Calculation, but needs to be passed. 
        
         List <MSD_CORE_TempExcurExposDetail__c> details = new List <MSD_CORE_TempExcurExposDetail__c>();
          
         for (MSD_CORE_TempExcurExposDetail__c exdtl : exposureDetails) {
                                    
            MSD_CORE_TempExcurExposDetail__c detail = new MSD_CORE_TempExcurExposDetail__c();
            detail.MSD_CORE_hours__c = exdtl.MSD_CORE_hours__c; 
            detail.MSD_CORE_Min__c = exdtl.MSD_CORE_Min__c;
		    detail.MSD_CORE_Seconds__c = exdtl.MSD_CORE_Seconds__c;
		    detail.MSD_CORE_Temp__c = exdtl.MSD_CORE_Temp__c;
		    details.add(detail);
             
         }
                     
         EndUserHighTempExcursionAssessment x = new EndUserHighTempExcursionAssessment();
 	      
         results = x.processHighTempExcursionAssessment(details, 
                                                        market,
                                                        brandNameProduct,
       					                                defaultGenericNameProduct, 
                                                        temperatureUnit);

         System.debug('MSD_CORE_TempExAssessmentService:FINAL RESULTS: Support Indicator: ' + results.supportIndicator);
         System.debug('MSD_CORE_TempExAssessmentService:FINAL RESULTS: Label Storage Condition: ' + results.labelStorageCondition);
         System.debug('MSD_CORE_TempExAssessmentService:FINAL RESULTS: High Temp Foot Note: ' + results.HTFootNote);
         System.debug('MSD_CORE_TempExAssessmentService:FINAL RESULTS: High Temp Comment: ' + results.HTComment);    
                    
         return JSON.serialize(results); 
           
    }   
    
}


/*
 
//To run this Class to Test the Service:

1. Create a Class in the Calling Environment using the code below (See #Class Code# below), named CallHighTempExCalcRestAPIService
1. Copy and paste this line of code in the Anonymous Window in the Developer Debug Window and run it with Logging Turned on:
	
 	CallHighTempExCalcRestAPIService.callHighTempExService();

Example Response:  "{\"timeLimitNote\":\"\",\"supportIndicator\":\"Stability Data does not Support Continued Use\",\"Outcome2\":\"\",\"Outcome1\":\"\",\"notes\":\"\",\"labelStorageCondition\":\"2.0C to 8.0C\",\"HTFootNote\":\"\",\"HTComment\":\"Send temperature excursion inquiries to bioepisqa@samsung.com.\"}"

Below is Sample Code. Do not use it for Production. Do not Hardcode any values in the Code. This is for Testing Purposes Only. 

#Class Code#:

public class CallHighTempExCalcRestAPIService {
    private final String clientId = '<Enter MSD_CORE_TempEx_Calculator_Service Connected App Id>';
    private final String clientSecret = '<Enter MSD_CORE_TempEx_Calculator_Service Connected App Secret Key>';
    private final String username = '<Enter gmsa_portal user Name>';
    private final String password = '<Enter gmsa_portal user Name Password>';
    public class deserializeResponse
    {
        public String id;
        public String access_token;
    }
    public String ReturnAccessToken() 
    {
        String reqbody = 'grant_type=password&client_id='
            +clientId+'&client_secret='
            +clientSecret+'&username='
            +username+'&password='+password;
        System.debug('KRB: URL: ' + reqbody);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqbody);
        req.setMethod('POST');
        req.setEndpoint('https://test.salesforce.com/services/oauth2/token');
        HttpResponse res = h.send(req);
        deserializeResponse response = (deserializeResponse)JSON.deserialize(res.getbody(),deserializeResponse.class);
        system.debug('KRB: @@access_token@@'+response );
        return response.access_token;
    }
    public static void callHighTempExService()
    {
        CallHighTempExCalcRestAPIService highTempCalcService = new CallHighTempExCalcRestAPIService();
        String accessToken;
        accessToken = highTempCalcService.ReturnAccessToken(); 

        if(accessToken != null) {
            String endPoint = 'https://msdlogin--hhusd4.my.salesforce.com/services/apexrest/msdcore/v1/MSD_CORE_HighTempExAssessmentService/';
            Http h2 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('Authorization','Bearer ' + accessToken);
            req1.setHeader('Content-Type','application/json');
            req1.setHeader('accept','application/json');
            //String body = '{"market" : "EU","brandNameProduct" : "BRENZYS","temperatureUnit" : "C","exposureDetails": [{"MSD_CORE_hours__c": 2,"MSD_CORE_Min__c": 3,"MSD_CORE_Seconds__c": 4,"MSD_CORE_Temp__c": 21.21}, {"MSD_CORE_hours__c": 5,"MSD_CORE_Min__c": 6,"MSD_CORE_Seconds__c": 7,"MSD_CORE_Temp__c": 32.32}]}';
            String body = '{"market" : "US","brandNameProduct" : "ZOSTAVAX Frozen","temperatureUnit" : "C","exposureDetails": [{"MSD_CORE_hours__c": 2,"MSD_CORE_Min__c": 3,"MSD_CORE_Seconds__c": 4,"MSD_CORE_Temp__c": 21.21}, {"MSD_CORE_hours__c": 5,"MSD_CORE_Min__c": 6,"MSD_CORE_Seconds__c": 7,"MSD_CORE_Temp__c": 32.32}]}';                      
                      
            req1.setBody(body);
            req1.setMethod('POST');
            req1.setEndpoint(endPoint);
            HttpResponse res1 = h2.send(req1);
            
            if(res1.getStatusCode() != 200){
               System.debug('The Status Code Returned was not expected: ' + 
                           res1.getStatusCode() + ' ' + res1.getStatus());   
            }else{
            
            	String trimmedResponse = res1.getBody().unescapeCsv().remove('\\');
            	system.debug('@@@RESPONSE@@'+trimmedResponse);
            	JSONParser parser = JSON.createParser(res1.getBody());
                
                Map<String, Object> o = (Map<String, Object>) JSON.deserializeUntyped(trimmedResponse);
                
                System.debug('Support Indicator: ' + o.get('supportIndicator'));
                System.debug('Label Storage Condition: ' + o.get('labelStorageCondition'));
                System.debug('Foot Note: ' + o.get('HTFootNote'));
                System.debug('Comment: ' + o.get('HTComment'));

             }
        }
    }
}
*/