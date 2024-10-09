/*
 * KRB 5/29/2020 - 20R3.0 Conversion of Assessment Excel Spreadsheet to Lightning Flow
 * 
 * This class mimic the Calculations performed in the "Entry Sheet High Temp" 
 * Excel Spreadsheet found in the "End_User_Temp_Excursion_Assessment_v1.2.xlsm Rev.19"
 * 
 * The Calculations in this Class are for HIGH TEMP EXCURSIONS ONLY!
 * 
 * pseudocode for the spreadsheet that was used to generate this class appears at the 
 * bottom of this class. 
 * 
 * Definitions of Classes referenced in this code:
 *  MSD_CORE_CalcHighTempExcurAssmt //Invocable for the Flow Apex Action
 *  MSD_CORE_AssessmentResultsDO //Results of the Assessment
 *  EndUserHighTempExcursionAssessment //Core Class for High Temp Calculations - all High Temp Calculations processed in Logic
 *  MSD_CORE_HighTempMetaDataDO //Stores all the metaData for the Product the Assessment is being done for. 
 *	 

 * 24R3.0 KRB - Implemented Absolute Rounding - With Negative Temperatures, The Absolute Value will be rounded.
 *              New Method: private Double absoluteRoundDouble(Double myDouble) 
 * 				i.e., -8.5 rounded is -9 => 
 * 				Steps: Absolute -8.5 = 8.5, rounded = 9, then apply negative -9 (9 * -1 = -9)
 *
 *
 * Testing:
    
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

	EndUserHighTempExcursionAssessment x = new EndUserHighTempExcursionAssessment();
 	x.processHighTempExcursionAssessment(details, 
                                         userSuppliedMrkt,
                                         userSuppliedBrandNameProduct,
       									 userSuppliedGenericNameProduct, 
                                         userSuppliedUnitOfTemp);
 
 */

public class EndUserHighTempExcursionAssessment {
    
    
    //SELECT MSD_CORE_AssHrs__c,MSD_CORE_hours__c,MSD_CORE_Min__c,MSD_CORE_Temp__c,MSD_CORE_TotlHrs__c
    //FROM MSD_CORE_TempExcurExposDetail__c

    //Stores all the metaData for the Product the Assessment is being done for.
    //TODO: Currently this Object has all dummied up data...need to pull this based on User Product Selected.  
    MSD_CORE_HighTempMetaDataDO productDO = new MSD_CORE_HighTempMetaDataDO();
    
    List <MSD_CORE_TempExcurExposDetail__c> userExposureDetailsEntered = new List <MSD_CORE_TempExcurExposDetail__c>();
    MSD_CORE_TempExcurExposDetail__c ued1 = new MSD_CORE_TempExcurExposDetail__c();    

    //Stores User Input
    String userMrkt = '';
    String userProduct = '';
    String userGenericProduct = '';
    String userUnitOfTemp = '';

    //Processing Logic Variables
    String ESHT_maxTempFailure = '';  //For Step 3.0 Max Temp Failure N25
    Long roundedMaxUserEnteredTempExposure = 0; //For Step 3.1
    Double ESHT_tempMax2 = 0; //ESHT Q25 - Calculated Fields for STEP 3.2:
    Double ESHT_maxTempFinal = 0; //ESHT Q16 - Calculated Fields for STEP 3.2:
    Double ESHT_MaxTempLimit = 0; //ESHT $Q$17 - Data For Step 3.3.a.1
    Double ESHT_tempMax1 = 0; //ESHT $Q$24 - Data For Step 3.3.a.2
    Double ESHT_totalUserEnteredExTime = 0; //For Step 3.3.a.4
    Double ESHT_calTimeLimitDays = 0; //(Q31) - For Step 3.3.b 
    String ESHT_additionalEvaluation = '';     //For Step 3.3.c - calculated Field (S14)
    Double ESHT_timeTotalSecondTime = 0; //ESHT T18 For STEP 3.4.a.3
    String ESHT_additionalEvaluation2 = ''; //ESHT T14 For STEP 3.4.c
    Double ESHT_evaluationTimeTimeTotal = 0; //For STEP 4.a.2
    String ESHT_TimeEvaluation = ''; //STEP 4 = IF(K18>Q19, "FAIL", "") - N24
    String ESHT_SupportIndicator = ''; //STEP 6 = final Support Indicator presented to User... D9
    String ESHT_LabelStorageCondition = ''; //C14 - STEP 7 Label Storage Condition
    Double ESHT_MinTempLimit = 0; //Q18 - STEP 7 Label Storage Condition
    List <MSD_CORE_CalcTempExcurExDetls> calculatedUserExposureDetailsEnteredList = new List <MSD_CORE_CalcTempExcurExDetls>();

    List <MSD_CORE_ProdAsmntMetadata__c> prodMetadataList = new List <MSD_CORE_ProdAsmntMetadata__c>();


    //New Main Entry into Calculations  coded on 6/16 
    public MSD_CORE_AssessmentResultsDO processHighTempExcursionAssessment(
                                               List <MSD_CORE_TempExcurExposDetail__c> exposureList, 
                                               String userSuppliedMrkt,
                                               String userSuppliedBrandNameProduct,
       										   String userSuppliedGenericNameProduct, 
                                               String userSuppliedUnitOfTemp){
       //For the Return Trip...
       MSD_CORE_AssessmentResultsDO results = new MSD_CORE_AssessmentResultsDO();
       
       System.debug('EUHTEA: userSuppliedMrkt:' + userSuppliedMrkt);                                            
       System.debug('EUHTEA: userSuppliedBrandNameProduct:' + userSuppliedBrandNameProduct);                                            
       System.debug('EUHTEA: userSuppliedGenericNameProduct:' + userSuppliedGenericNameProduct);                                            
       System.debug('EUHTEA: userSuppliedUnitOfTemp:' + userSuppliedUnitOfTemp); 
       for(MSD_CORE_TempExcurExposDetail__c x: exposureList){
          System.debug('EUHTEA::exposureList.MSD_CORE_hours__c'+ x.MSD_CORE_hours__c); 
          System.debug('EUHTEA::exposureList.MSD_CORE_Min__c'+ x.MSD_CORE_Min__c);                                               
          System.debug('EUHTEA::exposureList.MSD_CORE_Seconds__c'+ x.MSD_CORE_Seconds__c); 

       }
                                                                      
       
       //Quick Exit if we dont have all the required information:
       if((String.isBlank(userSuppliedUnitOfTemp)) ||
          (String.isBlank(userSuppliedBrandNameProduct))){
           results.supportIndicator = 'Missing Necessary information: Temp/Product. Calculation could not be Completed.';
           System.debug('Missing Necessary information. Temp/Product. Calculation could not be Completed.');
           System.debug('userSuppliedBrandNameProduct: ' + userSuppliedBrandNameProduct );
           System.debug('userSuppliedUnitOfTemp: ' + userSuppliedUnitOfTemp );
           return results;
       }
       /*
       if(userSuppliedUnitOfTemp != 'C' || userSuppliedUnitOfTemp != 'F'){
           results.supportIndicator = 'Missing Necessary information: Temp has to be C or F.';
           System.debug('Missing Necessary information: Temp has to be C or F.');
           System.debug('userSuppliedUnitOfTemp: ' + userSuppliedUnitOfTemp );
           return results;
       }*/
                                                   
       if(exposureList.isEmpty()){
           results.supportIndicator = 'Missing Necessary information: Excursion Details. Calculation could not be Completed.';
           System.debug('Missing Necessary information. Excursion Details. Calculation could not be Completed.');
           return results;
        }
         
        for(MSD_CORE_TempExcurExposDetail__c exposure: exposureList){

           MSD_CORE_TempExcurExposDetail__c exp = new MSD_CORE_TempExcurExposDetail__c();
           exp.MSD_CORE_hours__c = exposure.MSD_CORE_hours__c;
           exp.MSD_CORE_Min__c = exposure.MSD_CORE_Min__c;
           exp.MSD_CORE_Seconds__c = exposure.MSD_CORE_Seconds__c;
           exp.MSD_CORE_Temp__c = exposure.MSD_CORE_Temp__c;
           userExposureDetailsEntered.add(exp);        
        }
         
        if(String.isBlank(userSuppliedMrkt)){
           userMrkt = 'US';                                             
        }
                                                   
        if(String.isNotBlank(userSuppliedGenericNameProduct)){
           userGenericProduct = userSuppliedGenericNameProduct;
        }
                                                   
        if(String.isNotBlank(userSuppliedBrandNameProduct)){
           userProduct = userSuppliedBrandNameProduct;
        }

        userUnitOfTemp = userSuppliedUnitOfTemp; 
        userMrkt = userSuppliedMrkt;

        // Dont want to mess with the User Temp/Time Exposure details that the User Entered.
        // Store user Exposure input in seperate Object to perform calculations that we dont want to store
        // Use the calculatedUserExposureDetailsEnteredList List of Objects to do all calculations...
        for(MSD_CORE_TempExcurExposDetail__c x: userExposureDetailsEntered){
           MSD_CORE_CalcTempExcurExDetls cuede = new MSD_CORE_CalcTempExcurExDetls();
           cuede.hours = x.MSD_CORE_hours__c;
           cuede.min = x.MSD_CORE_Min__c;
           cuede.seconds = x.MSD_CORE_Seconds__c;
           cuede.temp = x.MSD_CORE_Temp__c;
           calculatedUserExposureDetailsEnteredList.add(cuede); 
        }

        //Exit if no Exposures were entered by the user...
        if(calculatedUserExposureDetailsEnteredList.size() == 0){
		   System.debug('calculatedUserExposureDetailsEnteredList was empty. Exiting.');
           results.supportIndicator = 'No Exposures Entered. Calculation could not be Completed.';
           return results;
        }                                                   
                                                   
        //TODO: Get all the Data into a NEW OBJECT AND Write the CODE to Retrieve it!!!!
        getHighTempMetaDataforProduct(userProduct, userGenericProduct, userSuppliedMrkt);
 
        if(prodMetadataList.isEmpty()){
             System.debug('Could not find Product Metadata. exiting.');
             results.supportIndicator = 'No Metadata found for given Product';
             results.labelStorageCondition = 'No Metadata found for given Product';
             return results;
                                                           
         }else{
             performCalculations();  
         }
                
         results.supportIndicator = ESHT_SupportIndicator;
         results.labelStorageCondition = ESHT_LabelStorageCondition;
         
         if(String.isNotBlank(productDO.HTM_FootNote)){
           results.HTFootNote = productDO.HTM_FootNote;                                            
         }
                                                   
         if(String.isNotBlank(productDO.HTM_Comment)){
           results.HTComment = productDO.HTM_Comment;                                            
         }
                                                                                                      
         return results;
                                                   
    }
    
        
    private void performCalculations(){
        calculateMaxTempFailure(); //STEP 3.0 N25
        calculateEvaluationTime(); //STEP 4.0 N24
        calculateSupportIndicator(); //STEP 6.0 D9
        calculateLabelStorageCondition(); //STEP 7.0 C14
        
    }
    
    /*
     * 24R3.0 KRB - This funtion "absolute" rounds a Double. 
    */
    private Double absoluteRoundDouble(Double myDouble){
       
       Double finalAbsoluteRoundedDouble;
        
       System.debug('KRB 24R3.0: Double passed into absoluteRoundDouble function: ' + myDouble);

      if(myDouble < 0){
          Double absoluteX = Math.abs(myDouble);
          System.debug('KRB 24R3.0: absoluteX:' + absoluteX );
          Double roundedAbsoluteX = absoluteX.round();
          System.debug('KRB 24R3.0: roundedAbsoluteX:' + roundedAbsoluteX );
          Double NegativeRoundedAbsoluteX = roundedAbsoluteX * -1;
          System.debug('KRB 24R3.0: NegativeRoundedAbsoluteX:' + NegativeRoundedAbsoluteX );
          finalAbsoluteRoundedDouble = NegativeRoundedAbsoluteX;
          System.debug('KRB 24R3.0: Final Rounded Number: ' + finalAbsoluteRoundedDouble);

       }else{ 

          System.debug('KRB 24R3.0: Positive Number, calling the normal round function...');
          finalAbsoluteRoundedDouble = myDouble.round();
       }

      System.debug('KRB 24R3.0: finalAbsoluteRoundedDouble: ' + finalAbsoluteRoundedDouble);
      return finalAbsoluteRoundedDouble;
        
    }
   
    
    /*
     * STEP 7 - Calculate Label Storage Condition (C14) 
     */
    private void calculateLabelStorageCondition(){
       /*
        * =IF(
        *      AND(
        *           C7="",  //either C7 or C6 will always be populated!
        *           C6=""
        *         ),
        *      "",
        *      IF(          //Start here
        *         C10="C",
        *         Q18&"C to "&Q17&"C",
        *         Q18&"F to "&Q17&"F")
        *      )
        */
        if(userUnitOfTemp == 'C'){
           ESHT_LabelStorageCondition = ESHT_MinTempLimit + 'C to ' + ESHT_MaxTempLimit + 'C';
        }else{
           ESHT_LabelStorageCondition = ESHT_MinTempLimit + 'F to ' + ESHT_MaxTempLimit + 'F';
        }
        
        System.debug('Storage Label Results:.....');
        System.debug('User entered unit of Temp:' + userUnitOfTemp);
        System.debug('(Q18) Min Temp Limit (ESHT_MinTempLimit): ' + ESHT_MinTempLimit);
        System.debug('(Q17) Max Temp Limit (ESHT_MaxTempLimit): ' + ESHT_MaxTempLimit);
        System.debug('(C14) Label Storage Condition (ESHT_LabelStorageCondition): ' + ESHT_LabelStorageCondition);
        
    }
    
       
    /*
     * STEP 6 - Calculate Support Indicator D9 presented to the User
     */
    private void calculateSupportIndicator(){
        
       /*  =IF(
        *       C8="",  //User entered Market - so make it Required...
        *       "",
        *       IF(
        *           AND(
        *                OR(
        *                    N25="FAIL",   //ESHT_maxTempFailure
        *                    N24="FAIL"    //ESHT_TimeEvaluation
        *                   ),
        *                Q28="N"   //productDO.HTM_timeAllowance
        *               ),
        *           "Stability Data does not Support Continued Use",
        *           IF(
        *               AND(
        *                   N25="FAIL", //ESHT_maxTempFailure 
        *                   Q28="Y"     //productDO.HTM_timeAllowance
        *                  ),
        *              "Stability Data does not Support Continued Use",
        *              "Stability Data Supports Continued use"
        *             )    
        *          )
        *      )
        * 
        */
        
        if(String.isEmpty(userMrkt) || String.isBlank(userMrkt)){
           ESHT_SupportIndicator = ''; 
        }else if( (ESHT_maxTempFailure == 'FAIL' || ESHT_TimeEvaluation == 'FAIL') && (productDO.HTM_timeAllowance == 'N')){
           ESHT_SupportIndicator = 'Stability Data does not Support Continued Use'; 
        }else if(ESHT_maxTempFailure == 'FAIL' && productDO.HTM_timeAllowance == 'Y'){
           ESHT_SupportIndicator = 'Stability Data does not Support Continued Use'; 
        }else{
           ESHT_SupportIndicator = 'Stability Data Supports Continued use'; 
        }
    
        System.debug('---calculateSupportIndicator() Results:');
        System.debug('userMrkt: ' + userMrkt);
        System.debug('ESHT_maxTempFailure: ' + ESHT_maxTempFailure);
        System.debug('ESHT_TimeEvaluation: ' + ESHT_TimeEvaluation);
        System.debug('productDO.HTM_timeAllowance: ' + productDO.HTM_timeAllowance);
        System.debug('Resulting Assessment (ESHT_SupportIndicator): ' + ESHT_SupportIndicator);
    }

    
    /*
     * STEP 3: final result is N25 - Max Temp Failure 
     */
    private void calculateMaxTempFailure(){
        calculateRoundedMaxUserEnteredTempExposure(userExposureDetailsEntered);//STEP 3.1
        calculateMaxTempFinal(); //STEP 3.2
        calculateTotalUserEnteredExTime(); //STEP 3.3.a.3
        calculateAdditionalEvaluation(); //STEP 3.3
        calculateAdditionalEvaluation2(); //STEP 3.4
        
        //Final Result for N25 Field - Max Temp Failure:
        //IF(ROUND(MAX(C19:C58),0)>Q16, "FAIL", IF(OR(S14="FAIL",T14="FAIL"), "FAIL", ""))
        //IF the Max Exposure Temp Entered by the User, Rounded to 0 decimal places, (roundedMaxUserEnteredTempExposure) is Greater than 
        //    the product's productDO.HTM_tempC , 
        // 		 N25 = "FAIL", 
        // ELSE IF ( ESHT_additionalEvaluation == 'FAIL' OR ESHT_additionalEvaluation2 == 'FAIL')
        // 		N25 = 'FAIL'
        // ELSE N25 = ''
        
        //Double roundedMaxUserEnteredTempExposure = 0;
        if(roundedMaxUserEnteredTempExposure > ESHT_maxTempFinal){
           ESHT_maxTempFailure = 'FAIL';    
        }else if((ESHT_additionalEvaluation == 'FAIL') || (ESHT_additionalEvaluation2 == 'FAIL')){
           ESHT_maxTempFailure = 'FAIL';  
        }else{
           ESHT_maxTempFailure = ''; 
        }
        
        System.debug('(N25) ESHT_maxTempFailure: ' + ESHT_maxTempFailure);
        
    }
    
    /*
     * Step 4.0 Compute the N24 value Evalution_time
     */
    
    private void calculateEvaluationTime(){
        //Calculate time totals(K18) = (SUM(K19:K58))*24 result needs to be hh.mm where mm is a fraction of an hour..
        //4.a.1 $Q$17 values lives in ESHT_MaxTempLimit
        
        //4.a.2  Evaluation Time - time calculation (K18)
        for(MSD_CORE_CalcTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
 
          //Out for 24R3.0
          //if(cted.temp.round() > ESHT_MaxTempLimit){
          //In for 24R3.0
          System.debug('KRB 24R3.0: cted.temp: ' + cted.temp); 
          System.debug('KRB 24R3.0: cted.temp.round() should = absoluteRoundDouble(cted.temp), except for -.5 numbers...');
          System.debug('KRB 24R3.0: cted.temp.round(): ' + cted.temp.round()); 
          System.debug('KRB 24R3.0: absoluteRoundDouble(cted.temp): ' + absoluteRoundDouble(cted.temp)); 
            
          if(absoluteRoundDouble(cted.temp) > ESHT_MaxTempLimit){
             cted.evaluationTimeCalcUserEnteredExposureTimeHours = cted.hours;
             cted.evaluationTimeCalcUserEnteredExposureTimeMins = cted.min;
             cted.evaluationTimeCalcUserEnteredExposureTimeSeconds = cted.seconds;
          }else{
             cted.evaluationTimeCalcUserEnteredExposureTimeHours = 0;
             cted.evaluationTimeCalcUserEnteredExposureTimeMins = 0;
             cted.evaluationTimeCalcUserEnteredExposureTimeSeconds = 0;

          }
 
       }

        Double totalCalculatedHours = 0;
        Double totalCalculatedMinutes = 0;
        Double totalCalculatedSeconds = 0;
        
        for(MSD_CORE_CalcTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
            totalCalculatedHours = totalCalculatedHours + cted.evaluationTimeCalcUserEnteredExposureTimeHours;
            totalCalculatedMinutes = totalCalculatedMinutes + cted.evaluationTimeCalcUserEnteredExposureTimeMins;
            totalCalculatedSeconds = totalCalculatedSeconds + cted.evaluationTimeCalcUserEnteredExposureTimeSeconds;
        }
        
        ESHT_evaluationTimeTimeTotal = totalCalculatedHours + (totalCalculatedMinutes/60) + (totalCalculatedSeconds/3600);              
       
        //4.a.3 value lives in productDO.HTM_MarketMaxHours (ESHT Q19/ HTT L16)
        //ESHT_TimeEvaluation = IF(K18>Q19, "FAIL", "") - N24
        
        if(ESHT_evaluationTimeTimeTotal > productDO.HTM_MarketMaxHours){
           ESHT_TimeEvaluation = 'FAIL';
        }else{
           ESHT_TimeEvaluation = ''; 
        }
        
        System.debug('..calculateEvaluationTime Results:');
        System.debug('4.a.1 (ESHT Q17) -  if C, (HTT C16), If F (HTT D16) - ESHT_MaxTempLimit: ' + ESHT_MaxTempLimit);
        System.debug('4.a.2 (ESHT K18) Evaluation Time - time calculation ESHT_evaluationTimeTimeTotal: ' + ESHT_evaluationTimeTimeTotal);
        System.debug('4.a.3 (ESHT Q19/ HTT L16) productDO.HTM_MarketMaxHours: ' + productDO.HTM_MarketMaxHours);
        System.debug('4.a.3 (ESHT N24) <= IF(K18>Q19, "FAIL", ""> ESHT_TimeEvaluation: ' + ESHT_TimeEvaluation);

     }
    
   
    private void getHighTempMetaDataforProduct(String product, String genericProduct, String market){
                

      //query the Product's Assessment Data to use for Calculation
      
      Id idRecordId = Schema.SObjectType.MSD_CORE_ProdAsmntMetadata__c.getRecordTypeInfosByDeveloperName().get('MSD_CORE_High_Temp').getRecordTypeId();
      System.debug('RecordTypeId based on Developer Name ---> '+idRecordId); 
     
        
      String queryProduct = '';
      if(String.isNotBlank(product)){
        System.debug('EUHTEA: Brand Product Populated. Doing Query for Brand Product:' + product); 
        System.debug('EUHTEA: idRecordId: ' + idRecordId); 
        System.debug('EUHTEA: market: ' + market); 


      	 prodMetadataList = [SELECT Id,MSD_CORE_Brand_Name__c,MSD_CORE_Generic_Name__c,MSD_CORE_HT_Comment__c,
									MSD_CORE_HT_FootNote__c,MSD_CORE_HT_LabelMaxC__c,MSD_CORE_HT_LabelMaxF__c,
                             		MSD_CORE_HT_LabelMinC__c,MSD_CORE_HT_LabelMinF__c,MSD_CORE_HT_MarketMaxHours__c,
									MSD_CORE_HT_Temp2MaxC__c,MSD_CORE_HT_Temp2MaxF__c,
									MSD_CORE_HT_Temp2TimeHours__c,MSD_CORE_HT_TempC__c,
									MSD_CORE_HT_TempF__c,MSD_CORE_HT_TimeAllowanceC__c,
									MSD_CORE_HT_TimeAllowanceF__c,MSD_CORE_HT_TimeAllowance__c,
									MSD_CORE_HT_TimeLimitDays__c,MSD_CORE_Market__c,RecordTypeId 
                          	FROM 	MSD_CORE_ProdAsmntMetadata__c 
                          	WHERE	RecordTypeId =: idRecordId 
                          	AND 	MSD_CORE_Brand_Name__c =: product
                            AND		MSD_CORE_Market__c =: market]; 
		queryProduct = product;
      }else{
      	 prodMetadataList = [SELECT Id,MSD_CORE_Brand_Name__c,MSD_CORE_Generic_Name__c,MSD_CORE_HT_Comment__c,
									MSD_CORE_HT_FootNote__c,MSD_CORE_HT_LabelMaxC__c,MSD_CORE_HT_LabelMaxF__c,
                             		MSD_CORE_HT_LabelMinC__c,MSD_CORE_HT_LabelMinF__c,MSD_CORE_HT_MarketMaxHours__c,
									MSD_CORE_HT_Temp2MaxC__c,MSD_CORE_HT_Temp2MaxF__c,
									MSD_CORE_HT_Temp2TimeHours__c,MSD_CORE_HT_TempC__c,
									MSD_CORE_HT_TempF__c,MSD_CORE_HT_TimeAllowanceC__c,
									MSD_CORE_HT_TimeAllowanceF__c,MSD_CORE_HT_TimeAllowance__c,
									MSD_CORE_HT_TimeLimitDays__c,MSD_CORE_Market__c,RecordTypeId 
                         	FROM 	MSD_CORE_ProdAsmntMetadata__c 
                          	WHERE	RecordTypeId =: idRecordId 
                          	AND 	MSD_CORE_Brand_Name__c =: genericProduct
                            AND		MSD_CORE_Market__c =: market]; 
         
          queryProduct = genericProduct;
       }

        if (prodMetadataList.size() > 0){
           MSD_CORE_ProdAsmntMetadata__c prodMetadata = prodMetadataList[0];    
           productDO.userProduct = queryProduct; 

           //load up the DO Object
           //STEP 3.2
            productDO.HTM_timeAllowance = prodMetadata.MSD_CORE_HT_TimeAllowance__c; //ESHT Q28 too
            productDO.HTM_timeAllowanceC = prodMetadata.MSD_CORE_HT_TimeAllowanceC__c;
            productDO.HTM_timeAllowanceF = prodMetadata.MSD_CORE_HT_TimeAllowanceF__c;
            productDO.HTM_temp2MaxC = prodMetadata.MSD_CORE_HT_Temp2MaxC__c;
            productDO.HTM_temp2MaxF = prodMetadata.MSD_CORE_HT_Temp2MaxF__c;
            
            if(userUnitOfTemp == 'C'){
               ESHT_tempMax2 = productDO.HTM_temp2MaxC;
            }else{
               ESHT_tempMax2 =  productDO.HTM_temp2MaxF;
            }
       
            System.debug('User Entered UnitOfTemp: ' + userUnitOfTemp);
            System.debug('(Q25) ESHT_tempMax2: ' + ESHT_tempMax2);
            //END: STEP 3.2 
            
            //Start: STEP 3.3.a.1 
            productDO.HTM_labelMaxC = prodMetadata.MSD_CORE_HT_LabelMaxC__c; //C16
            productDO.HTM_labelMaxF = prodMetadata.MSD_CORE_HT_LabelMaxF__c; //D16
            
            //($Q$17)
            if(userUnitOfTemp == 'C'){
               ESHT_MaxTempLimit = productDO.HTM_labelMaxC;
            }else{
               ESHT_MaxTempLimit = productDO.HTM_labelMaxF;
            }
            System.debug('($Q$17) ESHT_MaxTempLimit: ' + ESHT_MaxTempLimit);
            
            //Start: Data For Step 3.3.a.2 
            productDO.HTM_tempC = prodMetadata.MSD_CORE_HT_TempC__c; //AQ16
            productDO.HTM_tempF = prodMetadata.MSD_CORE_HT_TempF__c; //AR16
            
            //($Q$24)
            if(userUnitOfTemp == 'C'){
               ESHT_tempMax1 = productDO.HTM_tempC;
            }else{
               ESHT_tempMax1 = productDO.HTM_tempF;
            }
            System.debug('($Q$24) ESHT_tempMax1: '+ ESHT_tempMax1);
            
            //Start: Data for 3.3.b 
            productDO.HTM_timeLimitDays = prodMetadata.MSD_CORE_HT_TimeLimitDays__c; //AP16
        
            //calculation for Step 3.3.b
            if (productDO.HTM_timeLimitDays > 0){
               ESHT_calTimeLimitDays = productDO.HTM_timeLimitDays * 24; //Q31
            }else{
               ESHT_calTimeLimitDays = 0;
            }
            
            System.debug('(Q31) ESHT_calTimeLimitDays: ' + ESHT_calTimeLimitDays);
            
            productDO.HTM_temp2MaxC = prodMetadata.MSD_CORE_HT_Temp2MaxC__c; //AT16 and Q35
            productDO.HTM_temp2MaxF = prodMetadata.MSD_CORE_HT_Temp2MaxF__c;//AU16 and Q36
            
            productDO.HTM_Temp2TimeHours = prodMetadata.MSD_CORE_HT_Temp2TimeHours__c; //AS16 and Q34
        
            //Step 4.0 
            productDO.HTM_MarketMaxHours = prodMetadata.MSD_CORE_HT_MarketMaxHours__c; // (HHT L16 and ESHT_Q19 totalHoursAllowed)
        
            //Step 7.0
            productDO.HTM_LabelMinC = prodMetadata.MSD_CORE_HT_LabelMinC__c; //(HHT E16) (ESHT_Q18)
            productDO.HTM_LabelMinF = prodMetadata.MSD_CORE_HT_LabelMinF__c; //(HHT F16) (ESHT_Q18)
            
            if(userUnitOfTemp == 'C'){
               ESHT_MinTempLimit = productDO.HTM_LabelMinC;
            }else{
               ESHT_MinTempLimit = productDO.HTM_LabelMinF;         
            }
        
            //Step 8 
            if(String.isNotBlank(prodMetadata.MSD_CORE_HT_FootNote__c)){
               productDO.HTM_FootNote = prodMetadata.MSD_CORE_HT_FootNote__c;   
            }
        
            //Step 9 
            if(String.isNotBlank(prodMetadata.MSD_CORE_HT_Comment__c)){
               productDO.HTM_Comment = prodMetadata.MSD_CORE_HT_Comment__c; //(HHT AL16) (ESHT Q21)
            }

          productDO.spoolData();
        }

        //---------using Integrilin as an example...
        /* What I was testing with....keep for a reference for some time..     
        //TODO: APEX SOQL to Pull productBrand
        //TODO: Apex SOQL to Pull productGeneric
        
        //if(String.isNotEmpty(productBrand) && String.isNotBlank(productBrand)){
            //TODO: Apex SOQL to Pull productBrand
            
            //load up the DO Object
            //STEP 3.2
            productDO.HTM_timeAllowance = 'Y'; //ESHT Q28 too
            productDO.HTM_timeAllowanceC = 0;
            productDO.HTM_timeAllowanceF = 0;
            productDO.HTM_temp2MaxC = 45;
            productDO.HTM_temp2MaxF = 113;
            
            if(userUnitOfTemp == 'C'){
               ESHT_tempMax2 = productDO.HTM_temp2MaxC;
            }else{
               ESHT_tempMax2 =  productDO.HTM_temp2MaxF;
            }
       
            System.debug('User Entered UnitOfTemp: ' + userUnitOfTemp);
            System.debug('(Q25) ESHT_tempMax2: ' + ESHT_tempMax2);
            //END: STEP 3.2 
            
            //Start: STEP 3.3.a.1 
            productDO.HTM_labelMaxC = 8; //C16
            productDO.HTM_labelMaxF = 46; //D16
            
            
            //($Q$17)
            if(userUnitOfTemp == 'C'){
               ESHT_MaxTempLimit = productDO.HTM_labelMaxC;
            }else{
               ESHT_MaxTempLimit = productDO.HTM_labelMaxF;
            }
            System.debug('($Q$17) ESHT_MaxTempLimit: ' + ESHT_MaxTempLimit);
            
            //Start: Data For Step 3.3.a.2 
            productDO.HTM_tempC = 25; //AQ16
            productDO.HTM_tempF = 77; //AR16
            
            //($Q$24)
            if(userUnitOfTemp == 'C'){
               ESHT_tempMax1 = productDO.HTM_tempC;
            }else{
               ESHT_tempMax1 = productDO.HTM_tempF;
            }
            System.debug('($Q$24) ESHT_tempMax1: '+ ESHT_tempMax1);
            
            //Start: Data for 3.3.b 
            productDO.HTM_timeLimitDays = 1; //AP16
        
            //calculation for Step 3.3.b
            if (productDO.HTM_timeLimitDays > 0){
               ESHT_calTimeLimitDays = productDO.HTM_timeLimitDays * 24; //Q31
            }else{
               ESHT_calTimeLimitDays = 0;
            }
            
            System.debug('(Q31) ESHT_calTimeLimitDays: ' + ESHT_calTimeLimitDays);
            
            productDO.HTM_temp2MaxC = 45; //AT16 and Q35
            productDO.HTM_temp2MaxF = 113;//AU16 and Q36
            
            productDO.HTM_Temp2TimeHours = 24; //AS16 and Q34
        
            //Step 4.0 
            productDO.HTM_MarketMaxHours = 24; // (HHT L16 and ESHT_Q19 totalHoursAllowed)
        
            //Step 7.0
            productDO.HTM_LabelMinC = 2; //(HHT E16) (ESHT_Q18)
            productDO.HTM_LabelMinF = 36; //(HHT F16) (ESHT_Q18)
            
            if(userUnitOfTemp == 'C'){
               ESHT_MinTempLimit = productDO.HTM_LabelMinC;
            }else{
               ESHT_MinTempLimit = productDO.HTM_LabelMinF;         
            }
        
            //Step 8 
            productDO.HTM_FootNote = '...some foot note...';  //(HHT J16) (ESHT Q20)
        
            //Step 9 
            productDO.HTM_Comment = '...some Comment...'; //(HHT AL16) (ESHT Q21)
  */      
            //Spool out the contents:
            productDO.spoolData();
    }
    
    /*
     *  Step 3.4.0 
     */
    private void calculateAdditionalEvaluation2(){
       
       //ESHT_tempMax2 ESHT $Q$25
       //ESHT_tempMax1 ESHT $Q$24

       //Calculate the Values for SS T19 - T58
       //=IF(AND(ROUND(C19,0)>$Q$24, ROUND(C19,0)<=$Q$25),D19,0)
       for(MSD_CORE_CalcTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){

          System.debug('KRB 24R3.0: cted.temp: ' + cted.temp); 
          System.debug('KRB 24R3.0: cted.temp.round() should = absoluteRoundDouble(cted.temp), except for -.5 numbers...');
          System.debug('KRB 24R3.0: cted.temp.round(): ' + cted.temp.round()); 
          System.debug('KRB 24R3.0: absoluteRoundDouble(cted.temp): ' + absoluteRoundDouble(cted.temp)); 

          //Out for 24R3.0
          //if((cted.temp.round() > ESHT_tempMax1) && (cted.temp.round()<= ESHT_tempMax2)){
          //In for 24R3.0
          if((absoluteRoundDouble(cted.temp) > ESHT_tempMax1) && (absoluteRoundDouble(cted.temp) <= ESHT_tempMax2)){
             cted.additionalEval2CalcUserEnteredExposureTimeHours = cted.hours;
             cted.additionalEval2CalcUserEnteredExposureTimeMins = cted.min;
             cted.additionalEval2CalcUserEnteredExposureTimeSeconds = cted.seconds;
          }else{
             cted.additionalEval2CalcUserEnteredExposureTimeHours = 0;
             cted.additionalEval2CalcUserEnteredExposureTimeMins = 0;
             cted.additionalEval2CalcUserEnteredExposureTimeSeconds = 0;
          }
 
       }
      
        //2. Calculate the totalUserEnteredExTime
        Double totalCalculatedHours = 0;
        Double totalCalculatedMinutes = 0;
        Double totalCalculatedSeconds = 0;
        
        for(MSD_CORE_CalcTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
            totalCalculatedHours = totalCalculatedHours + cted.additionalEval2CalcUserEnteredExposureTimeHours;
            totalCalculatedMinutes = totalCalculatedMinutes + cted.additionalEval2CalcUserEnteredExposureTimeMins;
        	totalCalculatedSeconds = totalCalculatedSeconds + cted.additionalEval2CalcUserEnteredExposureTimeSeconds;
        }
        
        ESHT_timeTotalSecondTime = totalCalculatedHours + (totalCalculatedMinutes/60) + (totalCalculatedSeconds/3600);              
        
        System.debug('Calculations for Step 4.0: ');
        System.debug('totalCalculatedHours:' + totalCalculatedHours);
        System.debug('totalCalculatedMinutes: ' + totalCalculatedMinutes);
        System.debug('totalCalculatedSeconds: ' + totalCalculatedSeconds);
        System.debug('(T18) ESHT_timeTotalSecondTime: ' + ESHT_timeTotalSecondTime);
        System.debug('(Q34) (Temp 2 time Hours)  productDO.HTM_Temp2TimeHours: ' +  productDO.HTM_Temp2TimeHours);
 
        //Calculate T14
        //ESHT_additionalEvaluation2
        if(ESHT_timeTotalSecondTime > productDO.HTM_Temp2TimeHours){ //T18 > Q34
          ESHT_additionalEvaluation2 = 'FAIL';    
        }else{
          ESHT_additionalEvaluation2 = '';  
        }
        
        System.debug('(T14) Additional Evaluation 2 (ESHT_additionalEvaluation2) : ' +  ESHT_additionalEvaluation2);

    }
    
    /*
     *  Step 3.1 Calulate rounded max user entered temp (C19:C58)
     *  input Params are the User entered Exposure Details, Temp and Time on a single Product. 
     *  Returned is a rounded Integer (No Decimals)
     */ 
    private void calculateRoundedMaxUserEnteredTempExposure(List<MSD_CORE_TempExcurExposDetail__c> userExposureDetailList ){
        Set<Double> userTempsSet = new Set<Double>();
        List<Double> userTempList = new  List<Double>();
                
        if ( userExposureDetailList == null || userExposureDetailList.isEmpty() ||  userExposureDetailList.size() == 0){
           System.debug('userExposureDetailList was empty...');
           roundedMaxUserEnteredTempExposure = 0;
        
        }else{
           
            for (MSD_CORE_TempExcurExposDetail__c uedl : userExposureDetailList){
              userTempsSet.add(uedl.MSD_CORE_Temp__c);
          
              userTempList = new List<Double>(userTempsSet);
              userTempList.sort();
        
              system.debug('Temps Sorted:'); 
              
              for (Double x : userTempList){ 
                  system.debug('aaa. userTempList: ' + x);
              }
            }
            
            Double maxUserEnteredTempExposure = userTempList[userTempList.size() - 1];
            System.debug('maxUserEnteredTempExposure: ' + maxUserEnteredTempExposure);
            
            //Out for 23R4.0
            //roundedMaxUserEnteredTempExposure = maxUserEnteredTempExposure.round();  
            //In for 23R4.0
            roundedMaxUserEnteredTempExposure = absoluteRoundDouble(maxUserEnteredTempExposure).longValue();
            
            System.debug('KRB 24R3.0: maxUserEnteredTempExposure.round() should = absoluteRoundDouble(maxUserEnteredTempExposure).longValue()');
            System.debug('KRB 24R3.0: except for -.5 numbers...');
            System.debug('KRB 24R3.0: maxUserEnteredTempExposure.round(): ' + maxUserEnteredTempExposure.round());
            System.debug('KRB 24R3.0: absoluteRoundDouble(maxUserEnteredTempExposure).longValue(): ' + absoluteRoundDouble(maxUserEnteredTempExposure).longValue());
            System.debug('KRB 24R3.0: roundedMaxUserEnteredTempExposure: ' + roundedMaxUserEnteredTempExposure);
            
            System.debug('roundedMaxUserEnteredTempExposure: ' + roundedMaxUserEnteredTempExposure);
       }
    }
    
    /*
     *  Calculation for Step 3.2 (Q16 - maxTempFinal)
     *  =IF(Q28=N, IF(C10=C, Q29,  Q30), Q25) 
     */
    private void calculateMaxTempFinal(){
        
        If(productDO.HTM_timeAllowance == 'N'){
            If(userUnitOfTemp == 'C'){
                ESHT_maxTempFinal = productDO.HTM_timeAllowanceC;
            } else{
               ESHT_maxTempFinal =  productDO.HTM_timeAllowanceF;
            }
        }else{
            ESHT_maxTempFinal = ESHT_tempMax2;
        }
        System.debug('(Q28): ESHT Time Allowance: (HHT AM16) productDO.HTM_timeAllowance)' + productDO.HTM_timeAllowance );
        System.debug('(Q16): ESHT Max Temp Final (ESHT_maxTempFinal): ' + ESHT_maxTempFinal);
    }

    /*
     *  Step 3.3.a.3 and .4
     */
    private void calculateTotalUserEnteredExTime(){
       //1. Calculate the "calculated" User Entered Exposure Time
       //IF(AND(ROUND(user Entered Exp Temp, 0)>maxTempLimit, ROUND(user Entered Exp Temp, 0)<tempMax1), user Entered Exp Temp, 0)
        for(MSD_CORE_CalcTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
                    
          System.debug('KRB 24R3.0: cted.temp: ' + cted.temp); 
          System.debug('KRB 24R3.0: cted.temp.round() should = absoluteRoundDouble(cted.temp), except for -.5 numbers...');
          System.debug('KRB 24R3.0: cted.temp.round(): ' + cted.temp.round()); 
          System.debug('KRB 24R3.0: absoluteRoundDouble(cted.temp): ' + absoluteRoundDouble(cted.temp)); 

            
            //Out for 24R3.0
            //if((cted.temp.round() > ESHT_MaxTempLimit) && (cted.temp.round()<= ESHT_tempMax1)){
            //In for 24R3.0
            if((absoluteRoundDouble(cted.temp) > ESHT_MaxTempLimit) && (absoluteRoundDouble(cted.temp) <= ESHT_tempMax1)){
                cted.calulatedUserEnteredexposureTimeHours = cted.hours;
                cted.calulatedUserEnteredexposureTimeMins = cted.min;
                cted.calulatedUserEnteredexposureTimeSeconds = cted.seconds;
            }else{
                cted.calulatedUserEnteredexposureTimeHours = 0;
                cted.calulatedUserEnteredexposureTimeMins = 0;
                cted.calulatedUserEnteredexposureTimeSeconds = 0;
            }
        }  
        
        //2. Calculate the totalUserEnteredExTime
        Double totalCalculatedHours = 0;
        Double totalCalculatedMinutes = 0;
        Double totalCalculatedSeconds = 0;
        
        for(MSD_CORE_CalcTempExcurExDetls cted: calculatedUserExposureDetailsEnteredList){
            totalCalculatedHours = totalCalculatedHours + cted.calulatedUserEnteredexposureTimeHours;
            totalCalculatedMinutes = totalCalculatedMinutes + cted.calulatedUserEnteredexposureTimeMins;
            totalCalculatedSeconds = totalCalculatedSeconds + cted.calulatedUserEnteredexposureTimeSeconds;
        }
        
        ESHT_totalUserEnteredExTime = totalCalculatedHours + (totalCalculatedMinutes/60) + (totalCalculatedSeconds/3600);              
        
        System.debug('Calculations for Step 3.3.a.3 and 4: ');
        System.debug('totalCalculatedHours:' + totalCalculatedHours);
        System.debug('totalCalculatedMinutes: ' + totalCalculatedMinutes);
        System.debug('totalCalculatedSeconds: ' + totalCalculatedSeconds);
        System.debug('(S18) ESHT_totalUserEnteredExTime: ' + ESHT_totalUserEnteredExTime);
        
   }
    
    
    /* 
     * Step 3.3.c
     * Calculate (S14) additionalEvaluation 
     * = IF(S18>Q31), "FAIL", ""
     */
    private void calculateAdditionalEvaluation(){
       
        if(ESHT_totalUserEnteredExTime > ESHT_calTimeLimitDays ){
           ESHT_additionalEvaluation = 'FAIL';  
        }else{
           ESHT_additionalEvaluation = ''; 
        }  
        
        System.debug('(S14) Additional Evaluation1 (ESHT_additionalEvaluation): ' + ESHT_additionalEvaluation);
    }

}