global with sharing class MSD_CORE_VarivaxTempExcurAssmt {

    @InvocableMethod
    public static List<Results> calculateVarivaxTempExcursionAssessment(List<Requests> requests){
      
       String assessmentProduct = 'Varivax';       
       VarivaxExcursionAssessment varivaxExcursionAssessment = new VarivaxExcursionAssessment();
       MSD_CORE_AssessmentResultsDO assessmentResults = new MSD_CORE_AssessmentResultsDO ();
      
       //Product has to be Varivax.  Confirm this. Exit if its not...
       String product = '';
       
       
       if(String.isNotBlank(requests[0].product) && requests[0].product.containsIgnoreCase(assessmentProduct)){
          product = requests[0].product;     
       }else{
          Results curResults = new Results();
          curResults.Outcome1 = 'Incorrect Product for Assessment. Assessment not Completed.';
          curResults.Outcome2 = 'Incorrect Product for Assessment. Assessment not Completed.';
                
          List<Results> resultsList = new List<results>();
          resultsList.add(curResults);
          return resultsList;
       }
        
        if(requests[0].expirationDate == null){
          Results curResults = new Results();
          curResults.Outcome1 = 'Expiration Date not supplied. Assessment not Completed.';
          curResults.Outcome2 = 'Expiration Date not supplied. Assessment not Completed.';
                
          List<Results> resultsList = new List<results>();
          resultsList.add(curResults);
          return resultsList;
                   
        }
        
        if(requests[0].rmTmp9_25Cor47_77FHours < 0 || requests[0].rmTmpm10_8Cor14_46FHours < 0){
          
          Results curResults = new Results();
          curResults.Outcome1 = 'Hours define have to be >= 0. Assessment not Completed.';
          curResults.Outcome2 = 'Hours define have to be >= 0. Assessment not Completed.';
                
          List<Results> resultsList = new List<results>();
          resultsList.add(curResults);
          return resultsList;
            
        }

        //KRB 23R3.0 preprocess Refrigeration Hours with the 72hr Subtraction Rule
        
        system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: Processing 72 Hour Logic...');
        system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: requests[0].rmTmpm10_8Cor14_46FHours value is:' + requests[0].rmTmpm10_8Cor14_46FHours);

       if((requests[0].rmTmpm10_8Cor14_46FHours - 72) < 0){
          system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: requests[0].rmTmpm10_8Cor14_46FHours - 72 IS < 0...');
          system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: assigning 0 to requests[0].rmTmpm10_8Cor14_46FHours value...');
          requests[0].rmTmpm10_8Cor14_46FHours = 0;  
          system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: New requests[0].rmTmpm10_8Cor14_46FHours value is: ' + requests[0].rmTmpm10_8Cor14_46FHours);
       }else{
          system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: requests[0].rmTmpm10_8Cor14_46FHours - 72 IS NOT < 0...');
          system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: subtracting 72 from the requests[0].rmTmpm10_8Cor14_46FHours...');
          requests[0].rmTmpm10_8Cor14_46FHours = requests[0].rmTmpm10_8Cor14_46FHours - 72;
          system.debug('23R3.0 MSD_CORE_VarivaxTempExcurAssmt: New requests[0].rmTmpm10_8Cor14_46FHours value is: ' + requests[0].rmTmpm10_8Cor14_46FHours);
       }
        
       assessmentResults = 
          varivaxExcursionAssessment.processVarivaxAssessment(requests[0].expirationDate,
                                                              requests[0].rmTmp9_25Cor47_77FHours,
                                                              requests[0].rmTmpm10_8Cor14_46FHours,
                                                              requests[0].colderHours,     //23R2.0 KRB
                                                              requests[0].warmerHours,     //23R2.0 KRB
                                                              requests[0].unlimitedHours); //23R2.0 KRB
        
       Results curResults = new Results();
       curResults.Outcome1 = assessmentResults.Outcome1;
       curResults.Outcome2 = assessmentResults.Outcome2;
                
       List<Results> resultsList = new List<results>();
       resultsList.add(curResults);
       return resultsList;
     
    }  
    
   
    global class Requests{
                
        @InvocableVariable
        global String product;
        
        @InvocableVariable
        global Date expirationDate;
        
        @InvocableVariable
        global Double rmTmp9_25Cor47_77FHours;

        @InvocableVariable
        global Double rmTmpm10_8Cor14_46FHours;
        
        @InvocableVariable
        global Double colderHours;  //23R2.0 KRB
        
        @InvocableVariable
        global Double warmerHours;  //23R2.0 KRB

        @InvocableVariable
        global Double unlimitedHours;  //23R2.0 KRB

    }
    
    
    global class Results{
        
        @InvocableVariable
        global String Outcome1 = '';
        
        @InvocableVariable
        global String Outcome2 = '';

    }
}