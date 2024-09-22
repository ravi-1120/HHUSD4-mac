/* KRB 10/2021 - REST API Class containing Methods to interface with the 
 * 				High Temp Excursion Calculator. 
 

    22R3.1 KRB 8/12/2022 - Made the following updates:
		1. 'market' is now a paramater for the HttpPost method
		2. Updates to numerous Debug Statements
		3. Removed the defaulting Market = US logic
		4. Validate that market Parameter Value is not null
		5. Validate that US, EU or DE is passed as the market Parameter Value
		6. In the EndUserLowTempExcursionAssessment.processLowTempExcursionAssessmentSeperateExposures()
				removed the defaultMarket and added the parameter value passed in for market in the HttpPost
   
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

   In Workbench: Goto REST Explorer and enter the following: 

   Execute POST to /services/apexrest/msdcore/v1/MSD_CORE_LowTempExAssessmentService/

   JSON Body of POST:
   {
      "market" : "US",
      "brandNameProduct" : "GARDASIL 9",
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

	1. Make sure to add 2 new Remote Site Records
		For Example, if calling from HHUSD3, make sure to add 
		each of these as a New Remote Site Record in HHUSD3: 
		https://test.salesforce.com
		https://msdlogin-hhusd4.my.salesforce.com

    2. Make sure the API User in the Environment where it was created has access to this APEX Class in their Profile. 

	3. Create a Class to call the Service (see notes at bottom of Class for an example Class):
		In HHUSD3 test class is: CallLowTempExCalcRestAPIService


*/

@RestResource(urlMapping='/msdcore/v1/MSD_CORE_LowTempExAssessmentService/*')
global with sharing class MSD_CORE_LowTempExAssessmentService {
   
    @HttpPost
    global static String calculateLowTempAssessment( String market, //22R3.1 KRB 8/22
        											 String brandNameProduct, 
                                                     String temperatureUnit,  
                                                     MSD_CORE_TempExcurExposDetail__c[] exposureDetails) {
        
        MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();

        System.debug('MSD_CORE_LowTempExAssessmentService: Details from POST:' + 
                     ' market:' + market + //22R3.1 KRB 8/22
                     ' brandNameProduct:' + brandNameProduct + 
                     ' temperatureUnit:' + temperatureUnit);
                                                         
        //Deault values that are not needed...yet...
        
        //22R3.1 Removed                                                
        //String defaultMrkt = 'US'; //Currently, all Countries use the same data for Low Temp.
                                                         
        String defaultGenericNameProduct = ''; //Not used in Current Calculation
        
                                                         
        //Validate input - quick return if invalid
        if (String.isEmpty(brandNameProduct) 
             || String.isEmpty(temperatureUnit) 
             || String.isEmpty(market)  //Added 22R3.1 8/1/22 KRB
             || (temperatureUnit != 'F' && temperatureUnit != 'C')
             || (market != 'US' && market != 'EU' && market != 'DE' && market != 'CH' && market != 'BR' && market != 'SG' && market != 'GB' && market != 'KR' && market != 'AU' && market != 'IL' && market != 'IT' && market != 'CA' && market != 'FR')  //Added 22R3.1 8/1/22 KRB - 23R2.0 KRB added CH
             || (exposureDetails == null  || exposureDetails.size() == 0 )){
           
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
              // || exdtl.MSD_CORE_Temp__c.round(System.roundingMode.FLOOR) <> exdtl.MSD_CORE_Temp__c //Removed 22R3.0 KRB 7/12/2022
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

        List <MSD_CORE_TempExcurExposDetail__c> details = new List <MSD_CORE_TempExcurExposDetail__c>();
          
        for (MSD_CORE_TempExcurExposDetail__c exdtl : exposureDetails) {
             
           System.debug('MSD_CORE_LowTempExAssessmentService: Details from POST: Hrs:' + exdtl.MSD_CORE_hours__c + ' Mins:' + 
                           exdtl.MSD_CORE_Min__c + ' Secs:' + exdtl.MSD_CORE_Seconds__c + 'Temp:' + exdtl.MSD_CORE_Temp__c  );
           
           MSD_CORE_TempExcurExposDetail__c detail = new MSD_CORE_TempExcurExposDetail__c();
           detail.MSD_CORE_hours__c = exdtl.MSD_CORE_hours__c; 
           detail.MSD_CORE_Min__c = exdtl.MSD_CORE_Min__c;
		   detail.MSD_CORE_Seconds__c = exdtl.MSD_CORE_Seconds__c;
		   detail.MSD_CORE_Temp__c = exdtl.MSD_CORE_Temp__c;
		   details.add(detail);
             
          }
           
          EndUserLowTempExcursionAssessment x = new EndUserLowTempExcursionAssessment();                                                          
                                                          
          results = x.processLowTempExcursionAssessmentSeperateExposures(details, 
                                                                         market, //added 22R3.1
                                                                         //defaultMrkt, removed 22R3.1
                                                                         brandNameProduct,
       					                                                 defaultGenericNameProduct, 
                                                                         temperatureUnit);
          
          System.debug('MSD_CORE_LowTempExAssessmentService:FINAL RESULTS: Support Indicator: ' + results.supportIndicator);
          System.debug('MSD_CORE_LowTempExAssessmentService:FINAL RESULTS: Label Storage Condition: ' + results.labelStorageCondition);
          System.debug('MSD_CORE_LowTempExAssessmentService:FINAL RESULTS: Foot Note: ' + results.notes);
          System.debug('MSD_CORE_LowTempExAssessmentService:FINAL RESULTS: Comment: ' + results.timeLimitNote);    
                    
          return JSON.serialize(results); 
           
    }   
    
}


/*
 
//To run this Class:
1. Create a Class in the Calling Environment using the code below (See #Class Code# below), named CallHighTempExCalcRestAPIService
1. Copy and paste this line of code in the Anonymous Window in the Developer Debug Window and run it with Logging Turned on:
	
 	CallLowTempExCalcRestAPIService.callLowTempExService();

Below is Sample Code. Do not use it for Production. Do not Hardcode any values in the Code. This is for Testing Purposes Only. 

#Class Code#:

public class CallLowTempExCalcRestAPIService {

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
    public static void callLowTempExService()
    {
        CallLowTempExCalcRestAPIService lowTempCalcService = new CallLowTempExCalcRestAPIService();
        String accessToken;
        accessToken = lowTempCalcService.ReturnAccessToken(); 

        if(accessToken != null) {
            String endPoint = 'https://msdlogin--hhusd4.my.salesforce.com/services/apexrest/msdcore/v1/MSD_CORE_LowTempExAssessmentService/';
            Http h2 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('Authorization','Bearer ' + accessToken);
            req1.setHeader('Content-Type','application/json');
            req1.setHeader('accept','application/json');
            String body = '{"brandNameProduct" : "GARDASIL 9","temperatureUnit" : "C","exposureDetails": [{"MSD_CORE_hours__c": 2,"MSD_CORE_Min__c": 3,"MSD_CORE_Seconds__c": 4,"MSD_CORE_Temp__c": 21}, {"MSD_CORE_hours__c": 5,"MSD_CORE_Min__c": 6,"MSD_CORE_Seconds__c": 7,"MSD_CORE_Temp__c": 32}]}';
                      
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
                System.debug('timeLimitNote  =' + o.get('timeLimitNote'));
                System.debug('supportIndicator  =' + o.get('supportIndicator'));
                System.debug('labelStorageCondition  =' + o.get('labelStorageCondition'));
                System.debug('notes  =' + o.get('notes'));
             }
        }
    }
}
*/