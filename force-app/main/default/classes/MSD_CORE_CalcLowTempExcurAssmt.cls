global with sharing class MSD_CORE_CalcLowTempExcurAssmt {

    @InvocableMethod
    public static List<Results> calculateLowTempExcursionAssessment(List<Requests> requests){

       EndUserLowTempExcursionAssessment endUserLowTempExcursionAssessment = new EndUserLowTempExcursionAssessment();
       MSD_CORE_AssessmentResultsDO assessmentResults = new MSD_CORE_AssessmentResultsDO();
      
       //Use the Brand Product name over the Generic one if the User Supplies both...
       String userProduct = '';
       String userGenericProduct = '';
       String userMarket = '';
        
        if(String.isNotBlank(requests[0].userMrkt)){
            userMarket = requests[0].userMrkt;
        }else{
            userMarket = 'US';
        } 
       
       if(String.isNotBlank(requests[0].userBrandNameProduct)){
          userProduct = requests[0].userBrandNameProduct;     
       }else if(String.isNotBlank(requests[0].userGenericNameProduct)) {
          userGenericProduct = requests[0].userGenericNameProduct; 
       }
        
        
      System.debug('KRB: In Invokable Low Temp Class: ');
      System.debug('KRB: userMarket: ' + userMarket);
      System.debug('KRB: userProduct: ' + userProduct);
      System.debug('KRB: userGenericProduct: ' + userGenericProduct);
      System.debug('KRB: requests[0].userUnitOfTemp: ' + requests[0].userUnitOfTemp);
      System.debug('KRB: Exposures: ');
        for(MSD_CORE_TempExcurExposDetail__c x : requests[0].exposureList){
                  System.debug('KRB: Exposure detail: ');
                  System.debug('KRB: hours: ' + x.MSD_CORE_hours__c);
                  System.debug('KRB: minutes: ' + x.MSD_CORE_Min__c);
                  System.debug('KRB: minutes: ' + x.MSD_CORE_Seconds__c);
        }  
      
        
      //New Access Method here...
      assessmentResults = 
          endUserLowTempExcursionAssessment.processLowTempExcursionAssessmentSeperateExposures(
                                               requests[0].exposureList,
                                               userMarket,
                                               userProduct,
       										   userGenericProduct, 
                                               requests[0].userUnitOfTemp);
        
      Results curResults = new Results();
      curResults.SupportIndicator =  assessmentResults.supportIndicator;
      curResults.labelStorageCondition = assessmentResults.labelStorageCondition;
      curResults.notes = assessmentResults.notes;
      curResults.timeLimitNote = assessmentResults.timeLimitNote;
        
      System.debug('KRB>>curResults.labelStorageCondition: ' + curResults.labelStorageCondition);
      System.debug('KRB>>curResults.SupportIndicator: ' + curResults.SupportIndicator);
          
      List<Results> resultsList = new List<results>();
      resultsList.add(curResults);
      return resultsList;

    }
    
/* Original Method of entry. Dont Delete! 
   
    public static List<Results> calculateLowTempExcursionAssessment(List<Requests> requests){
      
       
       EndUserLowTempExcursionAssessment endUserLowTempExcursionAssessment = new EndUserLowTempExcursionAssessment();
       MSD_CORE_AssessmentResultsDO assessmentResults = new MSD_CORE_AssessmentResultsDO ();
      
       //Use the Brand Product name over the Generic one if the User Supplies both...
       String userProduct = '';
       String userGenericProduct = '';
       
       if(String.isNotBlank(requests[0].userBrandNameProduct)){
          userProduct = requests[0].userBrandNameProduct;     
       }else if(String.isNotBlank(requests[0].userGenericNameProduct)) {
          userGenericProduct = requests[0].userGenericNameProduct; 
       }
           
       if (String.isBlank( requests[0].exposure2Concatenated)){
         requests[0].exposure2Concatenated = '0:0:0';  
       }
       if (String.isBlank( requests[0].exposure3Concatenated)){
         requests[0].exposure3Concatenated = '0:0:0';  
       }
        
        assessmentResults = 
          endUserLowTempExcursionAssessment.processLowTempExcursionAssessmentSeperateExposures(requests[0].exposure1Concatenated,
                                                                                                 requests[0].exposure2Concatenated,
                                                                                                 requests[0].exposure3Concatenated,
                                                                                                 requests[0].userMrkt,
                                                                                                 userProduct,
                                                                                                 userGenericProduct,
                                                                                                 requests[0].userUnitOfTemp);
      Results curResults = new Results();
      curResults.SupportIndicator =  assessmentResults.supportIndicator;
      curResults.labelStorageCondition = assessmentResults.labelStorageCondition;
                
      List<Results> resultsList = new List<results>();
      resultsList.add(curResults);
      return resultsList;
     
    }  
*/    
     
    global class Requests{
                
        @InvocableVariable
        global String userMrkt = '';
        
        @InvocableVariable
        global String userBrandNameProduct = '';

        @InvocableVariable
        global String userGenericNameProduct = '';
        
        @InvocableVariable
        global String userUnitOfTemp = '';
        
        //@InvocableVariable
        //global List<String> tempExcurExposDetailList;

        @InvocableVariable
        global List <MSD_CORE_TempExcurExposDetail__c> exposureList;
        
        /*
        @InvocableVariable
        global String exposure1Concatenated = '0:0:0';

        @InvocableVariable
        global String exposure2Concatenated = '0:0:0';
        
        @InvocableVariable
        global String exposure3Concatenated = '0:0:0';
        */
        
        
        //Use this to pass in a List of all the Exposure Details
        //@InvocableVariable
        //global List<MSD_CORE_TempExcurExposDetail__c> tempExcurExposDetailList;
                
    }
    
    global class Results{
        
        @InvocableVariable
        global String SupportIndicator = '';
        
        @InvocableVariable
        global String labelStorageCondition = '';

        @InvocableVariable
        global String notes = '';        

        @InvocableVariable
        global String timeLimitNote = '';        

    }
}