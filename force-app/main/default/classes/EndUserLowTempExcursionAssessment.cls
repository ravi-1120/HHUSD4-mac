/*
 * KRB 5/29/2020 - 20R3.0 Conversion of Assessment Excel Spreadsheet to Lightning Flow
 * 
 * This class mimics the Calculations performed in the "Entry Sheet Low Temp" Excel
 * Spreadsheet found in the "End_User_Temp_Excursion_Assessment_v1.2.xlsm Rev.19"
 * 
 * The Calculations in this Class are for LOW TEMP EXCURSIONS ONLY!
 * 
 * pseudocode for the spreadsheet that was used to generate this class appears at the 
 * bottom of this class. 
 * 
 * Descriptions of Classes used in this Class:
 * 1. MSD_CORE_LowTempMetaDataDO - Stores all the metaData for the Product the Assessment is being done for. 
 *	  TODO: above class needs to be populated from Database….
 * 
 * Change Log: 22R3.1 8/2022 KRB -  Made the following Changes:
 * 
 * 									-Validate that userSuppliedMrkt is not Blank
 * 									-Removed all "US" Defaulting Market Logic 
 * 									-Updated numerous Debug Statements
 * 
 * 
 * Testing this Class in isolation:

    List <MSD_CORE_TempExcurExposDetail__c> details = new List <MSD_CORE_TempExcurExposDetail__c>();
		MSD_CORE_TempExcurExposDetail__c detail = new MSD_CORE_TempExcurExposDetail__c();
		detail.MSD_CORE_hours__c = 20;
		detail.MSD_CORE_Min__c = 20;
		detail.MSD_CORE_Seconds__c = 55;
		detail.MSD_CORE_Temp__c = 22;
		details.add(detail);

		MSD_CORE_TempExcurExposDetail__c detail1 = new MSD_CORE_TempExcurExposDetail__c();
		detail1.MSD_CORE_hours__c = 2;
		detail1.MSD_CORE_Min__c = 30;
		detail1.MSD_CORE_Seconds__c = 15;
		detail1.MSD_CORE_Temp__c = 22;
		details.add(detail1);

	String userSuppliedMrkt = 'US';
	String userSuppliedBrandNameProduct = 'INTEGRILIN';
	String userSuppliedUnitOfTemp = 'C';
	String userSuppliedGenericNameProduct = '';

	EndUserLowTempExcursionAssessment x = new EndUserLowTempExcursionAssessment();
 	x.processLowTempExcursionAssessmentSeperateExposures(details, 
                                                         userSuppliedMrkt,
                                                         userSuppliedBrandNameProduct,
       										             userSuppliedGenericNameProduct, 
                                                         userSuppliedUnitOfTemp);


 */

public class EndUserLowTempExcursionAssessment {
   
   //Stores the Low Temp MetaData for given Product 
   MSD_CORE_LowTempMetaDataDO lowTempMetaDataDO = new MSD_CORE_LowTempMetaDataDO(); 

   //Stores the Original (unmodified) User Entered Exposure Detail.  - leave it unmodified in the Code! 
   List <MSD_CORE_TempExcurExposDetail__c> userExposureDetailsEntered = new List <MSD_CORE_TempExcurExposDetail__c>();
   
   //Stores Metadata on Product
   List <MSD_CORE_ProdAsmntMetadata__c> prodMetadataList = new List <MSD_CORE_ProdAsmntMetadata__c>();

    
   //Stores User Input
   String userMrkt = '';
   String userProduct = '';
   String userGenericProduct = '';

   String userUnitOfTemp = '';
    
   //CONSTANTS 
   //These fields were prepopulated with Data in the Excel Spreadsheet. 
   Double ESLT_C_LOWER = -1; //R32
   Double ESLT_F_LOWER = 30.2; //R34
   Double ESLT_C_UPPER = 0; //R33
   Double ESLT_F_UPPER = 32; //R35
    
   //Entry Sheet Low Temp (ESLT)
   String ESLT_Evaluation_Temp = ''; //O20
   String ESLT_Min_Temp_Limit = ''; //R15 
   Double ESLT_Temp_R_Limit_Lower = 0; //R30
   Double ESLT_Temp_R_Upper_Lower = 0; //R31
   Double ESLT_Min_Temp = 0; //O15
   Double ESHT_TimeTotals = 0; //L15
   String ESLT_Max_Temp_Limit = ''; //R14 $R$14
   String ESLT_Evaluation_Time = ''; //O21
   String ESLT_Total_Hours_Allowed = ''; //R16
   String ESLT_Cycles = ''; //R17
   Double ESLT_Normalized_For_Cycles = 0; //K15
   String ESLT_Evaluation_Cycles = ''; //O22

   //Storage Label Variables
   String ESLT_Min_C_Storage = ''; //R19 ='Low Temp Table'!G1 - Labeled Temp Range Min C
   String ESLT_Max_C_Storage = ''; //R18 ='Low Temp Table'!I1 - Labeled Temp Range Max C
   String ESLT_Min_F_Storage = ''; //R21 ='Low Temp Table'!H1 - Labeled Temp Range Min F
   String ESLT_Max_F_Storage = ''; //R20 ='Low Temp Table'!J1 - Labeled Temp Range Max F
   String ESLT_Max_C_Storage_2 = ''; //R22='Low Temp Table'!Q1 - Second Label Range Temp Max C
   String ESLT_Min_C_Storage_2 = ''; //R23='Low Temp Table'!O1 - Second Label Range Temp Min C
   String ESLT_Min_F_Storage_2 = ''; //R25 ='Low Temp Table'!P1 - Second Label Range Temp Min F
   String ESLT_Max_F_Storage_2 = ''; //R24 ='Low Temp Table'!R1 - Second Label Range Temp Max F
   String ESLT_Label_Storage_Condition = ''; //C11

   //Assessment Result:
   String ESLT_Assessment_Result = ''; //D8
   String ESLT_Notes = ''; //R26
   String ESLT_Time_Limit_Note = ''; //B13
       
       //B13: =IF(OR(R27="No",R27=""),"","Note: This product does not have a time limit") 
    
   List <MSD_CORE_CalcLowTempExcurExDetls> calculatedUserExposureDetailsEnteredList = new List <MSD_CORE_CalcLowTempExcurExDetls>();

    
    
    //New Entry Method coded on 6/16  
    public MSD_CORE_AssessmentResultsDO processLowTempExcursionAssessmentSeperateExposures(
                                               List <MSD_CORE_TempExcurExposDetail__c> exposureList, 
                                               String userSuppliedMrkt,
                                               String userSuppliedBrandNameProduct,
       										   String userSuppliedGenericNameProduct, 
                                               String userSuppliedUnitOfTemp){
                                                   
      System.debug('EULTEA: In EndUserLowTempExcursionAssessment Class: ');
      System.debug('EULTEA: userSuppliedMrkt: ' + userSuppliedMrkt);
      System.debug('EULTEA: userSuppliedBrandNameProduct: ' + userSuppliedBrandNameProduct);
      System.debug('EULTEA: userSuppliedGenericNameProduct: ' + userSuppliedGenericNameProduct);
      System.debug('EULTEA: userSuppliedUnitOfTemp: ' + userSuppliedUnitOfTemp);
      System.debug('EULTEA: Exposures: ');
      
      for(MSD_CORE_TempExcurExposDetail__c x : exposureList){
         System.debug('EULTEA: Exposure detail: ');
         System.debug('EULTEA: hours: ' + x.MSD_CORE_hours__c);
         System.debug('EULTEA: minutes: ' + x.MSD_CORE_Min__c);
         System.debug('EULTEA: seconds: ' + x.MSD_CORE_Seconds__c);
         System.debug('EULTEA: temp: ' + x.MSD_CORE_Temp__c);
        }  

      
      MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();
                                                   
      //Quick Exit if we dont have all the required information:
      if((String.isBlank(userSuppliedUnitOfTemp)) ||
         (String.isBlank(userSuppliedBrandNameProduct)) ||
         (String.isBlank(userSuppliedMrkt)) // 22R3.1 Add
        ){
           results.supportIndicator = 'Missing Necessary information. Calculation could not be Completed. Product/Temp/Market';
           System.debug('Missing Necessary information. Calculation could not be Completed.');
           System.debug('userSuppliedBrandNameProduct: ' + userSuppliedBrandNameProduct );
           System.debug('userSuppliedUnitOfTemp: ' + userSuppliedUnitOfTemp );
           System.debug('userSuppliedMrkt: ' + userSuppliedMrkt ); // 22R3.1 Add
           return results;
      }
       /*                                            
       if(userSuppliedUnitOfTemp != 'C' || userSuppliedUnitOfTemp != 'F'){
           results.supportIndicator = 'Missing Necessary information: Temp has to be C or F.';
           System.debug('Missing Necessary information: Temp has to be C or F.');
           System.debug('userSuppliedUnitOfTemp: ' + userSuppliedUnitOfTemp );
           return results;
       }
       */                                            
    
      if(exposureList.isEmpty()){
           results.supportIndicator = 'Missing Necessary information for Calculation. Missing Exposure Information. ';
           System.debug('Missing Necessary information. Missing Exposure Information..');
           return results;
      }
       
      //Process Exposure Information from User
      for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){

          MSD_CORE_TempExcurExposDetail__c exp = new MSD_CORE_TempExcurExposDetail__c();
           exp.MSD_CORE_hours__c = exposure.MSD_CORE_hours__c;
           exp.MSD_CORE_Min__c = exposure.MSD_CORE_Min__c;
           exp.MSD_CORE_Temp__c = exposure.MSD_CORE_Temp__c;
           exp.MSD_CORE_Seconds__c = exposure.MSD_CORE_Seconds__c;
           userExposureDetailsEntered.add(exp);
      }
                                                   
      /* Removed for 22R3.1
      if(String.isBlank(userSuppliedMrkt)){
        userMrkt = 'US';                                               
      }else{
        userMrkt = userSuppliedMrkt; 
      }
      */   

      //Add 22R3.1                                            
      userMrkt = userSuppliedMrkt;
      
      userUnitOfTemp = userSuppliedUnitOfTemp;
     
      if(String.isNotBlank(userSuppliedBrandNameProduct) && userSuppliedBrandNameProduct != 'NA'){
        userProduct = userSuppliedBrandNameProduct;
      }
                
      if(String.isNotBlank(userSuppliedGenericNameProduct) && userSuppliedGenericNameProduct != 'NA'){
         userGenericProduct = userSuppliedGenericNameProduct;
      }
                                              
      // Dont want to mess with the User Temp/Time Exposure details that the User Entered.
      // Store user Exposure input in seperate Object to perform calculations that we dont want to store
      // Use the calculatedUserExposureDetailsEnteredList List of Objects to do all calculations...
      for(MSD_CORE_TempExcurExposDetail__c x: userExposureDetailsEntered){
         MSD_CORE_CalcLowTempExcurExDetls cuede = new MSD_CORE_CalcLowTempExcurExDetls();
         cuede.hours = x.MSD_CORE_hours__c;
         cuede.min = x.MSD_CORE_Min__c;
         cuede.seconds = x.MSD_CORE_Seconds__c;
         cuede.temp = x.MSD_CORE_Temp__c;
         calculatedUserExposureDetailsEnteredList.add(cuede); 
      }

      System.debug('EULTEA: getLowTempMetaDataforProduct');
	  System.debug('EULTEA: userProduct' + userProduct); 
	  System.debug('EULTEA: userGenericProduct' + userGenericProduct); 
	  System.debug('EULTEA: userSuppliedMrkt' + userSuppliedMrkt);
                                                   
      //Load up the Product MetaData                                            
      getLowTempMetaDataforProduct(userProduct, userGenericProduct, userSuppliedMrkt);
		System.debug('EULTEA: 1');
    
      //If there is no Metadata for the Product, Quick Exit.                                             
      if(prodMetadataList.isEmpty()){
		 System.debug('EULTEA: 2');
         System.debug('Could not find Product Metadata. exiting.');
              
         results.supportIndicator = 'No Metadata found for given Product';
         results.labelStorageCondition = 'No Metadata found for given Product';
         return results;
                    
      }else{
         System.debug('EULTEA: Entering performCalculations()');
         performCalculations();  
      }
      
      System.debug('ESLT_Label_Storage_Condition before Results assignment: ' + ESLT_Label_Storage_Condition);                                       
      results.supportIndicator = ESLT_Assessment_Result;
      results.labelStorageCondition = ESLT_Label_Storage_Condition;
      results.notes = ESLT_Notes;
      results.timeLimitNote = ESLT_Time_Limit_Note;    
                                             
      return results;                                         
                                                   
   } 
        
    
    //***********************************
    //Main Entry Method for Calculations
    //***********************************
    private void performCalculations(){
       calculateEvaluationTemp(); //O20 Evaluation "Temp"
       System.debug('EULTEA 3');
       calculateEvaluationTime(); //O21 Evaluation "Time"
       System.debug('EULTEA 4');
       calculateEvaluationCycles(); //O22 Evaluation "Cycles"
       System.debug('EULTEA 5');
       calculateStorageLabel(); //C11 Storage Label
       System.debug('EULTEA 6');
       calculateAssessmentResult(); //D8
       System.debug('EULTEA 7');
       calculateTimeLimitNote(); //B13
       System.debug('EULTEA 8');
    }
    
    //Utility Method to determine if the String Supplied is a real String or a Number...
    private boolean thisStringIsANumber(String aString){
        
        boolean isNumber = false;
        
        try{
           Double aNum = Double.valueOf(aString) ; 
           isNumber = true;
        }catch(Exception ex){
           system.debug('Could not translate. its a string!');
        }
        
        return isNumber;
        
    }
    
  
    private void calculateTimeLimitNote(){
       //String ESLT_Time_Limit_Note = ''; //B13
       //B13: =IF(OR(R27="No",R27=""),"","Note: This product does not have a time limit") 

       if(String.isBlank(lowTempMetaDataDO.LTT_UnlimitedTime) || lowTempMetaDataDO.LTT_UnlimitedTime.equalsIgnoreCase('no')){
          ESLT_Time_Limit_Note = '';       
       }else{
          ESLT_Time_Limit_Note = 'Note: This product does not have a time limit'; 
       } 
    
       system.debug('ESLT_Time_Limit_Note (B13): ' + ESLT_Time_Limit_Note);
    }
    
    
    private void calculateAssessmentResult(){
       //   String ESLT_Assessment_Result = ''; //D8
       ESLT_Notes = lowTempMetaDataDO.LTT_Comment;
       String tempAssessmentString = '';
        
       if(ESLT_Evaluation_Temp =='FAIL' || 
          ESLT_Evaluation_Time == 'FAIL' || 
          ESLT_Evaluation_Cycles =='FAIL'){

          tempAssessmentString = 'Stability Data does not Support Continued Use';  
               
       }else{
         tempAssessmentString = 'Stability Data Supports Continued use';  
       }

       
       if(String.isNotBlank(ESLT_Notes)){
          ESLT_Assessment_Result = ESLT_Notes + ' ' + tempAssessmentString;
       } else{
          ESLT_Assessment_Result = tempAssessmentString;
       }
    
    system.debug('FINAL Assessment ESLT_Assessment_Result (D8): '+ ESLT_Assessment_Result);
    }  
        
      
    private void calculateStorageLabel(){
    /*
     C11: "Storage Label" : = 

   		//Storage Label Variables
   		String ESLT_Min_C_Storage = ''; //R19 ='Low Temp Table'!G1 - Labeled Temp Range Min C
   		String ESLT_Max_C_Storage = ''; //R18 ='Low Temp Table'!I1 - Labeled Temp Range Max C
   		String ESLT_Min_F_Storage = ''; //R21 ='Low Temp Table'!H1 - Labeled Temp Range Min F
   		String ESLT_Max_F_Storage = ''; //R20 ='Low Temp Table'!J1 - Labeled Temp Range Max F
   		String ESLT_Max_C_Storage_2 = ''; //R22='Low Temp Table'!Q1 - Second Label Range Temp Max C
   		String ESLT_Min_C_Storage_2 = ''; //R23='Low Temp Table'!O1 - Second Label Range Temp Min C
   		String ESLT_Min_F_Storage_2 = ''; //R25 ='Low Temp Table'!P1 - Second Label Range Temp Min F
   		String ESLT_Max_F_Storage_2 = ''; //R24 ='Low Temp Table'!R1 - Second Label Range Temp Max F
     */
       ESLT_Min_C_Storage = lowTempMetaDataDO.LTT_LabeledTempRangeMinC;
       ESLT_Max_C_Storage = lowTempMetaDataDO.LTT_LabeledTempRangeMaxC;
       ESLT_Min_F_Storage = lowTempMetaDataDO.LTT_LabeledTempRangeMinF; 
       ESLT_Max_F_Storage = lowTempMetaDataDO.LTT_LabeledTempRangeMaxF; 
       ESLT_Max_C_Storage_2 = lowTempMetaDataDO.LTT_SecondLabelRangeTempMaxC;
	   ESLT_Min_C_Storage_2 = lowTempMetaDataDO.LTT_SecondLabelRangeTempMinC;     
       ESLT_Min_F_Storage_2 = lowTempMetaDataDO.LTT_SecondLabelRangeTempMinF;
       ESLT_Max_F_Storage_2 = lowTempMetaDataDO.LTT_SecondLabelRangeTempMaxF; 
       
       System.debug('***********************************************************');
       System.debug('calculateStorageLabel() - START ***************************');
       System.debug('ESLT_Min_C_Storage: (R19): ' + ESLT_Min_C_Storage);
       System.debug('ESLT_Max_C_Storage: (R18): ' + ESLT_Max_C_Storage);
       System.debug('ESLT_Min_F_Storage: (R21): ' + ESLT_Min_F_Storage);
       System.debug('ESLT_Max_F_Storage: (R20): ' + ESLT_Max_F_Storage);
       System.debug('ESLT_Max_C_Storage_2: (R22): ' + ESLT_Max_C_Storage_2);
       System.debug('ESLT_Min_C_Storage_2: (R23): ' + ESLT_Min_C_Storage_2);
       System.debug('ESLT_Min_F_Storage_2: (R25): ' + ESLT_Min_F_Storage_2);
       System.debug('ESLT_Max_F_Storage_2: (R24): ' + ESLT_Max_F_Storage_2);
 /*
       In the Apex Code, we only care about this portion of the Condition (Product is required User Input!):

			IF(
				C9="C",
				R19&"C to "&R18&"C",
				R21&"F to "&R20&"F"
			)
			&
			IF(
				R22<>"N/A",
				" and "& IF(
							C9="C",
							R23&"C to "&R22&"C",
							R25&"F to "&R24&"F"
							)
				,""
			)
        
 */       
        
        if(userUnitOfTemp == 'C'){
            ESLT_Label_Storage_Condition = ESLT_Min_C_Storage + 'C to ' + ESLT_Max_C_Storage + 'C';
            
            if(ESLT_Max_C_Storage_2 != 'N/A'){
               ESLT_Label_Storage_Condition = ESLT_Label_Storage_Condition + ' and ' + ESLT_Min_C_Storage_2 + 'C to ' + ESLT_Max_C_Storage_2 + 'C';
            }
            
        }else if(userUnitOfTemp == 'F'){
            ESLT_Label_Storage_Condition = ESLT_Min_F_Storage + 'F to ' + ESLT_Max_F_Storage + 'F';
            
            if(ESLT_Max_C_Storage_2 != 'N/A'){
               ESLT_Label_Storage_Condition = ESLT_Label_Storage_Condition + ' and ' + ESLT_Min_F_Storage_2 + 'F to ' + ESLT_Max_F_Storage_2 + 'F';
            }

        }
            
        System.debug('ESLT_Label_Storage_Condition (C11): ' + ESLT_Label_Storage_Condition);
        System.debug('***********************************************************');
           
    }
    
    //O20 Evaluation "Temp" - ESLT_Evaluation_Temp
    //O20: (Evaluation: "Temp") - =IF(R15="","",IF(O15<R15,"FAIL",""))
    //IF(ESLT_Min_Temp < ESLT_Min_Temp_Limit,"FAIL","")
    //Note: In an Excel Spreadsheet, a Number (positive or Negative) will ALWAYS be LESS than a Text Value. 

    private void calculateEvaluationTemp(){
        System.debug('EULTEA 11');
       calculateMinTempLimit(); //R15 - Result is a String (Number or Text)  - String ESLT_Min_Temp_Limit = ''; //R15 
       calculateMinTemp(); //O15 - Result is a Double    - Double ESLT_Min_Temp = 0; //O15 

       ESLT_Evaluation_Temp = '';
       system.debug('ESLT_Min_Temp_Limit value: ' + ESLT_Min_Temp_Limit);
        
       if(String.isBlank(ESLT_Min_Temp_Limit)){
            system.debug('String.isBlank(ESLT_Min_Temp_Limit) was TRUE, so ESLT_Evaluation_Temp = blank ');
            ESLT_Evaluation_Temp = '';
        }else{
            if(! thisStringIsANumber(ESLT_Min_Temp_Limit)){
               ESLT_Evaluation_Temp = 'FAIL'; 
               system.debug('ESLT_Min_Temp_Limit is NOT a Number, so ESLT_Evaluation_Temp = FAIL ');

            }else{
                if(thisStringIsANumber(ESLT_Min_Temp_Limit)){
                    system.debug('ESLT_Min_Temp_Limit Is a Number, so doing calculation... ');
                    system.debug('ESLT_Min_Temp: ' + ESLT_Min_Temp);
                    system.debug('Double.valueOf(ESLT_Min_Temp_Limit): ' + Double.valueOf(ESLT_Min_Temp_Limit));

                    if(ESLT_Min_Temp < Double.valueOf(ESLT_Min_Temp_Limit)){
                        ESLT_Evaluation_Temp = 'FAIL'; 
                        system.debug('ESLT_Min_Temp < Double.valueOf(ESLT_Min_Temp_Limit) so ESLT_Evaluation_Temp = FAIL ');
                    }else{
                        system.debug('ESLT_Min_Temp > Double.valueOf(ESLT_Min_Temp_Limit) so ESLT_Evaluation_Temp = blank ');
                    }
                }else{
                    system.debug('Failing into the Catch-all: ESLT_Evaluation_Temp = blank');
                    ESLT_Evaluation_Temp = '';  
                }
            }
        }

        
        system.debug('*******************************************');
        system.debug('calculateEvaluationTemp()- IF(ESLT_Min_Temp < ESLT_Min_Temp_Limit,"FAIL","") Final Results:');
        system.debug('ESLT_Min_Temp_Limit: ' + ESLT_Min_Temp_Limit);
        system.debug('ESLT_Min_Temp: ' + ESLT_Min_Temp);
        system.debug('ESLT_Evaluation_Temp (ESLT O20) Evaluation "Temp": ' + ESLT_Evaluation_Temp);
        system.debug('*******************************************');
        
    }
    

    //O21 Evaluation "Time"
    private void calculateEvaluationTime(){

       //for **Each** Time Entered, do the Following: =IF(C16<$R$14,D16,0)
       system.debug('*************************************************************');
       system.debug('Entered calculateEvaluationTime (ESLT O21)');
        
       if (userUnitOfTemp == 'C'){
          ESLT_Max_Temp_Limit = lowTempMetaDataDO.LTT_SupportedLowMaxC;  
       }else{  
          ESLT_Max_Temp_Limit = lowTempMetaDataDO.LTT_SupportedLowMaxF;  
       }
            
       system.debug('userUnitOfTemp: ' + userUnitOfTemp);
       system.debug('ESLT_Max_Temp_Limit Max Temp Limit (ESLT R14 $R$14): ' + ESLT_Max_Temp_Limit);

       if(thisStringIsANumber(ESLT_Max_Temp_Limit)) {
          system.debug('ESLT_Max_Temp_Limit Max Temp Limit **IS A NUMBER**');
       }else{
          system.debug('ESLT_Max_Temp_Limit Max Temp Limit **IS A STRING**');
       }      
       
       for(MSD_CORE_CalcLowTempExcurExDetls userEnteredDetails : calculatedUserExposureDetailsEnteredList){
            
          if(! thisStringIsANumber(ESLT_Max_Temp_Limit)){
             userEnteredDetails.calulatedUserEnteredExposureTimeHours  = userEnteredDetails.hours;
             userEnteredDetails.calulatedUserEnteredExposureTimeMins = userEnteredDetails.min;
             userEnteredDetails.calulatedUserEnteredExposureTimeSeconds = userEnteredDetails.seconds;
          }else{
                if(userEnteredDetails.temp < Double.valueOf(ESLT_Max_Temp_Limit)){
                   userEnteredDetails.calulatedUserEnteredExposureTimeHours  = userEnteredDetails.hours;
                   userEnteredDetails.calulatedUserEnteredExposureTimeMins = userEnteredDetails.min;
                   userEnteredDetails.calulatedUserEnteredExposureTimeSeconds = userEnteredDetails.seconds;
                }else{
                   userEnteredDetails.calulatedUserEnteredExposureTimeHours  = 0;
                   userEnteredDetails.calulatedUserEnteredExposureTimeMins = 0;
                   userEnteredDetails.calulatedUserEnteredExposureTimeSeconds = 0;
                }
            }
        }
        
        Double totalCalculatedHours = 0;
        Double totalCalculatedMinutes = 0;
        Double totalCalculatedSeconds = 0;
        
        for(MSD_CORE_CalcLowTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
            totalCalculatedHours = totalCalculatedHours + cted.calulatedUserEnteredExposureTimeHours;
            totalCalculatedMinutes = totalCalculatedMinutes + cted.calulatedUserEnteredExposureTimeMins;
            totalCalculatedSeconds = totalCalculatedSeconds + cted.calulatedUserEnteredExposureTimeSeconds;
        }
        
        ESHT_TimeTotals = totalCalculatedHours + (totalCalculatedMinutes/60) + (totalCalculatedSeconds/3600);              
        
        system.debug('ESHT_TimeTotals (ESLT L15): ' + ESHT_TimeTotals);
        
        ESLT_Total_Hours_Allowed = lowTempMetaDataDO.LTT_NumberOfHours; //R16
        
        system.debug('ESLT_Total_Hours_Allowed (ESLT R16): ' + ESLT_Total_Hours_Allowed);

        if(thisStringIsANumber(ESLT_Total_Hours_Allowed)){
           system.debug('ESLT_Total_Hours_Allowed (ESLT R16) *IS A NUMBER*');
        }else{
           system.debug('ESLT_Total_Hours_Allowed (ESLT R16) *IS A STRING*');
        }
        
        //ESLT_Evaluation_Time = IF(L15>R16, "FAIL", "") so, IF(ESHT_TimeTotals > )
        //Note: In an Excel Spreadsheet, a Number (positive or Negative) will ALWAYS be LESS than a Text Value. 

        ESLT_Evaluation_Time = '';    

        if(! thisStringIsANumber(ESLT_Total_Hours_Allowed)){ //R16 a String, i.e., unlimited
           ESLT_Evaluation_Time = ''; //Since In an Excel Spreadsheet, a Number (positive or Negative) will ALWAYS be LESS than a Text Value.       
        }else{
            if(thisStringIsANumber(ESLT_Total_Hours_Allowed)){
                if(ESHT_TimeTotals > Double.valueOf(ESLT_Total_Hours_Allowed)){
                   ESLT_Evaluation_Time = 'FAIL';    
                }    
            }else{
               ESLT_Evaluation_Time = '';                       
            }
          
            
        }
        
        system.debug('ESLT_Evaluation_Time (ESLT O21): ' + ESLT_Evaluation_Time);
        system.debug('*************************************************************');
        
    }
    
    //O22 Evaluation "Cycles"
    private void calculateEvaluationCycles(){
       //REMEMBER: R17 can be a number or a String
       //Note: In an Excel Spreadsheet, a Number (positive or Negative) will ALWAYS be LESS than a Text Value. 
       //Double ESLT_Normalized_For_Cycles = 0; //K15
	   system.debug('**********************************************');
       System.debug('calculateEvaluationCycles() Start:');
        
        
       //Calculate R17
       ESLT_Cycles = lowTempMetaDataDO.LTT_NumberOfCycles; //R17
       system.debug('ESLT_Cycles (R17): ' + ESLT_Cycles);
        
        
       //Calculate K15 - ESLT_Normalized_For_Cycles

       //If the "Max Temp Limit" is a String (i.e., N/A) than ESLT_Normalized_For_Cycles is 
       //		just a count of the exposures entered by the user.
       //If its a Number, do the calculation... 
       if(thisStringIsANumber(ESLT_Max_Temp_Limit)){

          system.debug('ESLT_Max_Temp_Limit (ESLT R14) is a Number: ' + ESLT_Max_Temp_Limit);

          Double maxTempLimit = Double.valueOf(ESLT_Max_Temp_Limit); 
           
          for(MSD_CORE_CalcLowTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
             if(cted.temp < maxTempLimit){
               ESLT_Normalized_For_Cycles = ESLT_Normalized_For_Cycles + 1;
             }
          }
       }else{ //its a String

          system.debug('ESLT_Max_Temp_Limit (ESLT R14) is a String: ' + ESLT_Max_Temp_Limit);
          ESLT_Normalized_For_Cycles = calculatedUserExposureDetailsEnteredList.size();
       }

       //Calculate O22 =IF(R17="N/A","",IF(K15>R17,"FAIL","")) 
       //String ESLT_Evaluation_Cycles = ''; //O22
       //R17 - ESLT_Cycles -  R17 can be a number or a String 
       //K15 - ESLT_Normalized_For_Cycles - always a Double
       
       if(thisStringIsANumber(ESLT_Cycles)){
           if(ESLT_Normalized_For_Cycles > Double.valueOf(ESLT_Cycles)){
              ESLT_Evaluation_Cycles = 'FAIL'; 
           }  
       }else{ //its a String...
          ESLT_Evaluation_Cycles = '';  
       }
       
       system.debug('ESLT_Evaluation_Cycles (ESLT O22): ' + ESLT_Evaluation_Cycles);
        
       System.debug('calculateEvaluationCycles() -End-');
       system.debug('**********************************************');
      
    }

    
    //****************************************************
    //Methods to Support O20 Evaluation *Temp* Calculation
    //****************************************************
    
    /*
       R15: "Min Temp Limit" - =IF(COUNT(C16:C55)<1,0,IF(C9="C",'Low Temp Table'!C1,'Low Temp Table'!D1))

            C16:C55 - User Entered Exposure Temperatures
            C9: User Entered "Units of Temperature" -  "C" or "F"
            'Low Temp Table'!C1: ("Supported Low Min C") -
            'Low Temp Table'!D1: ("Supported Low Min F") -

    */
    private void calculateMinTempLimit(){
         System.debug('EULTEA 12');
       //String ESLT_Min_Temp_Limit = ''; //R15
        if(userExposureDetailsEntered.size()==0){
            ESLT_Min_Temp_Limit = '0';
        }else{
            if(userUnitOfTemp == 'C'){
               ESLT_Min_Temp_Limit = lowTempMetaDataDO.LTT_SupportedLowMinC; //could be Text i.e., N/A
            }else{
               ESLT_Min_Temp_Limit = lowTempMetaDataDO.LTT_SupportedLowMinF; //could be Text i.e., N/A
            }
        } 
        system.debug('-----------------------------------------');
        system.debug('calculateMinTempLimit()-ESLT R15 Results:');
        system.debug('userExposureDetailsEntered.size(): ' + userExposureDetailsEntered.size());
        system.debug('userUnitOfTemp: ' + userUnitOfTemp);
        system.debug('lowTempMetaDataDO.LTT_SupportedLowMinC: ' + lowTempMetaDataDO.LTT_SupportedLowMinC);
        system.debug('lowTempMetaDataDO.LTT_SupportedLowMinF: ' + lowTempMetaDataDO.LTT_SupportedLowMinF);
        system.debug('FINAL Result:ESLT_Min_Temp_Limit (ESLT R15): ' + ESLT_Min_Temp_Limit);
        system.debug('-----------------------------------------');

    }
    
    //O15: "Min Temp" - =IF(AND(MIN(C16:C55)>R30,MIN(C16:C55)<R31),MIN(C16:C55),ROUND(MIN(C16:C55),0))
    private void calculateMinTemp(){
 System.debug('EULTEA 13');
       //calculate user entered MIN Temperature   //userExposureDetailsEntered MSD_CORE_TempExcurExposDetail__c
       Set<Double> userEnteredTempsSet = new Set<Double>();
       List<Double> userEnteredTempList = new  List<Double>();
       Double userEnteredMinTemp = 0;
       Double userEnteredRoundedMinTemp = 0;
       System.debug('EULTEA 13a'); 
       for (MSD_CORE_TempExcurExposDetail__c uedl : userExposureDetailsEntered){
           System.debug('EULTEA 13a1 uedl.MSD_CORE_Temp__c: ' + uedl.MSD_CORE_Temp__c); 
          userEnteredTempsSet.add(uedl.MSD_CORE_Temp__c);
       }   
       System.debug('EULTEA 13b'); 
          
       userEnteredTempList = new List<Double>(userEnteredTempsSet);
       userEnteredTempList.sort();
       System.debug('EULTEA 13c'); 
        
       system.debug('-------------------------'); 
       system.debug('User Entered Temps Sorted:'); 
       for (Double x : userEnteredTempList){ 
          system.debug('User Temp: ' + x);
       }

       System.debug('EULTEA 13d'); 
        
        system.debug('-------------------------'); 

       userEnteredMinTemp =  userEnteredTempList[0];           
       system.debug('userEnteredMinTemp: ' + userEnteredMinTemp);
       System.debug('EULTEA 13e'); 

       //***************************************************
       //calculate the ROUNDED user entered MIN Temperature
       //***************************************************
       userEnteredRoundedMinTemp = userEnteredMinTemp.round(); 
       System.debug('KRB 13f'); 

       system.debug('userEnteredRoundedMinTemp: ' + userEnteredRoundedMinTemp);
       system.debug('-------------------------'); 
        
       //***************************************************
       //calculate R30 "Temp R Limit Lower" 
       //***************************************************

        if(userUnitOfTemp == 'C'){
            ESLT_Temp_R_Limit_Lower = ESLT_C_LOWER;
       }else{
            ESLT_Temp_R_Limit_Lower = ESLT_F_LOWER;
       }
       System.debug('EULTEA 13g'); 

        system.debug('Temp R Limit Lower (ESLT_Temp_R_Limit_Lower) (ESLT R30): ' + ESLT_Temp_R_Limit_Lower);

       //***************************************************
       //calculate R31 "Temp R Upper Lower" (ESLT_Temp_R_Upper_Lower)
       //***************************************************
       if(userUnitOfTemp == 'C'){
            ESLT_Temp_R_Upper_Lower = ESLT_C_UPPER; //R33
       }else{
            ESLT_Temp_R_Upper_Lower = ESLT_F_UPPER; //R35
       }
       system.debug('Temp R Upper Lower (ESLT_Temp_R_Upper_Lower) (ESLT R31): ' + ESLT_Temp_R_Upper_Lower);
       System.debug('EULTEA 13h'); 

       //***************************************************
       //Calculate O15: "Min Temp" - (ESLT_Min_Temp)
       //***************************************************
       
       /*
          =IF(
               AND(
                    MIN(C16:C55)>R30,
                    MIN(C16:C55)<R31
                  ),
               MIN(C16:C55),
               ROUND(MIN(C16:C55),0)
             )
       */ 
        
        if((userEnteredMinTemp > ESLT_Temp_R_Limit_Lower) && 
           (userEnteredMinTemp < ESLT_Temp_R_Upper_Lower)){
              ESLT_Min_Temp = userEnteredMinTemp;   
           } else{
              ESLT_Min_Temp = userEnteredRoundedMinTemp; 
           } 
        System.debug('EULTEA 13i'); 
       
       system.debug('Min Temp-(ESLT_Min_Temp) (ESLT O15): ' + ESLT_Min_Temp);
        System.debug('EULTEA 14');
    }
    
   /* -------------------------------------------------------------------- 
      Test Method to test this Class in isolation 
      ----------------------------------------------------------------- */

   public void runLowTempAssessmentTest(){
   }

   private void getLowTempMetaDataforProduct(String product, String genericProduct, String market){
       System.debug('EULTEA: Inside getLowTempMetaDataforProduct() ');
      //query the Product's Assessment Data to use for Calculation
       System.debug('EULTEA: a ');
 
      Id idRecordId = Schema.SObjectType.MSD_CORE_ProdAsmntMetadata__c.getRecordTypeInfosByDeveloperName().get('MSD_CORE_Low_Temp').getRecordTypeId();
      System.debug('RecordTypeId based on Developer Name ---> '+idRecordId); 
      System.debug('EULTEA: b ');
      
      String queryProduct = '';
      if(String.isNotBlank(product)){
         System.debug('EULTEA: b1 ');

      	 prodMetadataList = [SELECT Id,MSD_CORE_Brand_Name__c,MSD_CORE_Generic_Name__c,
									MSD_CORE_LT_Category__c,MSD_CORE_LT_Comment__c,
									MSD_CORE_LT_LblTmpRngMnC__c,MSD_CORE_LT_LblTmpRngMnF__c,
									MSD_CORE_LT_LblTmpRngMxC__c,MSD_CORE_LT_LblTmpRngMxF__c,
									MSD_CORE_LT_NumOfCycles__c,MSD_CORE_LT_NumOfHours__c,
									MSD_CORE_LT_SLblRngTmpMnC__c,MSD_CORE_LT_SLblRngTmpMnF__c,
									MSD_CORE_LT_SLblRngTmpMxC__c,MSD_CORE_LT_SLblRngTmpMxF__c,
									MSD_CORE_LT_SpprtdLwMnC__c,MSD_CORE_LT_SpprtdLwMnF__c,
									MSD_CORE_LT_SpprtdLwMxC__c,MSD_CORE_LT_SpprtdLwMxF__c,
									MSD_CORE_LT_Time__c,MSD_CORE_LT_UnitsOfTime__c,
									MSD_CORE_LT_Unlimited_Time__c,MSD_CORE_Market__c,Name,OwnerId,
									RecordTypeId 
                          	FROM 	MSD_CORE_ProdAsmntMetadata__c 
                          	WHERE	RecordTypeId =: idRecordId 
                          	AND 	MSD_CORE_Brand_Name__c =: product
                            AND		MSD_CORE_Market__c =: market];
          
		queryProduct = product;
      }else{
         System.debug('EULTEA: b2 ');

         prodMetadataList = [SELECT Id,MSD_CORE_Brand_Name__c,MSD_CORE_Generic_Name__c,
									MSD_CORE_LT_Category__c,MSD_CORE_LT_Comment__c,
									MSD_CORE_LT_LblTmpRngMnC__c,MSD_CORE_LT_LblTmpRngMnF__c,
									MSD_CORE_LT_LblTmpRngMxC__c,MSD_CORE_LT_LblTmpRngMxF__c,
									MSD_CORE_LT_NumOfCycles__c,MSD_CORE_LT_NumOfHours__c,
									MSD_CORE_LT_SLblRngTmpMnC__c,MSD_CORE_LT_SLblRngTmpMnF__c,
									MSD_CORE_LT_SLblRngTmpMxC__c,MSD_CORE_LT_SLblRngTmpMxF__c,
									MSD_CORE_LT_SpprtdLwMnC__c,MSD_CORE_LT_SpprtdLwMnF__c,
									MSD_CORE_LT_SpprtdLwMxC__c,MSD_CORE_LT_SpprtdLwMxF__c,
									MSD_CORE_LT_Time__c,MSD_CORE_LT_UnitsOfTime__c,
									MSD_CORE_LT_Unlimited_Time__c,MSD_CORE_Market__c,Name,OwnerId,
									RecordTypeId 
                          	FROM 	MSD_CORE_ProdAsmntMetadata__c 
                          	WHERE	RecordTypeId =: idRecordId 
                          	AND 	MSD_CORE_Brand_Name__c =: genericProduct
                            AND		MSD_CORE_Market__c =: market]; 
 
         
          queryProduct = genericProduct;
       }
       
       System.debug('EULTEA: c');
     
       if (prodMetadataList.size() > 0){
          MSD_CORE_ProdAsmntMetadata__c prodMetadata = prodMetadataList[0];
     	  	lowTempMetaDataDO.userProduct = queryProduct;
          	lowTempMetaDataDO.LTT_SupportedLowMinC = prodMetadata.MSD_CORE_LT_SpprtdLwMnC__c;
      		lowTempMetaDataDO.LTT_SupportedLowMinF = prodMetadata.MSD_CORE_LT_SpprtdLwMnF__c; //Supported Low Min F //D //Text and number 
      		lowTempMetaDataDO.LTT_SupportedLowMaxC = prodMetadata.MSD_CORE_LT_SpprtdLwMxC__c; //switch between 'N/A' and '0' Supported Low Max C //E //Text and number
      		lowTempMetaDataDO.LTT_SupportedLowMaxF = prodMetadata.MSD_CORE_LT_SpprtdLwMxF__c; //Supported Low Max F //F //Text and number
      		lowTempMetaDataDO.LTT_LabeledTempRangeMinC = prodMetadata.MSD_CORE_LT_LblTmpRngMnC__c;  //Labeled Temp Range Min C //G //Number
      		lowTempMetaDataDO.LTT_LabeledTempRangeMinF = prodMetadata.MSD_CORE_LT_LblTmpRngMnF__c; //Labeled Temp Range Min F //H //Number
     	 	lowTempMetaDataDO.LTT_LabeledTempRangeMaxC  = prodMetadata.MSD_CORE_LT_LblTmpRngMxC__c; //Labeled Temp Range Max C //I //Number
      		lowTempMetaDataDO.LTT_LabeledTempRangeMaxF  = prodMetadata.MSD_CORE_LT_LblTmpRngMxF__c; //Labeled Temp Range Max F //J //Number
      		lowTempMetaDataDO.LTT_Time = prodMetadata.MSD_CORE_LT_Time__c; //Time //K //Text and Number
      		lowTempMetaDataDO.LTT_UnitsOfTime = prodMetadata.MSD_CORE_LT_UnitsOfTime__c; //Units of time //L //Text
      		lowTempMetaDataDO.LTT_NumberOfHours = prodMetadata.MSD_CORE_LT_NumOfHours__c; //Switch between 4 and 120 and abc to test "Evaluation: Time"//Number of hours //M //Text and Number
      		lowTempMetaDataDO.LTT_NumberOfCycles = prodMetadata.MSD_CORE_LT_NumOfCycles__c; //Number of Cycles //N //Text and Number
      		lowTempMetaDataDO.LTT_SecondLabelRangeTempMinC = prodMetadata.MSD_CORE_LT_SLblRngTmpMnC__c;    //Second Label Range Temp Min C //O //Text and Number
      		lowTempMetaDataDO.LTT_SecondLabelRangeTempMinF = prodMetadata.MSD_CORE_LT_SLblRngTmpMnF__c; //Second Label Range Temp Min F //P //Text and Number
      		lowTempMetaDataDO.LTT_SecondLabelRangeTempMaxC = prodMetadata.MSD_CORE_LT_SLblRngTmpMxC__c; // Second Label Range Temp Max C //Q //Text and Number
      		lowTempMetaDataDO.LTT_SecondLabelRangeTempMaxF = prodMetadata.MSD_CORE_LT_SLblRngTmpMxF__c;  //Second Label Range Temp Max F //R //Text and Number
      		lowTempMetaDataDO.LTT_UnlimitedTime = prodMetadata.MSD_CORE_LT_Unlimited_Time__c; //Hide if Number of Cycles N/A //S //Text
      		lowTempMetaDataDO.LTT_Comment = prodMetadata.MSD_CORE_LT_Comment__c; //Comment //T //Text
      		lowTempMetaDataDO.LTT_Category = prodMetadata.MSD_CORE_LT_Category__c; //Category //U //Number
      		lowTempMetaDataDO.spoolData();
       }
       
       System.debug('EULTEA: d');
       
      /*    was using as Test Data: leave in "commented out" as a reference....   
      //LTT_ = Low Temp Table            //<Spreadsheet Name//<Column>//<Data Type in SS>
      lowTempMetaDataDO.userProduct = 'INTEGRILIN'; //from User Input, used to query data
      lowTempMetaDataDO.LTT_SupportedLowMinC = '-20'; //switch between 'N/A' and '-20'//Supported Low Min C //C //Text and number
      lowTempMetaDataDO.LTT_SupportedLowMinF = '-4'; //Supported Low Min F //D //Text and number 
      lowTempMetaDataDO.LTT_SupportedLowMaxC = '0'; //switch between 'N/A' and '0' Supported Low Max C //E //Text and number
      lowTempMetaDataDO.LTT_SupportedLowMaxF = '32'; //Supported Low Max F //F //Text and number
      lowTempMetaDataDO.LTT_LabeledTempRangeMinC = '2';  //Labeled Temp Range Min C //G //Number
      lowTempMetaDataDO.LTT_LabeledTempRangeMinF  = '36'; //Labeled Temp Range Min F //H //Number
      lowTempMetaDataDO.LTT_LabeledTempRangeMaxC  = '8'; //Labeled Temp Range Max C //I //Number
      lowTempMetaDataDO.LTT_LabeledTempRangeMaxF  = '46'; //Labeled Temp Range Max F //J //Number
      lowTempMetaDataDO.LTT_Time = '5'; //Time //K //Text and Number
      lowTempMetaDataDO.LTT_UnitsOfTime = 'D'; //Units of time //L //Text
      lowTempMetaDataDO.LTT_NumberOfHours = '120'; //Switch between 4 and 120 and abc to test "Evaluation: Time"//Number of hours //M //Text and Number
      lowTempMetaDataDO.LTT_NumberOfCycles = '3'; //Number of Cycles //N //Text and Number
      lowTempMetaDataDO.LTT_SecondLabelRangeTempMinC = 'N/A';    //Second Label Range Temp Min C //O //Text and Number
      lowTempMetaDataDO.LTT_SecondLabelRangeTempMinF = 'N/A'; //Second Label Range Temp Min F //P //Text and Number
      lowTempMetaDataDO.LTT_SecondLabelRangeTempMaxC = 'N/A'; // Second Label Range Temp Max C //Q //Text and Number
      lowTempMetaDataDO.LTT_SecondLabelRangeTempMaxF = 'N/A';  //Second Label Range Temp Max F //R //Text and Number
      lowTempMetaDataDO.LTT_UnlimitedTime = 'No'; //Hide if Number of Cycles N/A //S //Text
      lowTempMetaDataDO.LTT_Comment = ''; //Comment //T //Text
      lowTempMetaDataDO.LTT_Category = 3; //Category //U //Number
      lowTempMetaDataDO.spoolData();
   */
   }


}












/*
 
Low Temp Calculation Notes: (pseudocode)
------------------
From the Low Temp Table Spreadsheet:
Name/Column/Type
Supported Low Min C   //C Text and number?

Supported Low Min F //D Text and number?

Supported Low Max C //E Text and number?

Supported Low Max F //F Text and number?

Labeled Temp Range Min C //G Number

Labeled Temp Range Min F //H Number

Labeled Temp Range Max C //I Number

Labeled Temp Range Max F //J Number

Time //K Text and Number

Units of time //L Text

Number of hours //M Text and Number

Number of Cycles //N Text and Number

Second Label Range Temp Min C //O Text and Number

Second Label Range Temp Min F //P Text and Number

Second Label Range Temp Max C //Q Text and Number

Second Label Range Temp Max F //R Text and Number

Hide if Number of Cycles N/A //S Text

Comment //T Text

Category //U Number

-------------------

 

Fields Not Used? O14 Max Temp

 

 

------------------------------------------------------------

Low Temp Calculation Notes:

------------------------------------------------------------

Final Calculated Field for Assessment Results: D8

=IF(

      AND(C6="",C7=""),  //If Product is not supplied, Blank. 

      "",

      IF(

          R26<>0,  // if R26 (Notes) is not = 0

          R26&" ", //   -  Take the value of the Note and add a space

          "")      //   -  else - no value

          &        // AND

      IF(

          COUNTIF(O20:O22,"")<>3,                          //If one of the Cells O20 - O22 Calculate to "FAIL"

          "Stability Data does not Support Continued Use", // -- Concatenate this value to the value in the above (IF)

          "Stability Data Supports Continued use")         // else, Contatenate this value to the value in the above (IF)

        )

 

-------------------------------------------

Trace of above Formula for Coding in Apex:

-------------------------------------------

C6: Brand Name - Picklist, user input

 

C7: Generic Name of Product - Picklist, user input

 

R26: ("Notes:") - ='Low Temp Table'!T1 //note, this gets populated to a "0" - need to handle in Code (String it!!!)

 

O20: (Evaluation: "Temp") - =IF(R15="","",IF(O15<R15,"FAIL",""))

 

               R15: "Min Temp Limit" - =IF(COUNT(C16:C55)<1,0,IF(C9="C",'Low Temp Table'!C1,'Low Temp Table'!D1))

                              C16:C55 - User Entered Exposure Temperatures

                              C9: User Entered "Units of Temperature" -  "C" or "F"

                              'Low Temp Table'!C1: ("Supported Low Min C") -

                              'Low Temp Table'!D1: ("Supported Low Min F") -

 

               O15: "Min Temp" - =IF(AND(MIN(C16:C55)>R30,MIN(C16:C55)<R31),MIN(C16:C55),ROUND(MIN(C16:C55),0))

                              C16:C55 - User Entered Exposure Temperatures

                                             - Calculate MIN

                                             - calculate ROUND MIN

                              R30: "Temp R Limit Lower" - =IF(C9="C",R32,R34)

                                             C9: User Entered "Units of Temperature" -  "C" or "F"

                                             R32: "C Lower" - Populated as a "-1" - no Formula/Calculations in Field - TODO: figure this out...

                                             R34: "F Lower" - Populated as a "30.2" - no Formula/Calculations in Field - TODO: figure this out...

 

                              R31: "Temp R Upper Lower"  - =IF(C9="C",R33,R35)

                                             C9: User Entered "Units of Temperature" -  "C" or "F"

                                             R33: "C Upper" - Populated as a "0" - no Formula/Calculations in Field - TODO: figure this out...

                                             R35: "F Upper" - Populated as a "32" - no Formula/Calculations in Field - TODO: figure this out...

 

O21: (Evaluation: "Time") - =IF(L15>R16,"FAIL","")

              

               L15: "Time Totals" - =(SUM(L16:L55))*24

 

                              L16:L55: Calculations on "User Entered Exposure Times"

 

                                             for **Each** Time Entered, do the Following: =IF(C16<$R$14,D16,0)

                                            

                                                            IF("User Entered Exposure **Time**" < $R$14){

                                                                           Use the User Entered Time

                                                            ELSE

                                                                           0

                                             where $R$14: "Max Temp Limit"               - =IF(C9="C",'Low Temp Table'!E1,'Low Temp Table'!F1)

                                                           

                                                            'Low Temp Table'!E1 : - "Supported Low Max C"  - IMPORTANT NOTE: Value could be a number or "N/A" - TODO - Figure out workaround!

                                                            'Low Temp Table'!F1 : - "Supported Low Max F"  - IMPORTANT NOTE: Value could be a number or "N/A" - TODO - Figure out workaround!

 

               R16: "Total Hours Allowed": - ='Low Temp Table'!M1

                             

                              'Low Temp Table'!M1: = "Number of hours" - IMPORTANT NOTE: Value could be a number or "Unlimited" - TODO - Figure out workaround!

              

 

O22: (Evaluation: "Cycles") - =IF(R17="N/A","",IF(K15>R17,"FAIL",""))

 

               R17: "Cycles" - ='Low Temp Table'!N1 "Number of Cycles"

                              'Low Temp Table'!N1 : - "Number of Cycles" - IMPORTANT NOTE: Value could be a number or "N/A" - TODO - Figure out workaround!

 

               K15: "Normalized for Cycles (Max)": - =MAX(K16:K55)

               

                For each User Entered Exposure Temperature, do the follow and then find the MAX:

                              K16:K55 "Normalized for Cycles" -:

                             

                                             For the First Exposure Entered by the User DO THIS (NOTE: NEED TO NOW KEEP THE EXPOSURED ENTERED ORDERED !!!!

                                                            IF(C16="",0,IF(C16<R14,1,0))

                                             For the next Exposure Entered and subsequent Exposures, do the Following!

                                                            =IF(C17="","",IF(C17<$R$14,K16+1,K16))

 

                                             (use some type of crazy Map Logic...?)

 

-----                      

C11: "Storage Label" : = =IF(AND(C7="",C6=""),"",IF(C9="C",R19&"C to "&R18&"C",R21&"F to "&R20&"F")&IF(R22<>"N/A"," and "&IF(C9="C",R23&"C to "&R22&"C",R25&"F to "&R24&"F"),""))                              

              

        Store below values as Text:

               R19: Min C Storage = ='Low Temp Table'!G1 - Labeled Temp Range Min C

               R18: Max C Storage = ='Low Temp Table'!I1 - Labeled Temp Range Max C

               R21: Min F Storage = ='Low Temp Table'!H1 - Labeled Temp Range Min F

               R20: Max F Storage = ='Low Temp Table'!J1 - Labeled Temp Range Max F

               R22: Max C Storage 2 = ='Low Temp Table'!Q1 - Second Label Range Temp Max C

               R23: Min C Storage 2 = ='Low Temp Table'!O1 - Second Label Range Temp Min C

               R25: Min F Storage 2 = ='Low Temp Table'!P1 - Second Label Range Temp Min F

               R24: Max F Storage 2 = ='Low Temp Table'!R1 - Second Label Range Temp Max F

 

 

B13: =IF(OR(R27="No",R27=""),"","Note: This product does not have a time limit")                           
*/