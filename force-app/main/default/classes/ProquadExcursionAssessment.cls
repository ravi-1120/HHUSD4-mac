/*

   Kevin R. Brace 20R3.0 6/29/2020 
   Proquad Assessment - Mimics the Calculations of the ProQuad Assessment Excel Spreadsheet. 
   
   23R2.0 - KRB 3/2023 - added support for 3 new fields: colder, warmer, unlimited. 

   Testing:

   MSD_CORE_AssessmentResultsDO ado = new MSD_CORE_AssessmentResultsDO();
   ProquadExcursionAssessment pa = new ProquadExcursionAssessment();
   ado = pa.processProquadAssessment(Date.newInstance(2020, 9, 25), 45, 56);
   System.debug('outcome1: ' + ado.Outcome1);
   System.debug('outcome2: ' + ado.Outcome2);
*/  


public class ProquadExcursionAssessment {
    
   private Date todaysDate = Date.today();
   private Double P1 = 3.777759;
   private Double P2 = 0.217847;
   private Double K1_hours = 0.023726/730;
   private Double K2_hours = 7.653694/730;
   private Double Mumps_Loss_day_RT = 0.06712;
   private Double Mumps_Loss_month_m15C = 0.004608;
   private Double Measles_Loss_month_m15C = 0.004894;
   private Double RT_hours = 0;
   private Double Refrig_hrs = 0;
   private Double RT_Loss = 0; //C12
   private Date expirationDate;
   private Double potencyAfter2_8CExposure = 0; //C13
   private Double potencyBefore2_8CExposure = 0; //C14
   private Double two_8CLoss = 0; //C15
   private Double shelfLifeReductionInMonths = 0; //C17
   private Double usableShelfLifeInMonths = 0; //C24
   private Double shelfLifeRemainingInMonths = 0; //C25
   private String outcome1 = '';
   private String outcome2 = '';
   MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();


   /*
      Main Entry Point
   */
   public MSD_CORE_AssessmentResultsDO processProquadAssessment(Date expDate, 
                                                                Double userEnteredRoomTemperatureExposureHours,
                                                                Double userEnteredRefrigerationExposureHours,
                                                                Double colderHours,     //23R2.0
                                                                Double warmerHours,     //23R2.0
                                                                Double unlimitedHours){ //23R2.0

      //23R2.0
      System.debug('23R2.0 ProquadExcursionAssessment: colderHours: ' + colderHours);
      System.debug('23R2.0 ProquadExcursionAssessment: warmerHours: ' + warmerHours);
      System.debug('23R2.0 ProquadExcursionAssessment: unlimitedHours: ' + unlimitedHours);
   
      //23R2.0 KRB 3/2023                                                             
      //Prevalidation Rules
      if(
          (colderHours != null && colderHours > 0 ) || 
          (warmerHours != null && warmerHours > 0)
      ){
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Cold or Warmer !null and > 0');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Cold or Warmer !null and > 0 evaluated to TRUE.');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Assigning Outcome and Exiting...');
          results.Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.';
          results.Outcome2 = 'IS NOT SUPPORTED BY STABILITY DATA';                                                                
          return results;
      } else {
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Cold or Warmer !null and > 0 evaluated to FALSE.');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Will continue with normal processing...');        
      }

      //if (colder and warmer = null or 0) AND  (refrig and room temp = 0) = Supported                                                              
      if(
          (colderHours == null || colderHours == 0) &&
          (warmerHours == null || warmerHours == 0) &&
          (userEnteredRoomTemperatureExposureHours == 0) &&
          (userEnteredRefrigerationExposureHours == 0) 
        ){
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Colder, warmer, roomtemp, refig all 0 Rule');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Colder, warmer, roomtemp, refig all 0 Rule evaluated to TRUE.');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Assigning Outcome and Exiting...');
          results.Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does support this specific temperature excursion.';
          results.Outcome2 = 'IS SUPPORTED BY STABILITY DATA';                                                                
          return results;
      } else {
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule evaluated to FALSE.');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Will continue with normal processing...');        
      }
                                                                                                                                                                                                         
      //if (colder and warmer = null or 0) AND  (refrig and room temp = 0) and Unlimited > 0 = Supported                                                              
      if(
          (colderHours == null || colderHours == 0) &&
          (warmerHours == null || warmerHours == 0) &&
          (userEnteredRoomTemperatureExposureHours == 0) &&
          (userEnteredRefrigerationExposureHours == 0) &&
          (unlimitedHours != null && unlimitedHours > 0)
        ){
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule evaluated to TRUE.');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Assigning Outcome and Exiting...');
          results.Outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does support this specific temperature excursion.';
          results.Outcome2 = 'IS SUPPORTED BY STABILITY DATA';                                                                
          return results;
      } else {
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Unlimited > 0 Rule evaluated to FALSE.');
          System.debug('23R2.0 ProquadExcursionAssessment:Prevalidation Rules: Will continue with normal processing...');        
      }
      
      //End Prevalidation Rules
                                                                    
                                                                                                                                      
      if(expDate == null || expDate < todaysDate){
         System.debug('Expiration Date is invalid');
         results.Outcome1 = 'Expiration Date is invalid. Assessment can not be completed.'; 
         results.Outcome2 = 'Expiration Date is invalid. Assessment can not be completed.'; 
         return results;
      }else{
         expirationDate = expDate;
      } 
                                                                    
      if(userEnteredRoomTemperatureExposureHours < 0){
         System.debug('Room Temperature hours Value is invalid');
         results.Outcome1 = 'Room Temperature hours Value is invalid. Assessment can not be completed.'; 
         results.Outcome2 = 'Room Temperature hours Value is invalid. Assessment can not be completed.';                                                               
         return results;
      }else{
         RT_hours = userEnteredRoomTemperatureExposureHours;
      }
                                                                    
      if(userEnteredRefrigerationExposureHours < 0){
         System.debug('Refrigeration hours Value is invalid');
         results.Outcome1 = 'Refrigeration hours Value is invalid. Assessment can not be completed.'; 
         results.Outcome2 = 'Refrigeration hours Value is invalid. Assessment can not be completed.';                                                               
         return results;
      } else{
         Refrig_hrs = userEnteredRefrigerationExposureHours;
      }
                                                                    
      performCalculations();
                                                                    
      results.Outcome1 = outcome1;
      results.Outcome2 = outcome2;                                                              
                                                                    
      return results;                                                              
   }

    private void performCalculations(){
       spoolConstants();
       calculateRTLoss(); //C12
       calculatePotencyAfter2_8CExposure(); //C13
       calculatePotencyBefore2_8CExposure(); //C14
       calculate2_8CLoss(); //C15
       calculateShelfLifeReductionInMonths(); //C17
       calculateShelfLifeRemainingInMonths(); //C25
       calculateUsableShelfLifeInMonths(); //C24
       calculateOutcomes();
    }
    
    private void calculateOutcomes(){
        if(usableShelfLifeInMonths < 1){
            outcome1 = 'Based on the information provided regarding the length of time and temperature to which the vaccines were exposed, our stability data does not support this specific temperature excursion.';
            outcome2 = 'IS NOT SUPPORTED BY STABILITY DATA';
        } else if (usableShelfLifeInMonths < 2){
            outcome1 = 'Immediately Freeze Product at +5F (-15C), Product Must be Used within 2 weeks';
            outcome2 = 'Must be used  within 2 weeks';
        } else if (usableShelfLifeInMonths < 4){
            outcome1 = 'Immediately Freeze Product at +5F (-15C), Product Must be Used within 1 month';
            outcome2 = 'Must be used within 1 month';
        } else if (usableShelfLifeInMonths>=4){
            outcome1 = 'Immediately Freeze Product at +5F (-15C), Product Must be Used within 3 months';
            outcome2 = 'Must be used within 3 months.';
        }   
    }
    

    /*
       =FLOOR((DAYS360(D16,D10))/30,1)
    */
    private void calculateShelfLifeRemainingInMonths(){
      Integer numberOf360Days = MSDays360(todaysDate, expirationDate);
      System.debug('numberOf360Days: ' + numberOf360Days);
      Double numOfMonths = numberOf360Days/30;
      System.debug('numOfMonths: ' + numOfMonths);
      shelfLifeRemainingInMonths = Math.floor(numOfMonths);
      System.debug('shelfLifeRemainingInMonths C25: ' + shelfLifeRemainingInMonths);
        
    }
    
    /*
      =(C25-C17)
    */
    private void calculateUsableShelfLifeInMonths(){
       usableShelfLifeInMonths = shelfLifeRemainingInMonths - shelfLifeReductionInMonths;      
       System.debug('usableShelfLifeInMonths C24: ' + usableShelfLifeInMonths);
    }
    
    /*
      Shelf life Reduction (months) C17
      =((C12)/Mumps_Loss_month__15C)+(C15/Measles_Loss_month__15C)
    */
    private void calculateShelfLifeReductionInMonths(){
       shelfLifeReductionInMonths =  (RT_Loss/Mumps_Loss_month_m15C) + (two_8CLoss/Measles_Loss_month_m15C);  
       System.debug('shelfLifeReductionInMonths C17: ' + shelfLifeReductionInMonths);
    }
    
    
    private void spoolConstants(){
       System.debug('todaysDate: ' + todaysDate);
       System.debug('P1: ' + P1);
       System.debug('P2: ' + P2);
       System.debug('K1_hours: ' + K1_hours);
       System.debug('K2_hours: ' + K2_hours);
       System.debug('Mumps_Loss_day_RT: ' + Mumps_Loss_day_RT);
       System.debug('Mumps_Loss_month_m15C: ' + Mumps_Loss_month_m15C);
       System.debug('Measles_Loss_month_m15C: ' + Measles_Loss_month_m15C);
    }
    
    /* =(RT_hours*Mumps_Loss_day_RT/24) */
    private void calculateRTLoss(){ //C12
       RT_Loss = (RT_hours * Mumps_Loss_day_RT)/24;
       System.debug('RT_Loss C12: ' + RT_Loss);
    }
    
    /* Potency after 2-8C exposure  C13
       =(P_1*EXP((-K_1)*Refrig_hrs))+(P_2*EXP((-K_2)*Refrig_hrs)) 
    */
    private void calculatePotencyAfter2_8CExposure(){
       potencyAfter2_8CExposure = (P1 * Math.exp((- K1_hours) * Refrig_hrs)) + (P2 * Math.exp((- K2_hours) * Refrig_hrs));
       System.debug('potencyAfter2_8CExposure C13: ' + potencyAfter2_8CExposure);
    }


    /* Potency before 2-8C exposure //C14
       =(3.777759*EXP((-0.023726)*0))+(0.217847*EXP((-7.653694)*0))
    */
    private void calculatePotencyBefore2_8CExposure(){
       potencyBefore2_8CExposure = (3.777759 * Math.exp((-0.023726)*0)) + (0.217847 * Math.exp((-7.653694)*0));
       System.debug('potencyBefore2_8CExposure C14: ' + potencyBefore2_8CExposure);
    }
    
    
    /* 2-8C Loss //C15
       =CEILING((C14-C13),0.001)
    */
    private void calculate2_8CLoss(){
      two_8CLoss =  (Math.ceil((potencyBefore2_8CExposure - potencyAfter2_8CExposure) * 1000))/1000;
      System.debug('two_8CLoss C15: ' + two_8CLoss);
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