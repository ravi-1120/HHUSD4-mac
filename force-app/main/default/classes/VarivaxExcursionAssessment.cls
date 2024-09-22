public class VarivaxExcursionAssessment {

   /*  Kevin R. Brace - 20R3.0 Temperature Excursions - Varivax
                      - mimics the Calculations present in the Varivax Frozen Spreadsheet.
    
       23R2.0 - KRB 3/2023 - added support for 3 new fields: colder, warmer, unlimited.  

       Testing:

       MSD_CORE_AssessmentResultsDO ado = new MSD_CORE_AssessmentResultsDO();
       VarivaxExcursionAssessment vea = new VarivaxExcursionAssessment();
       ado = vea.processVarivaxAssessment(Date.newInstance(2020, 12, 1), 30, 0);
    
   */
    
    
   private Date todaysDate = Date.today();
   private Date expirationDate = Date.today();
   private Double timeRemainingInMonths = 0; //C10
   private Double temp9to25cOr47to77fExposureHrs = 0; //D12
   private Double temp10to8cOr14to46fExposureHrs = 0; //D13
   private Double potencyAfterImproperStorage = 0; //C15
   private String Outcome1 = ''; //C17, A21
   private String Outcome2 = ''; //C18, A26
   private Double OutcomeCompareTo8 = 8;
   private Double OutcomeCompareTo3150 = 3150;
   private Double OutcomeCompareTo3210 = 3210; 
   private Double OutcomeCompareTo3600 = 3600;
    
    /*
       Main Entry Point
    */
   public MSD_CORE_AssessmentResultsDO processVarivaxAssessment(Date expDate, 
                                                                Double userEnteredRmTmp9to25cOr47to77fExpHours,
                                                                Double userEnteredRmTmpGtrthnMinus10to8cOr14to46fExpHours,
                                                                Double colderHours,     //23R2.0
                                                                Double warmerHours,     //23R2.0
                                                                Double unlimitedHours){ //23R2.0

      MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();

      //23R2.0 KRB
      System.debug('23R2.0 VarivaxExcursionAssessment: colderHours: ' + colderHours);
      System.debug('23R2.0 VarivaxExcursionAssessment: warmerHours: ' + warmerHours);
      System.debug('23R2.0 VarivaxExcursionAssessment: unlimitedHours: ' + unlimitedHours);
                                                                    
      //23R2.0 KRB 3/2023                                                            
      //Prevalidation Rules
      if(
          (colderHours != null && colderHours > 0 ) || 
          (warmerHours != null && warmerHours > 0)      
      ){
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Cold or Warmer !null and > 0');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Cold or Warmer !null and > 0 evaluated to TRUE.');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Assigning Outcome and Exiting...');
          results.Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.';
          results.Outcome2 = 'IS NOT SUPPORTED BY STABILITY DATA';                                                                
          return results;
      } else {
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Cold or Warmer !null and > 0 evaluated to FALSE.');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Will continue with normal processing...');        
      }

      //if (colder and warmer = null or 0) AND  (refrig and room temp = 0) = Supported                                                              
      if(
          (colderHours == null || colderHours == 0) &&
          (warmerHours == null || warmerHours == 0) &&
          (userEnteredRmTmp9to25cOr47to77fExpHours == 0) &&
          (userEnteredRmTmpGtrthnMinus10to8cOr14to46fExpHours == 0) 
        ){
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Colder, warmer, roomtemp, refig all 0 Rule');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Colder, warmer, roomtemp, refig all 0 Rule evaluated to TRUE.');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Assigning Outcome and Exiting...');
          results.Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does support this specific temperature excursion.';
          results.Outcome2 = 'IS SUPPORTED BY STABILITY DATA';                                                                
          return results;
      } else {
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule evaluated to FALSE.');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Will continue with normal processing...');        
      }
                                                                                                                                       
      //if (colder and warmer = null or 0) AND  (refrig and room temp = 0) and Unlimited > 0 = Supported                                                              
      if(
          (colderHours == null || colderHours == 0) &&
          (warmerHours == null || warmerHours == 0) &&
          (userEnteredRmTmp9to25cOr47to77fExpHours == 0) &&
          (userEnteredRmTmpGtrthnMinus10to8cOr14to46fExpHours == 0) &&
          (unlimitedHours != null && unlimitedHours > 0)
        ){
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule evaluated to TRUE.');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Assigning Outcome and Exiting...');
          results.Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does support this specific temperature excursion.';
          results.Outcome2 = 'IS SUPPORTED BY STABILITY DATA';                                                                
          return results;
      } else {
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule evaluated to FALSE.');
          System.debug('23R2.0 VarivaxExcursionAssessment:Prevalidation Rules: Will continue with normal processing...');        
      }
      
      //End Prevalidation Rules
                                                              
                                                                                                                                        
      //Quick Exit if we don't have the correct values
      if(expDate == null ){
          System.debug('Required Information missing. Expiration Date. Exiting.');
          results.Outcome1 = 'Required Information missing. Expiration Date. Exiting.';
          results.Outcome2 = 'Required Information missing. Expiration Date. Exiting.';
          return results;
      }

      if((userEnteredRmTmp9to25cOr47to77fExpHours == null && userEnteredRmTmpGtrthnMinus10to8cOr14to46fExpHours == null)){
          System.debug('Required Information missing. Room Temp. Exiting.');
          results.Outcome1 = 'Required Information missing. Room Temp. Exiting.';
          results.Outcome2 = 'Required Information missing. Room Temp. Exiting.';
          return results;
          
      }
      if(expDate < todaysDate){
          System.debug('Expiration Date has to be greater than Today\'s Date. Exiting');                                                              
          results.Outcome1 = 'Expiration Date has to be greater than Today\'s Date. Exiting';
          results.Outcome2 = 'Expiration Date has to be greater than Today\'s Date. Exiting';
          return results;
                                                                        
      }
      if(userEnteredRmTmp9to25cOr47to77fExpHours < 0 || userEnteredRmTmpGtrthnMinus10to8cOr14to46fExpHours < 0){
          System.debug('Exposure Hours have to be >= 0. Exiting');                                                              
          results.Outcome1 = 'Exposure Hours have to be >= 0. Exiting';
          results.Outcome2 = 'Exposure Hours have to be >= 0. Exiting';
          return results;
      }                                                              
        
      expirationDate = expDate;
      temp9to25cOr47to77fExposureHrs = userEnteredRmTmp9to25cOr47to77fExpHours;
      temp10to8cOr14to46fExposureHrs = userEnteredRmTmpGtrthnMinus10to8cOr14to46fExpHours;                                                               
                                                                     
      performCalculations(); 
                                                                    
      results.Outcome1 = Outcome1;                                                             
      results.Outcome2 = Outcome2; 
                                                                    
      System.debug('Outcome1: ' + Outcome1);                                                             
      System.debug('Outcome2: ' + Outcome2);
      
      return results;
   }
    
    
    private void performCalculations(){
        TimeRemainingInMonths(); //C10
        PotencyAfterImproperStorage(); //C15
        ProcessOutcome1();
        ProcessOutcome2();
    }
    
    /*
       calculates Outcome 1

       Outcome_1 = =IF(C10<8,"Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.",
                IF(C15<3150,"Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.",
                    IF(C15<3210,"Immediately Freeze Product at +5F (-15C), Product Must be Used within 2 weeks",
                       IF(C15<3600,"Immediately Freeze Product at +5F (-15C), Product Must be Used within 1 month",
                           IF(C15>=3600,"Immediately Freeze Product at +5F (-15C), Product Must be Used within 3 months")))))

    */
    private void ProcessOutcome1(){
        if(timeRemainingInMonths < OutcomeCompareTo8){
           Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.';    
        }else if(potencyAfterImproperStorage < OutcomeCompareTo3150){
           Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.'; 
        }else if(potencyAfterImproperStorage < OutcomeCompareTo3210){
           Outcome1 = 'Immediately Freeze Product at +5F (-15C), Product Must be Used within 2 weeks.'; 
        }else if(potencyAfterImproperStorage < OutcomeCompareTo3600){
           Outcome1 = 'Immediately Freeze Product at +5F (-15C), Product Must be Used within 1 month.'; 
        }else if(potencyAfterImproperStorage >= OutcomeCompareTo3600){
           Outcome1 = 'Immediately Freeze Product at +5F (-15C), Product Must be Used within 3 months.'; 
        }
    }
    
/*
    private Double OutcomeCompareTo8 = 8;
   private Double OutcomeCompareTo3150 = 3150;
   private Double OutcomeCompareTo3210 = 3210; 
   private Double OutcomeCompareTo3600 = 3600;
   
  */  
    
    /*
       calculates Outcome 2

       Outcome_2 = =IF(C10<8,"IS NOT SUPPORTED BY STABILITY DATA",
                    	IF(C15<3150,"IS NOT SUPPORTED BY STABILITY DATA",
                    		IF(C15<3210,"Must be used within 2 weeks,",
                      			IF(C15<3600,"Must be used within 1 month,",
                        			IF(C15>=3600,"Must be used within 3 months,")))))

    */
    private void ProcessOutcome2(){
        if(timeRemainingInMonths < OutcomeCompareTo8){
           Outcome2 = 'IS NOT SUPPORTED BY STABILITY DATA';    
        }else if(potencyAfterImproperStorage < OutcomeCompareTo3150){
           Outcome2 = 'IS NOT SUPPORTED BY STABILITY DATA'; 
        }else if(potencyAfterImproperStorage < OutcomeCompareTo3210){
           Outcome2 = 'Must be used within 2 weeks'; 
        }else if(potencyAfterImproperStorage < OutcomeCompareTo3600){
           Outcome2 = 'Must be used within 1 month'; 
        }else if(potencyAfterImproperStorage >= OutcomeCompareTo3600){
           Outcome2 = 'Must be used within 3 months'; 
        }
    }
    
    
    
    /*
      Calculate the Potency After Improper Storage C15
      PEMDAS =  Parentheses, Exponents, Multiplication/Division, Addition/Subtraction
      

      =FLOOR(
              (4357/(1+0.015)^(24-C10))
                    /
              (1+0.005)^(CEILING(D12,1)+(CEILING(D13/24,1)+6))
          ,10
      ) 



      //Calc11
      =FLOOR(           //Calc3(Exp)
                   //Calc1    Calc2
            (4357/(1+0.015)^(24-C10))
               //Calc4
                         /    -> Calc10
                (1+0.005)^(CEILING(D12,1)+(CEILING(D13/24,1)+6))
                 //Calc5       //Calc6          //Calc7
                                       //Calc8 (+)
                       //Calc9(Exp)     
          ,10
          //Calc12
         ) 

    */
    
    private void PotencyAfterImproperStorage(){

        Double calc1 = 1 + 0.015;
        Double calc2 = 24 - timeRemainingInMonths;
        Double calc3 = Math.pow(calc1, calc2);
        Double calc4 = 4357 / calc3;
        Double calc5 = 1 + 0.005;
        Double calc6 = Math.ceil(temp9to25cOr47to77fExposureHrs); 
        Double calc7 = Math.ceil(temp10to8cOr14to46fExposureHrs/24) + 6; 
        Double calc8 = calc6 + calc7; 
        Double calc9 = Math.pow(calc5, calc8); 
        Double calc10 = calc4/calc9; 
        Double calc11 = Math.floor(calc10);
        Double calc12 = Math.round(calc11/10) * 10;
        
        System.debug('PotencyAfterImproperStorage:calc1: ' + calc1);
        System.debug('PotencyAfterImproperStorage:calc2: ' + calc2);
        System.debug('PotencyAfterImproperStorage:calc3: ' + calc3);
        System.debug('PotencyAfterImproperStorage:calc4: ' + calc4);
        System.debug('PotencyAfterImproperStorage:calc5: ' + calc5);
        System.debug('PotencyAfterImproperStorage:calc6: ' + calc6);
        System.debug('PotencyAfterImproperStorage:calc7: ' + calc7);
        System.debug('PotencyAfterImproperStorage:calc8: ' + calc8);
        System.debug('PotencyAfterImproperStorage:calc9: ' + calc9);
        System.debug('PotencyAfterImproperStorage:calc10: ' + calc10);
        System.debug('PotencyAfterImproperStorage:calc11: ' + calc11);
        System.debug('PotencyAfterImproperStorage:calc12: ' + calc12);
        
        potencyAfterImproperStorage = calc12;
        System.debug('potency After Improper Storage: (C15): ' + potencyAfterImproperStorage);
        
    }    
    
    /*
      Calculate the Time Remaining in Months C10
    */
    private void  TimeRemainingInMonths(){
      Integer numberOf360Days = MSDays360(todaysDate, expirationDate);
      System.debug('VarivaxExcursionAssessment: TimeRemainingInMonths: numberOf360Days: ' + numberOf360Days);
      Double numOfMonths = numberOf360Days/30;
      System.debug('VarivaxExcursionAssessment: TimeRemainingInMonths: numOfMonths: ' + numOfMonths);
      timeRemainingInMonths = Math.floor(numOfMonths);
      System.debug('VarivaxExcursionAssessment: TimeRemainingInMonths: timeRemainingInMonths(C10): ' + timeRemainingInMonths);
    }  
 
    
    /* 
      Calculates days between months using the MS DAYS360 method
      Date a = Start Date; Date b = End Date.
    */ 
    private Integer MSDays360(Date a, Date b){
       Integer dayA = a.day();
       Integer dayB = b.day();
      
       if(dayA == Date.daysInMonth(a.year(), a.month()) && dayB == Date.daysInMonth(b.year(), b.month()) ){
         dayB = Math.min(30, dayB);
       }else if (dayA == 30 && dayB ==31){
            dayB = 30;
       }
        
       if(dayA == Date.daysInMonth(a.year(), a.month())){
         dayA = 30; 
       }
        
       return dayB + b.month() * 30 + b.year() * 360 - dayA - a.month() * 30 - a.year() * 360;
 
     }

}


/*
Details in SS:

C15: potency after improper storage
 
   =FLOOR(
            (4357/(1+0.015)^(24-C10))
                    /
                (1+0.005)^(CEILING(D12,1)+(CEILING(D13/24,1)+6))
          ,10
         ) 
    

//Apex Power Math Method: public static Double pow(Double doubleValue, Double exponent)
   

Outcome_1 = =IF(C10<8,"Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.",
                IF(C15<3150,"Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.",
                    IF(C15<3210,"Immediately Freeze Product at +5F (-15C), Product Must be Used within 2 weeks",
                       IF(C15<3600,"Immediately Freeze Product at +5F (-15C), Product Must be Used within 1 month",
                           IF(C15>=3600,"Immediately Freeze Product at +5F (-15C), Product Must be Used within 3 months")))))

 

Outcome_2 = =IF(C10<8,"IS NOT SUPPORTED BY STABILITY DATA",
                IF(C15<3150,"IS NOT SUPPORTED BY STABILITY DATA",
                    IF(C15<3210,"Must be used within 2 weeks,",
                      IF(C15<3600,"Must be used within 1 month,",
                        IF(C15>=3600,"Must be used within 3 months,")))))

 

 

Enter expiration date

The following two prompts must contain an entry; if NA enter a 0.

Room Temperature (9 to 25°C or 47 to 77°F) Exposure:
Enter the number of hours, rounded up to the nearest whole hour, that the product was exposed to 9 to 25°C or 47 to 77°F

Refrigeration (> –10 to 8°C or 14 to 46°F) Exposure:
Enter the number of hours, rounded up to the nearest whole hour, that the product was exposed to > –10 to 8°C or 14 to 46°F
Subtract 72 hours from the refrigeration range to account for the time allowed by the label

Today's date is


Outcome

=Outcome_1

Extrapolation of in-house stability studies suggest that prior to reconstitution,

VARIVAX exposed to the unique conditions you described (RESTATE CONDITIONS)

=Outcome_2

------------------
Microsoft Floor:
------------------

Syntax
expression.Floor (Arg1, Arg2)

expression A variable that represents a WorksheetFunction object.

Parameters
TABLE 1
Name	Required/Optional	Data type	Description
Arg1	Required	Double	Number - the numeric value that you want to round.
Arg2	Required	Double	Significance - the multiple to which you want to round.



*/