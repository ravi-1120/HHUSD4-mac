/*
    KRB 6/5/2020 - 20R3.0 Product Excursion Assessment Logic

    Trigger ensures that all the Data is correctly entered for use in 
    Excursion Assessments and also performs the logic for the necessary
    Calculated Fields. 

    1. Ensure that the following Fields are Populated for Low Temp Assessments. If not, fail the record insert/update

       MSD_CORE_LT_SpprtdLwMnC__c       public String LTT_SupportedLowMinC  = ''; //Supported Low Min C //C //Text and number 
       MSD_CORE_LT_SpprtdLwMnF__c        public String LTT_SupportedLowMinF  = ''; //Supported Low Min F //D //Text and number 
       MSD_CORE_LT_SpprtdLwMxC__c        public String LTT_SupportedLowMaxC = ''; //Supported Low Max C //E //Text and number
       MSD_CORE_LT_SpprtdLwMxF__c        public String LTT_SupportedLowMaxF = ''; //Supported Low Max F //F //Text and number
       MSD_CORE_LT_LblTmpRngMnC__c      public String LTT_LabeledTempRangeMinC = '';  //Labeled Temp Range Min C //G //Number - used only for Storage label
       MSD_CORE_LT_LblTmpRngMnF__c      public String LTT_LabeledTempRangeMinF  = ''; //Labeled Temp Range Min F //H //Number - used only for Storage label
       MSD_CORE_LT_LblTmpRngMxC__c       public String LTT_LabeledTempRangeMaxC  = ''; //Labeled Temp Range Max C //I //Number - used only for Storage label
       MSD_CORE_LT_LblTmpRngMxF__c     public String LTT_LabeledTempRangeMaxF  = ''; //Labeled Temp Range Max F //J //Number - used only for Storage label
       MSD_CORE_LT_Time__c                    public String LTT_Time = ''; //Time //K //Text and Number
       MSD_CORE_LT_UnitsOfTime__c        public String LTT_UnitsOfTime = ''; //Units of time //L //Text
       MSD_CORE_LT_NumOfHours__c      public String LTT_NumberOfHours = ''; //Number of hours //M //Text and Number
       MSD_CORE_LT_NumOfCycles__c      public String LTT_NumberOfCycles = ''; //Number of Cycles //N //Text and Number
       MSD_CORE_LT_SLblRngTmpMnC__c    public String LTT_SecondLabelRangeTempMinC = '';    //Second Label Range Temp Min C //O //Text and Number - used only for Storage label
       MSD_CORE_LT_SLblRngTmpMnF__c    public String LTT_SecondLabelRangeTempMinF = ''; //Second Label Range Temp Min F //P //Text and Number - used only for Storage label
       MSD_CORE_LT_SLblRngTmpMxC__c      public String LTT_SecondLabelRangeTempMaxC = ''; // Second Label Range Temp Max C //Q //Text and Number - used only for Storage label
       MSD_CORE_LT_SLblRngTmpMxF__c        public String LTT_SecondLabelRangeTempMaxF = '';  //Second Label Range Temp Max F //R //Text and Number - used only for Storage label
       MSD_CORE_LT_UnlimitedTime__c       public String LTT_UnlimitedTime = ''; //Hide if Number of Cycles N/A //S //Text
       MSD_CORE_LT_Comment__c           public String LTT_Comment = ''; //Comment //T //Text
       MSD_CORE_LT_Category __c     public Double LTT_Category = 0; //Category //U //Number

    2. Ensure that the correct Data is populated in the Following Fields:
        
    3. The Following Fields are calculated Fields:
        MSD_CORE_LT_NumOfHours__c
        MSD_CORE_LT_UnlimitedTime__c

    4. Make sure Product is not a duplicate!!??

*/

trigger MSD_CODE_Validate_ExcurAssessmentMetadata on MSD_CORE_ProdAsmntMetadata__c (before insert, before update) {
    
    //All following Logic needs to be checked for both insert and updates
    
    for(MSD_CORE_ProdAsmntMetadata__c rec: Trigger.new){
       //Low Temp Metadata Checks:
       //The Following Fields are calculated Fields:
        //MSD_CORE_LT_NumOfHours__c
        //MSD_CORE_LT_UnlimitedTime__c
        //
    
       String recordTypeNameStr = '';
        
        
       //Get the RecordType Dev Name
       recordTypeNameStr = Schema.SObjectType.MSD_CORE_ProdAsmntMetadata__c.getRecordTypeInfosById().get(rec.RecordTypeId).getDeveloperName();
       System.debug('Record Developer Name ====> '+ recordTypeNameStr);
 
       if (recordTypeNameStr == 'MSD_CORE_Low_Temp'){
                
           if(
                (String.isBlank(rec.MSD_CORE_Brand_Name__c) && String.isBlank(rec.MSD_CORE_Generic_Name__c)) ||
                 String.isBlank(rec.MSD_CORE_LT_LblTmpRngMnC__c) ||
                 String.isBlank(rec.MSD_CORE_LT_LblTmpRngMnF__c) ||
                 String.isBlank(rec.MSD_CORE_LT_LblTmpRngMxC__c) ||
                 String.isBlank(rec.MSD_CORE_LT_LblTmpRngMxF__c) ||
                 String.isBlank(rec.MSD_CORE_LT_NumOfCycles__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SLblRngTmpMnC__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SLblRngTmpMnF__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SLblRngTmpMxC__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SLblRngTmpMxF__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SpprtdLwMnC__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SpprtdLwMnF__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SpprtdLwMxC__c) ||
                 String.isBlank(rec.MSD_CORE_LT_SpprtdLwMxF__c) ||
                 String.isBlank(rec.MSD_CORE_LT_Time__c) ||
                 String.isBlank(rec.MSD_CORE_LT_UnitsOfTime__c) ||
                 String.isBlank(rec.MSD_CORE_Market__c)         
             ){
                 String errorStr = 'Insert failed. Missing one or more Required Fields: '; 
                 errorStr = errorStr + 'MSD_CORE_Brand_Name__c, MSD_CORE_Generic_Name__c, MSD_CORE_LT_LblTmpRngMnC__c, ';
                 errorStr = errorStr + 'MSD_CORE_LT_LblTmpRngMnF__c, MSD_CORE_LT_LblTmpRngMxC__c, MSD_CORE_LT_LblTmpRngMxF__c, ';
                 errorStr = errorStr + 'MSD_CORE_LT_NumOfCycles__c, MSD_CORE_LT_SLblRngTmpMnC__c, MSD_CORE_LT_SLblRngTmpMnF__c, ';             
                 errorStr = errorStr + 'MSD_CORE_LT_SLblRngTmpMxC__c, MSD_CORE_LT_SLblRngTmpMxF__c, MSD_CORE_LT_SpprtdLwMnC__c, ';             
                 errorStr = errorStr + 'MSD_CORE_LT_SpprtdLwMnF__c, MSD_CORE_LT_SpprtdLwMxC__c, MSD_CORE_LT_SpprtdLwMxF__c, ';             
                 errorStr = errorStr + 'MSD_CORE_LT_Time__c, MSD_CORE_LT_UnitsOfTime__c, MSD_CORE_Market__c ';             
                 
                 rec.addError(errorStr);
              }

              
             if(fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SpprtdLwMnC__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SpprtdLwMnF__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SpprtdLwMxC__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SpprtdLwMxF__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_NumOfCycles__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SLblRngTmpMnC__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SLblRngTmpMnF__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SLblRngTmpMxC__c) ||
                fieldNotInProperFormat_NumberOrNA(rec.MSD_CORE_LT_SLblRngTmpMxF__c)){

                String errorStr = 'Insert failed. Field not in proper format. Number or N/A:';
                errorStr = errorStr + 'MSD_CORE_LT_SpprtdLwMnC__c,MSD_CORE_LT_SpprtdLwMnF__c,MSD_CORE_LT_SpprtdLwMxC__c,';
                errorStr = errorStr + 'MSD_CORE_LT_SpprtdLwMxF__c,MSD_CORE_LT_NumOfCycles__c,MSD_CORE_LT_SLblRngTmpMnC__c,';
                errorStr = errorStr + 'MSD_CORE_LT_SLblRngTmpMnF__c,MSD_CORE_LT_SLblRngTmpMxC__c,MSD_CORE_LT_SLblRngTmpMxF__c.';
            
                rec.addError(errorStr);
             } 
              
             if(fieldNotInProperFormat_Number(rec.MSD_CORE_LT_LblTmpRngMnC__c) ||
                fieldNotInProperFormat_Number(rec.MSD_CORE_LT_LblTmpRngMnF__c) ||
                fieldNotInProperFormat_Number(rec.MSD_CORE_LT_LblTmpRngMxC__c) ||
                fieldNotInProperFormat_Number(rec.MSD_CORE_LT_LblTmpRngMxF__c)){
                
                String errorStr = 'Insert failed. Field not in proper format. Value not a Number.';
                errorStr = errorStr + 'MSD_CORE_LT_LblTmpRngMnC__c,MSD_CORE_LT_LblTmpRngMnF__c,MSD_CORE_LT_LblTmpRngMxC__c,MSD_CORE_LT_LblTmpRngMxF__c.';
                    
                rec.addError(errorStr);
             }
              
             //Units of Time has to be either D, M, or N/A.
             //22R3.1 8/9/2022 - Updated to new method with Hours "H"
             if(fieldNotInProperFormat_DorNAorMorH(rec.MSD_CORE_LT_UnitsOfTime__c)){
                 rec.addError('Insert failed. Units of Time has to be either H, D, M, or N/A.'); 
             }
              

             //Time has to be Unlimited, a number or N/A
             if(fieldNotInProperFormat_NumberOrNAOrUnlimited(rec.MSD_CORE_LT_Time__c)){
                 rec.addError('Insert failed. Time has to be either N/A, a Number or Unlimited.'); 
             }
                
             //if Time is a Number, units of Time has to be either M or D
             //22R3.1 - 8/9/2022 added Hours "H" as a valid value
             if(thisStringIsANumber(rec.MSD_CORE_LT_Time__c)){
                 if(rec.MSD_CORE_LT_UnitsOfTime__c != 'D' && rec.MSD_CORE_LT_UnitsOfTime__c != 'M' && rec.MSD_CORE_LT_UnitsOfTime__c != 'H' ){
                    rec.addError('Insert failed. Units of Time has to be H, D or M because Time is a Number.'); 
                 }   
             }
              
              
             //Calculated Field Logic: 
             //Number of Hours
             // if Time = Unlimited, Number of Hours has to = Unlimited
             // if Units of Time = D, Time has to be a number and Number of Hours = time *24
             // if units of Time = M, Time has to be a number and Number of Hours = time * 24 * 30
             if(String.isNotBlank(rec.MSD_CORE_LT_Time__c) 
               && String.isNotBlank(rec.MSD_CORE_LT_UnitsOfTime__c)){
               if (rec.MSD_CORE_LT_Time__c == 'Unlimited'){
                  rec.MSD_CORE_LT_NumOfHours__c = 'Unlimited';
               }else if (rec.MSD_CORE_LT_UnitsOfTime__c == 'D'){ 
                  if(thisStringIsANumber(rec.MSD_CORE_LT_Time__c)){
                    Double x =  Double.valueOf(rec.MSD_CORE_LT_Time__c); 
                    Double NumOfHours = x * 24;
                    rec.MSD_CORE_LT_NumOfHours__c = String.valueOf(NumOfHours); 
                  }else{
                    rec.addError('Insert failed. Time has to a number in order to do the Number of hours Calculation.'); 
                  }
               }else if (rec.MSD_CORE_LT_UnitsOfTime__c == 'M'){
                  if(thisStringIsANumber(rec.MSD_CORE_LT_Time__c)){
                     Double x =  Double.valueOf(rec.MSD_CORE_LT_Time__c); 
                     Double NumOfHours = x * 24 * 30; 
                     rec.MSD_CORE_LT_NumOfHours__c = String.valueOf(NumOfHours);                      
                  }else{
                     rec.addError('Insert failed. Time has to a number in order to do the Number of hours Calculation.'); 
                  }  
               }else{ 
                 rec.MSD_CORE_LT_NumOfHours__c =  rec.MSD_CORE_LT_Time__c;
               }
             } 
              
              
             //Calculate "Hide if Number of Cycles N/A" (MSD_CORE_LT_UnlimitedTime__c)
             // If Number of Cycles = N/A AND Number of Hours = Unlimited, field Value = YES, else NO    
             if ((rec.MSD_CORE_LT_NumOfCycles__c == 'N/A') && (rec.MSD_CORE_LT_NumOfHours__c == 'Unlimited')){
                rec.MSD_CORE_LT_Unlimited_Time__c = 'YES';  
             }else{
                rec.MSD_CORE_LT_Unlimited_Time__c  = 'No'; 
             }
               
              
          }else if (recordTypeNameStr == 'MSD_CORE_High_Temp'){ 
              
              //1. Make sure all the neccessary fields are populated
              /*
                MSD_CORE_HT_TimeAllowance__c
                MSD_CORE_HT_TimeAllowanceC__c
                MSD_CORE_HT_TimeAllowanceF__c
                MSD_CORE_HT_Temp2MaxC__c 
                MSD_CORE_HT_Temp2MaxF__c
                MSD_CORE_HT_LabelMaxC__c
                MSD_CORE_HT_LabelMaxF__c
                MSD_CORE_HT_TempC__c
                MSD_CORE_HT_TempF__c
                MSD_CORE_HT_TimeLimitDays__c
                MSD_CORE_HT_Temp2TimeHours__c
                MSD_CORE_HT_LabelMinC__c
                MSD_CORE_HT_LabelMinF__c
                MSD_CORE_HT_MarketMaxHours__c
               */ 
                
             if(String.isBlank(rec.MSD_CORE_HT_TimeAllowance__c) || rec.MSD_CORE_HT_TimeAllowanceC__c == NULL ||
                 rec.MSD_CORE_HT_TimeAllowanceF__c == NULL || rec.MSD_CORE_HT_Temp2MaxC__c == NULL || 
                 rec.MSD_CORE_HT_Temp2MaxF__c == NULL || rec.MSD_CORE_HT_LabelMaxC__c == NULL ||
                 rec.MSD_CORE_HT_LabelMaxF__c == NULL || rec.MSD_CORE_HT_TempC__c == NULL ||
                 rec.MSD_CORE_HT_TempF__c ==NULL || rec.MSD_CORE_HT_TimeLimitDays__c == NULL ||
                 rec.MSD_CORE_HT_Temp2TimeHours__c == NULL || rec.MSD_CORE_HT_LabelMinC__c == NULL ||
                 rec.MSD_CORE_HT_LabelMinF__c == NULL || rec.MSD_CORE_HT_MarketMaxHours__c == NULL){
 
                    String errorMessage =  'Insert failed. One of the following fields is NULL: ';
                    errorMessage = errorMessage + 'MSD_CORE_HT_TimeAllowance__c,MSD_CORE_HT_TimeAllowanceC__c,MSD_CORE_HT_TimeAllowanceF__c, '; 
                    errorMessage = errorMessage + 'MSD_CORE_HT_Temp2MaxC__c,MSD_CORE_HT_Temp2MaxF__c,MSD_CORE_HT_LabelMaxC__c,'; 
                    errorMessage = errorMessage + 'MSD_CORE_HT_LabelMaxF__c,MSD_CORE_HT_TempC__c,MSD_CORE_HT_TempF__c,MSD_CORE_HT_TimeLimitDays__c,'; 
                    errorMessage = errorMessage + 'MSD_CORE_HT_Temp2TimeHours__c,MSD_CORE_HT_LabelMinC__c,MSD_CORE_HT_LabelMinF__c,MSD_CORE_HT_MarketMaxHours__c '; 
                    rec.addError(errorMessage); 
                  
              }
              
              //2. Validate data.
              if (String.isNotBlank(rec.MSD_CORE_HT_TimeAllowance__c)){
                  if(rec.MSD_CORE_HT_TimeAllowance__c != 'Y' && rec.MSD_CORE_HT_TimeAllowance__c != 'N' ){
                     rec.addError('MSD_CORE_HT_TimeAllowance__c must be either a Y or a N'); 
                      
                  }  
              } 

          }else if (recordTypeNameStr == 'MSD_CORE_Frozen'){ 
              if(String.isBlank(rec.MSD_CORE_Brand_Name__c)){   
                     rec.addError('Brand Name must be populated.'); 
              }  

          }else{
              rec.addError('Insert failed. Not a supported Record Type. '); 
          }
           
           
      }


    //Field has to be D, M or N/A, else fail it.
    //KRB 22R3.1 8/9/2022 - updated to add Hours "H" 
    private boolean fieldNotInProperFormat_DorNAorMorH(String fieldValue){
        
        boolean fail = false;
        
        if((fieldValue != 'N/A') && (fieldValue != 'D') && (fieldValue != 'M') && (fieldValue != 'H')){
               fail = true;
        }
        
        return fail;
    }

    //Validate if field is a Number, if not, make sure it has a value of N/A or Unlimited, else fail it. 
    private boolean fieldNotInProperFormat_NumberOrNAOrUnlimited(String fieldValue){

        boolean fail;
        
        try{
           Double aNum = Double.valueOf(fieldValue) ; 
           fail = false;
        }catch(Exception ex){
            if((fieldValue != 'N/A') && (fieldValue != 'Unlimited')){
               fail = true;
            }else{
               fail = false; 
            }
        }
        
        return fail;
    }
    
    //Validate if field is a Number, if not, make sure it has a value of N/A, else fail it. 
    private boolean fieldNotInProperFormat_NumberOrNA(String fieldValue){
        
        boolean fail;
        
        try{
           Double aNum = Double.valueOf(fieldValue) ; 
           fail = false;
        }catch(Exception ex){
            if(fieldValue != 'N/A'){
               fail = true;
            }else{
               fail = false; 
            }
        }
        
        return fail;
    }
    
    //Validate if field is a Number, else fail it. 
    private boolean fieldNotInProperFormat_Number(String fieldValue){
        
        boolean fail;
        
        try{
           Double aNum = Double.valueOf(fieldValue) ; 
           fail = false;
        }catch(Exception ex){
           fail = true;
        }
        
        return fail;
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

    
}