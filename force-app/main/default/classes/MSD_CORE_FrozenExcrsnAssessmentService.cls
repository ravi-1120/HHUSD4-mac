/* KRB 10/2021 - REST API Class containing Methods to interface with the 
 * 				Frozen Temp Excursion Calculator. 
 


   KRB 23R2.0 3/1/2023 - Added 3 additional optional fields to the JSON. Warmer, Colder and Unlimited
   KRB 23R4.0 8/18/2023 - Added 3 additional optional fields to the JSON: colderTemperatureExposureMinutes, warmerTemperatureExposureMinutes, unlimitedTemperatureExposureMinutes
                        - Added Minute Logic to the 3 new fields. 
   For Testing: 
   In Workbench: Goto REST Explorer and enter the following: 

   Execute POST to /services/apexrest/msdcore/v1/MSD_CORE_FrozenExcrsnAssessmentService/

   JSON Body of POST: Note: Same results on Stability for Proquad and Varivax, just change the Product field
   "Not Supported" result: for Proquad: Make date 5 days past current date for a 'Not Stable' Result:

   {  "product" : "Proquad",
      "expDateMonth" : 10,
      "expDateDay" : 20,
      "expDateYear": 2021,
      "roomTemperatureExposureHours": 10,
      "refrigerationExposureHours": 5
    }
    
    "Supported" result: for Proquad: Make date 2 months past current date for a 'Stable' Result:

    { "product" : "Proquad",
      "expDateMonth" : 12,
      "expDateDay" : 15,
      "expDateYear": 2022,
      "roomTemperatureExposureHours": 0,
      "refrigerationExposureHours": 1
    }

    Calling from a different Salesforce Org:

	1. Make sure to add 2 new Remote Site Records
		For Example, if calling from HHUSD3, make sure to add 
		each of these as a New Remote Site Record in HHUSD3: 
		https://test.salesforce.com
		https://msdlogin-hhusd4.my.salesforce.com

    2. Make sure the API User in the Environment where it was created has access to 
       this APEX Class in their Profile. 

	3. Create a Class to call the Service (see notes at bottom of Class for an example Class):
		In HHUSD3 test class is: CallFrozenTempExCalcRestAPIService

*/

@RestResource(urlMapping='/msdcore/v1/MSD_CORE_FrozenExcrsnAssessmentService/*')
global with sharing class MSD_CORE_FrozenExcrsnAssessmentService {

    @HttpPost
    global static String calculateFozenAssessment(String product,
                                                  Integer expDateMonth,
                                                  Integer expDateDay,
                                                  Integer expDateYear,  
                                                  Integer roomTemperatureExposureHours, //9 to 25 C or 47 to 77 F
                                                  Integer refrigerationExposureHours,   //-10 to 8 C or 14 to 46 F
                                                  Integer colder,      //23R2.0 KRB
                                                  Integer warmer,      //23R2.0 KRB
                                                  Integer unlimited,   //23R2.0 KRB
                                                  Integer roomTemperatureExposureMinutes, //23R3.0 KRB
                                                  Integer refrigerationExposureMinutes,    //23R3.0 KRB
                                                  Integer colderTemperatureExposureMinutes,   //23R4.0 KRB
                                                  Integer warmerTemperatureExposureMinutes,   //23R4.0 KRB
                                                  Integer unlimitedTemperatureExposureMinutes //23R4.0 KRB
                                                  ) { 
                                                           
        MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();

        System.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: Details from POST:' + 
                     ' product: ' + product +
                     ' expDateMonth:' + expDateMonth + 
                     ' expDateDay:' + expDateDay +
                     ' expDateYear:' + expDateYear +
                     ' roomTemperatureExposureHours:' + roomTemperatureExposureHours +
                     ' refrigerationExposureHours:' + refrigerationExposureHours + 
                     ' colder:' + colder +       //23R2.0 KRB
                     ' warmer:' + warmer +       //23R2.0 KRB
                     ' unlimited:' + unlimited + //23R2.0 KRB
                     ' roomTemperatureExposureMinutes:' + roomTemperatureExposureMinutes + //23R3.0 KRB
                     ' refrigerationExposureMinutes:' + refrigerationExposureMinutes +     //23R3.0 KRB
                     ' colderTemperatureExposureMinutes:' + colderTemperatureExposureMinutes +  //23R4.0 KRB
                     ' warmerTemperatureExposureMinutes:' + warmerTemperatureExposureMinutes +  //23R4.0 KRB
                     ' unlimitedTemperatureExposureMinutes:' + unlimitedTemperatureExposureMinutes   //23R4.0 KRB                
                    );


       //KRB 23R3.0                                              
       //default minutes fields if passed as null  
       if  (roomTemperatureExposureMinutes == null){
          roomTemperatureExposureMinutes = 0;
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: roomTemperatureExposureMinutes was null, defaulting to 0...');
           
       }else{
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: roomTemperatureExposureMinutes was not null, no defaulting required...');
       }  
                                                      
       if  (refrigerationExposureMinutes == null){
          refrigerationExposureMinutes = 0;  
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureMinutes was null, defaulting to 0...');
       }else{
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureMinutes was not null, no defaulting required...');
       }                                             
        
       //23R4.0 - Addition of 3 new Minutes Fields
       if (colderTemperatureExposureMinutes == null){
          colderTemperatureExposureMinutes = 0;  
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: colderTemperatureExposureMinutes was null, defaulting to 0...');
       }else{
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: colderTemperatureExposureMinutes was not null, no defaulting required...');
       }                                             

       if (warmerTemperatureExposureMinutes == null){
          warmerTemperatureExposureMinutes = 0;  
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: warmerTemperatureExposureMinutes was null, defaulting to 0...');
       }else{
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: warmerTemperatureExposureMinutes was not null, no defaulting required...');
       }                                             

       if (unlimitedTemperatureExposureMinutes == null){
          unlimitedTemperatureExposureMinutes = 0;  
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: unlimitedTemperatureExposureMinutes was null, defaulting to 0...');
       }else{
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: unlimitedTemperatureExposureMinutes was not null, no defaulting required...');
       }                                             

                                                      
       //23R3.0 Minute and 72 Hour Subtraction Logic 

       //23R3.0 Minute Logic first...
       system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: Processing Minute Logic...');

       if(roomTemperatureExposureMinutes > 0){
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: roomTemperatureExposureMinutes > 0 so adding 1 to the roomTemperatureExposureHours ...');
          roomTemperatureExposureHours = roomTemperatureExposureHours + 1;  
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: New roomTemperatureExposureHours value: ' + roomTemperatureExposureHours);         
       }else{
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: roomTemperatureExposureMinutes <= 0 so NOT adding 1 to the roomTemperatureExposureHours ...');
       }

       if(refrigerationExposureMinutes > 0){
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureMinutes > 0 so adding 1 to the refrigerationExposureHours ...');
          refrigerationExposureHours = refrigerationExposureHours + 1; 
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: New refrigerationExposureHours value: ' + refrigerationExposureHours);         
       }else{
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureMinutes <= 0 so NOT adding 1 to the refrigerationExposureHours ...');          
       }
                                                      
       //23R4.0 - Added logic for colderTemperatureExposureMinutes, warmerTemperatureExposureMinutes, unlimitedTemperatureExposureMinutes
       if(colderTemperatureExposureMinutes > 0){
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: colderTemperatureExposureMinutes > 0 so adding 1 to the colder value ...');
          
          if(colder == null){
             colder = 1; 
          }else{
             colder = colder + 1;  
          }
                     
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: New colder value: ' + colder);         
       }else{
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: colderTemperatureExposureMinutes <= 0 so NOT adding 1 to the colder value ...');          
       }
                                                      
       if(warmerTemperatureExposureMinutes > 0){
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: warmerTemperatureExposureMinutes > 0 so adding 1 to the warmer value ...');
           if(warmer == null){
              warmer = 1; 
           }else{
              warmer = warmer + 1;   
           }
         
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: New warmer value: ' + warmer);         
       }else{
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: warmerTemperatureExposureMinutes <= 0 so NOT adding 1 to the warmer value ...');          
       }

       if(unlimitedTemperatureExposureMinutes > 0){
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: unlimitedTemperatureExposureMinutes > 0 so adding 1 to the unlimited value ...');
          
          if(unlimited == null){
             unlimited = 1;  
          }else{
             unlimited = unlimited + 1; 
          }
           
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: New unlimited value: ' + unlimited);         
       }else{
          system.debug('23R4.0 MSD_CORE_FrozenExcrsnAssessmentService: unlimitedTemperatureExposureMinutes <= 0 so NOT adding 1 to the unlimited value ...');          
       }                                                                                                                                                          
                                                                                                          
       //23R3.0 72 Hour Subtraction Logic from refrigerationExposureHours 
       system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: Processing 72 Hour Logic...');
       system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureHours value is:' + refrigerationExposureHours );

       if((refrigerationExposureHours - 72) < 0){
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureHours - 72 IS < 0...');
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: assigning 0 to refrigerationExposureHours value...');
          refrigerationExposureHours = 0;                                                   
       }else{
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: refrigerationExposureHours - 72 IS NOT < 0...');
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: subtracting 72 from the refrigerationExposureHours...');
          refrigerationExposureHours = refrigerationExposureHours - 72;
          system.debug('23R3.0 MSD_CORE_FrozenExcrsnAssessmentService: New refrigerationExposureHours value is: ' + refrigerationExposureHours);
       }
                                                      
                                                      
        //Validate input - quick return if invalid 
        //Product has to be ProQuad or Varivax so fail if
        //product is blank OR Product <> either one..'Varivax' or 'Proquad'
        if( String.isBlank(product) || 
           (( product !='Varivax') && ( product != 'Proquad')) 
           ){
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        }
        
        //Date Validation: Fail if
        //  Month || day || year is null
        //	Month, day, year is an invalid date
        //	expDate < todaysDate
          
        Date expirationDate;
        Date todaysDate = Date.today();
        
        if (expDateMonth == null || expDateDay == null || expDateYear == null ){
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        }  

        if (expDateMonth < 1 || expDateMonth > 12 ){
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        }      
                                                                                                                
        try{
           expirationDate = Date.newInstance(expDateYear, expDateMonth, expDateDay);                                                   
        }catch(Exception ex){
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        }
        
        if(expirationDate < todaysDate){
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        }

        //roomTemperatureExposureHours and refrigerationExposureHours Validation: Fail if
        //  either value is not an Integer (enforced by JSON Parser)
        //  < 0
        //	either value is null                                             

        if(roomTemperatureExposureHours == null || refrigerationExposureHours == null 
           || roomTemperatureExposureHours < 0 || refrigerationExposureHours < 0 ){
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        }

        //23R2.0 KRB                                              
        if(colder == null ){
           System.debug('23R2.0: Colder was passed Null...');
        }        
        if(warmer == null ){
           System.debug('23R2.0: warmer was passed Null... ');
        } 
        if(unlimited == null ){
           System.debug('23R2.0: unlimited was passed Null... ');
        }        

                                                      
        if(product.equalsIgnoreCase('Proquad')){
           ProquadExcursionAssessment pa = new ProquadExcursionAssessment();
           //23R2.0 KRB - added colder and warmer parms
           results = pa.processProquadAssessment(expirationDate, roomTemperatureExposureHours, refrigerationExposureHours, colder, warmer, unlimited);
                                                   
           System.debug('MSD_CORE_FrozenExcrsnAssessmentService:FINAL RESULTS: Proquad: outcome1: ' + results.Outcome1);
           System.debug('MSD_CORE_FrozenExcrsnAssessmentService:FINAL RESULTS: Proquad: outcome2: ' + results.Outcome2);
                                                            
           return JSON.serialize(results); 
                                                          
        }else if(product.equalsIgnoreCase('Varivax')){
           VarivaxExcursionAssessment va = new VarivaxExcursionAssessment();
           //23R2.0 KRB - added colder and warmer parms
           results = va.processVarivaxAssessment(expirationDate, roomTemperatureExposureHours, refrigerationExposureHours, colder, warmer, unlimited);
                                                   
           System.debug('MSD_CORE_FrozenExcrsnAssessmentService:FINAL RESULTS: Varivax: outcome1: ' + results.Outcome1);
           System.debug('MSD_CORE_FrozenExcrsnAssessmentService:FINAL RESULTS: Varivax: outcome2: ' + results.Outcome2);
                                                            
           return JSON.serialize(results); 
            
        }else{
           results.Outcome1 = 'ERROR: Invalid Data Provided to REST API Service';
           return JSON.serialize(results);
        } 
                                                      
           
    }   
    
}


/*
 
//To run this Class:
1. Create a Class in the Calling Environment using the code below (See #Class Code# below), named CallFrozenTempExCalcRestAPIService
1. Copy and paste this line of code in the Anonymous Window in the Developer Debug Window and run it with Logging Turned on:
	
 	CallFrozenTempExCalcRestAPIService.callFrozenTempExService();

Below is Sample Code. Do not use it for Production. Do not Hardcode any values in the Code. This is for Testing Purposes Only. 
End Point values defined in the Code for the Access Token and Service will need to be updated to reflect 
Production Values when migrated. 

#Class Code#:

public class CallFrozenTempExCalcRestAPIService {

    private final String clientId = '<Enter MSD_CORE_TempEx_Calculator_Service Connected App Id>';
    private final String clientSecret = '<Enter MSD_CORE_TempEx_Calculator_Service Connected App Secret Key>';
    private final String username = '<Enter gmsa_portal user Name>';
      
    //Note For the Below Variable:
    //If testing against a Sandbox Org (ie, HHUSF1 or HHUSF2), make sure the following is done for the Password:
    //1. For the gmsa_portal Users Profile, "MSD_CORE GMSA Portal Integration", 
    //   make sure that the Login IP Ranges are blank. 
    //2. Log in as the gmsa_portal User in the Sandbox and request a Security Token via the User Settings.
    //   Security Token is sent to the email address associated to the gmsa_portal User's Record. 
    //3. Add this Security Token to the Password: "gmsa_portal User + Security Token"
    //Dev Boxes are configured differently and therefore this added step is not required.
	//A Security Token WILL be required for Production. 

    private final String password = '<Enter gmsa_portal user's Password>';

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
    public static void callFrozenTempExService()
    {
        CallFrozenTempExCalcRestAPIService frozenTempCalcService = new CallFrozenTempExCalcRestAPIService();
        String accessToken;
        accessToken = frozenTempCalcService.ReturnAccessToken(); 

        if(accessToken != null) {
            
            //UAT Sandbox: HHUSF1
            //String endPoint = 'https://msdlogin--hhusf1.my.salesforce.com/services/apexrest/msdcore/v1/MSD_CORE_FrozenExcrsnAssessmentService/';
            
            //Dev Org HHUSD4
            String endPoint = 'https://msdlogin--hhusd4.my.salesforce.com/services/apexrest/msdcore/v1/MSD_CORE_FrozenExcrsnAssessmentService/';
            Http h2 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('Authorization','Bearer ' + accessToken);
            req1.setHeader('Content-Type','application/json');
            req1.setHeader('accept','application/json');

            //NOTE: In the JSON Body, the Expire Date has to be greater than today's Data!
            //For a "Not Supported" result: for Proquad/Varivax: Make date 5 days past current date for a 'Not Stable' Result.
            //For a "Supported" result: for Proquad/Varivax: Make date 2 months past current date for a Stable Result.

            //Proquad Not Supported Result
            //String body = '{"product" : "Proquad","expDateMonth" : 10,"expDateDay" : 12,"expDateYear": 2021,"roomTemperatureExposureHours": 10,"refrigerationExposureHours": 5}';
            //Proquad Supported Result
            String body = '{"product" : "Proquad","expDateMonth" : 12,"expDateDay" : 10,"expDateYear": 2022,"roomTemperatureExposureHours": 0,"refrigerationExposureHours": 1}';

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
                System.debug('Outcome1  =' + o.get('Outcome1'));
                System.debug('Outcome2  =' + o.get('Outcome2'));
             }
        }
    }
}
*/