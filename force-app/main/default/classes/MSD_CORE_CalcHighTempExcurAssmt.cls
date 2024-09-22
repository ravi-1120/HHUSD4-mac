global with sharing class MSD_CORE_CalcHighTempExcurAssmt {
   
    @InvocableMethod
    public static List<Results> calculateHighTempExcursionAssessment(List<Requests> requests){
      
       
       EndUserHighTempExcursionAssessment endUserHighTempExcursionAssessment = new EndUserHighTempExcursionAssessment();
       MSD_CORE_AssessmentResultsDO assessmentResults = new MSD_CORE_AssessmentResultsDO ();
      
       //Use the Brand Product name over the Generic one if the User Supplies both...
       String userProduct = '';
       String userGenericProduct = '';
       
       if(String.isNotBlank(requests[0].userBrandNameProduct)){
          userProduct = requests[0].userBrandNameProduct;     
       }

       if(String.isNotBlank(requests[0].userGenericNameProduct)) {
          userGenericProduct = requests[0].userGenericNameProduct; 
       }
        
       assessmentResults = 
          endUserHighTempExcursionAssessment.processHighTempExcursionAssessment(requests[0].exposureList,
                                                                                requests[0].userMrkt,
                                                                                userProduct,
                                                                                userGenericProduct,
                                                                                requests[0].userUnitOfTemp);
       Results curResults = new Results();
       curResults.SupportIndicator =  assessmentResults.supportIndicator;
       curResults.labelStorageCondition = assessmentResults.labelStorageCondition;
        
       if(String.isNotBlank(assessmentResults.HTFootNote)){
           curResults.Footnote = assessmentResults.HTFootNote;                                            
       }

       if(String.isNotBlank(assessmentResults.HTComment)){
           curResults.Comment = assessmentResults.HTComment;                                            
       }
                
       List<Results> resultsList = new List<results>();
       resultsList.add(curResults);
       return resultsList;
     
    }  
    
   
    global class Requests{
                
        @InvocableVariable
        global String userMrkt = '';
        
        @InvocableVariable
        global String userBrandNameProduct = '';

        @InvocableVariable
        global String userGenericNameProduct = '';
        
        @InvocableVariable
        global String userUnitOfTemp = '';
        
        @InvocableVariable
        global List<MSD_CORE_TempExcurExposDetail__c> exposureList;
                
    }
    
    
    global class Results{
        
        @InvocableVariable
        global String SupportIndicator = '';
        
        @InvocableVariable
        global String labelStorageCondition = '';
        
        @InvocableVariable
        global String Footnote = '';

        @InvocableVariable
        global String Comment = '';

    }
}