public class MSD_CORE_HighTempMetaDataDO {

   //Values Pulled from Object: 
   public String userProduct = ''; //from User Input, used to query data
   //For Step 3.2
   Public String HTM_timeAllowance = ''; //HTT AM$16 and ESHT Q28
   Public Double HTM_timeAllowanceC = 0; //HTT AN$16
   Public Double HTM_timeAllowanceF = 0; //HTT AO$16
   Public Double HTM_temp2MaxC = 0; //HTT AT$16 and ESHT_Q35
   Public Double HTM_temp2MaxF = 0; //HTT AU$16 and ESHT_Q36

   //For Step 3.3.a.1  
   Public Double HTM_labelMaxC = 0; //HTT C16
   Public Double HTM_labelMaxF = 0; //HTT D16

   //For Step 3.3.a.2 
   Public Double HTM_tempC = 0; //HTT AQ16
   Public Double HTM_tempF = 0; //HTT AR16

   //For Step 3.3.b 
   Public Double HTM_timeLimitDays = 0; //HHT AP16 ESHT_Q31
   //Public Double HTM_calTimeLimitDays = 0;
   
   //For Step 3.4.
   Public Double HTM_Temp2TimeHours = 0; //HTT AS16 and ESHT_Q34
    
   //For Step 4.0
   Public Double HTM_MarketMaxHours = 0; //HHT L16 and ESHT_Q19
    
   //For Step 7
   Public Double HTM_LabelMinC = 0; //HHT E16 ESHT_Q18
   Public Double HTM_LabelMinF = 0; //HHT F16 ESHT_Q18
    
   //For Step 8
   Public String HTM_FootNote = ''; //HHT J16 ESHT Q20
    
   //For Step 9
   Public String HTM_Comment = ''; //HHT AL16 ESHT Q21
    
       
   public void spoolData(){

      System.debug('-----------------------------------------');
      System.debug('userProduct: ' + userProduct);
      System.debug('HTM_timeAllowance (HTT AM$16) (ESHT Q28): ' + HTM_timeAllowance);
      System.debug('HTM_timeAllowanceC (HTT AN$16) (ESHT Q29): ' + HTM_timeAllowanceC);
      System.debug('HTM_timeAllowanceF (HTT AO$16) (ESHT Q30): ' + HTM_timeAllowanceF);
      System.debug('HTM_temp2MaxC (HTT AT$16) (ESHT Q35): ' + HTM_temp2MaxC);
      System.debug('HTM_temp2MaxF (HTT AU$16) (ESHT Q36): ' + HTM_temp2MaxF);
      System.debug('HTM_labelMaxC (HTT C16): ' + HTM_labelMaxC);
      System.debug('HTM_labelMaxF (HTT D16): ' + HTM_labelMaxF);
      System.debug('HTM_tempC (HTT AQ16) (ESHT Q32): ' + HTM_tempC);
      System.debug('HTM_tempF (HTT AR16  (ESHT Q33): ' + HTM_tempF);
      System.debug('HTM_timeLimitDays (HHT AP16) (ESHT Q31):' + HTM_timeLimitDays);
      System.debug('HTM_Temp2TimeHours (HTT AS16) (ESHT_Q34): ' + HTM_Temp2TimeHours);
      System.debug('HTM_LabelMinC (HHT E16) (ESHT_Q18): ' + HTM_LabelMinC);
      System.debug('HTM_LabelMinF (HHT F16) (ESHT_Q18): ' + HTM_LabelMinF);
      System.debug('HTM_FootNote (HHT J16) (ESHT Q20): ' + HTM_FootNote);
      System.debug('HTM_Comment (HHT AL16) (ESHT Q21): ' + HTM_Comment);
      System.debug('-----------------------------------------');

    }
}