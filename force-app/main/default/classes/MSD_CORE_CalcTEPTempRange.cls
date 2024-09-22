/*
KRB 9/2/2020 - Assessments - calculates the Temp Range String on the Temp Excursion Product Record. 
KRB 3/31/2022 - 22R2.0 (updated for CEF2F-15098) increased the Temp Range by 1 degree 
				for Low and High Temp Excursions

KRB 8/18/2022 - 22R4.0 made the follow changes to Ranges:
						
						"BELOW 2°C Bucket": <= 1.4C
						"2°C to 8°C Bucket": >= 1.5C and <= 8.4C
						"ABOVE 9°C Bucket": >= 8.5C

						"BELOW 36°F Bucket": <= 35.4F
						"36°F to 46°F Bucket": >= 35.5F and <= 46.4F
						"ABOVE 47°F Bucket": >= 46.5F

KRB 11/15/2022 - 23R1.0 made the following changes to all MMRII ranges (High and Low)
	Prior Ranges for High and Low Temp:

	Fahrenheit
	> 46                         : ABOVE 46F
	< -58                        : BELOW -58F
	>= -58 && <= 46              : -58F – +46F

	Celsius
	> 8                       	: ABOVE 8C
	< -50                    	: BELOW -50C
	>= -50 && <= 8 				: -50C – +8C

	New Buckets for MMRII for 23R1.0 Release:

	Fahrenheit
	>= 46.50                    : ABOVE 47F
	< -58                       : BELOW -58F
	>= -58 && <= 46.49         	: -58F – +46F

	Celsius

	>= 8.50                     : ABOVE 9C
	< -50                       : BELOW -50C
	>= -50 && <= 8.49           : -50C – +8C

  KRB 23R1.0 1-17-2023 New Temperature Buckets for refrigerated vaccines
    For refrigerated vaccines, the following entered ranges should display as noted below in the Most Recent Temp field:
    Entered ranges for 1.41C to 1.49C and 35.41F to 35.49F should be displayed in the Most Recent Temp field as “Below 2C” and “Below 36F”.
    Entered ranges for 8.41C to 8.49C and 46.41F to 46.49F should be displayed correctly in the Most Recent Temp field as “2C to 8C” and “36F to 46F”.
*/


global with sharing class MSD_CORE_CalcTEPTempRange {
    
    @InvocableMethod
    public static List<Results> calculateCumulativeExposureTime(List<Requests> requests){

       List <String> currentExcursionsOverFlow = new List <String>();
       List <String> currentExcursions = new List <String>();

       String assmntType = '';
       String tempUnit = '';
       Double RoomTempFrozen = 0;
       Double RefrigeratedTempFrozen = 0;
       
       Integer hours = 0;
       Integer minutes = 0;
       Integer seconds = 0;
       String assessmentProduct = '';
        
       Results curResults = new Results();
       curResults.tempRangeTimeString = '';
        
       //for labels:
       String hoursLabel = 'hours';
       String minutesLabel = 'minutes';
       String secondsLabel = 'seconds';

       List <MSD_CORE_TempExcurExposDetail__c> exposureList = new List <MSD_CORE_TempExcurExposDetail__c>();
 
       exposureList = requests[0].exposureList;
       assmntType = requests[0].assessmentType;
       tempUnit = requests[0].temperatureUnit;
         
        RoomTempFrozen = requests[0].frozenRmTemp;
        RefrigeratedTempFrozen = requests[0].frozenRefrigTemp;
        assessmentProduct = requests[0].product;
        
       //Format that Range String needs to be in: 
       /*
 
       FROZEN
       Frozen:
          15°F to 47°F (42F) for 7 hours and 3 minutes
          -9°C to 9°C (4C) for 7 hours and 3 minutes
       Frozen in Recommended Range:
          -58°F to 5°F (-20F) for 5 hours and 30 minutes
          -50°C to -15°C (-20C) for 5 hours and 30 minutes
      */
        
      //Processing Logic:
        if(assmntType == 'LowTemp'){

           if(tempUnit == 'F'){
              
                if(assessmentProduct.contains('M-M-R-II')){
               
                     for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){

                          hoursLabel = 'hours';
                          minutesLabel = 'minutes';
                          secondsLabel = 'seconds';
                  
                          hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                          minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                          seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                                   
                          if(exposure.MSD_CORE_hours__c == 1){
                              hoursLabel = 'hour';     
                          }
                          if(exposure.MSD_CORE_Min__c == 1){
                             minutesLabel = 'minute';     
                          }
                          if(exposure.MSD_CORE_Seconds__c == 1){
                             secondsLabel = 'second';     
                          }
                 
                          if(exposure.MSD_CORE_Temp__c >= 46.50){
                             currentExcursions.add('ABOVE 47F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                          }else if (exposure.MSD_CORE_Temp__c < -58){
                             currentExcursions.add('BELOW -58F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                          }else if (exposure.MSD_CORE_Temp__c >= -58 && exposure.MSD_CORE_Temp__c <= 46.49){
                             currentExcursions.add('-58F – +46F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                          }
                 
                     }
               
               
              }else{ //not MMR Product

                 for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){

                    hoursLabel = 'hours';
                    minutesLabel = 'minutes';
                    secondsLabel = 'seconds';
                  
                    hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                    minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                    seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                                   
                    if(exposure.MSD_CORE_hours__c == 1){
                       hoursLabel = 'hour';     
                    }
                    if(exposure.MSD_CORE_Min__c == 1){
                       minutesLabel = 'minute';     
                    }
                    if(exposure.MSD_CORE_Seconds__c == 1){
                       secondsLabel = 'second';     
                    }
                 
                    if(exposure.MSD_CORE_Temp__c <= 35.49){
                       currentExcursions.add('BELOW 36°F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel); 
                    }else if (exposure.MSD_CORE_Temp__c >= 35.5 && exposure.MSD_CORE_Temp__c <= 46.49){
                        currentExcursions.add('36°F to 46°F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }
                 
                 }

              } 
               
           }else if(tempUnit == 'C'){
               
              if(assessmentProduct.contains('M-M-R-II')){
 
                   for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
                        
                        hoursLabel = 'hours';
                        minutesLabel = 'minutes';
                        secondsLabel = 'seconds';
                  
                        hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                        minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                        seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                  
                        if(exposure.MSD_CORE_hours__c == 1){
                           hoursLabel = 'hour';     
                        }
                        if(exposure.MSD_CORE_Min__c == 1){
                           minutesLabel = 'minute';     
                        }
                        if(exposure.MSD_CORE_Seconds__c == 1){
                           secondsLabel = 'second';     
                        }
                 
                        if(exposure.MSD_CORE_Temp__c >= 8.50){
                           currentExcursions.add('ABOVE 9C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                        }else if(exposure.MSD_CORE_Temp__c < -50){
                           currentExcursions.add('BELOW -50C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                        }else if (exposure.MSD_CORE_Temp__c >= -50 && exposure.MSD_CORE_Temp__c <= 8.49){
                           currentExcursions.add('-50C – +8C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                        }
                 

                }//for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
           
             }else{//not MMR Product

                 for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){

                    hoursLabel = 'hours';
                    minutesLabel = 'minutes';
                    secondsLabel = 'seconds';
                  
                    hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                    minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                    seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                  
                    if(exposure.MSD_CORE_hours__c == 1){
                       hoursLabel = 'hour';     
                    }
                    if(exposure.MSD_CORE_Min__c == 1){
                       minutesLabel = 'minute';     
                    }
                    if(exposure.MSD_CORE_Seconds__c == 1){
                       secondsLabel = 'second';     
                    }
                 
                    if(exposure.MSD_CORE_Temp__c <= 1.49){
                       currentExcursions.add('BELOW 2°C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }else if (exposure.MSD_CORE_Temp__c >= 1.5 && exposure.MSD_CORE_Temp__c <= 8.49){
                       currentExcursions.add('2°C to 8°C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }
                 

                }//for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
  
             }// }else{//not MMR Product
           
           }//}else if(tempUnit == 'C'){
            

        //*************** High Temp *******************************************************

        }else if(assmntType == 'HighTemp'){
            
           if(tempUnit == 'F'){
               
              if(assessmentProduct.contains('M-M-R-II')){

                 for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
                 
                    hoursLabel = 'hours';
                    minutesLabel = 'minutes';
                    secondsLabel = 'seconds';

                    hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                    minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                    seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                  
                    if(exposure.MSD_CORE_hours__c == 1){
                      hoursLabel = 'hour';     
                    }
                    if(exposure.MSD_CORE_Min__c == 1){
                       minutesLabel = 'minute';     
                    }
                    if(exposure.MSD_CORE_Seconds__c == 1){
                       secondsLabel = 'second';     
                    }
                 
                     if(exposure.MSD_CORE_Temp__c >= 46.50){
                        currentExcursions.add('ABOVE 47F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                     }else if (exposure.MSD_CORE_Temp__c < -58){
                        currentExcursions.add('BELOW -58F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                     }else if (exposure.MSD_CORE_Temp__c >= -58 && exposure.MSD_CORE_Temp__c <= 46.49){
                        currentExcursions.add('-58F – +46F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);

                     }

                 }
              
              }else{ // not MMR Product
                 
                  for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
                 
                    hoursLabel = 'hours';
                    minutesLabel = 'minutes';
                    secondsLabel = 'seconds';

                    hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                    minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                    seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                  
                    if(exposure.MSD_CORE_hours__c == 1){
                      hoursLabel = 'hour';     
                    }
                    if(exposure.MSD_CORE_Min__c == 1){
                       minutesLabel = 'minute';     
                    }
                    if(exposure.MSD_CORE_Seconds__c == 1){
                       secondsLabel = 'second';     
                    }
                 
                    if(exposure.MSD_CORE_Temp__c >= 46.5){
                       currentExcursions.add('ABOVE 47°F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }else if (exposure.MSD_CORE_Temp__c >= 35.5 && exposure.MSD_CORE_Temp__c <= 46.49){
                       currentExcursions.add('36°F to 46°F (' + exposure.MSD_CORE_Temp__c + 'F) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }
                 }
                      
                      
              }
              
           }else if(tempUnit == 'C'){
              
              if(assessmentProduct.contains('M-M-R-II')){

                   for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
                        
                        hoursLabel = 'hours';
                        minutesLabel = 'minutes';
                        secondsLabel = 'seconds';
                  
                        hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                        minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                        seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                  
                        if(exposure.MSD_CORE_hours__c == 1){
                           hoursLabel = 'hour';     
                        }
                        if(exposure.MSD_CORE_Min__c == 1){
                           minutesLabel = 'minute';     
                        }
                        if(exposure.MSD_CORE_Seconds__c == 1){
                           secondsLabel = 'second';     
                        }
                 
                        if(exposure.MSD_CORE_Temp__c >= 8.50){
                           currentExcursions.add('ABOVE 9C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                        }else if(exposure.MSD_CORE_Temp__c < -50){
                           currentExcursions.add('BELOW -50C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                        }else if (exposure.MSD_CORE_Temp__c >= -50 && exposure.MSD_CORE_Temp__c <= 8.49){
                           currentExcursions.add('-50C – +8C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                        }
                 

                }//for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
           
              }else{//Not MMR Product

                 for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
                 
                    hoursLabel = 'hours';
                    minutesLabel = 'minutes';
                    secondsLabel = 'seconds';
                  
                    hours = Integer.valueOf(exposure.MSD_CORE_hours__c);
                    minutes = Integer.valueOf(exposure.MSD_CORE_Min__c);
                    seconds = Integer.valueOf(exposure.MSD_CORE_Seconds__c); 
                  
                    if(exposure.MSD_CORE_hours__c == 1){
                       hoursLabel = 'hour';     
                    }
                    if(exposure.MSD_CORE_Min__c == 1){
                       minutesLabel = 'minute';     
                    }
                    if(exposure.MSD_CORE_Seconds__c == 1){
                       secondsLabel = 'second';     
                    }
                 
                    if(exposure.MSD_CORE_Temp__c >= 8.5){
                       currentExcursions.add('ABOVE 9°C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }else if (exposure.MSD_CORE_Temp__c >= 1.5 && exposure.MSD_CORE_Temp__c <= 8.49){
                       currentExcursions.add('2°C to 8°C (' + exposure.MSD_CORE_Temp__c + 'C) for ' + hours + ' ' + hoursLabel + ' ' + minutes + ' ' + minutesLabel + ' and ' + seconds + ' ' + secondsLabel);
                    }
                 }                  
                  
              }
              
           }

        }else if(assmntType == 'Frozen'){
            
        /*    
           Refrigeration Range 
           14°F to 46°F for hours, minutes, seconds
           (-10°C to 8°C) for hours, minutes, seconds
 
           Room Temperature Range 
           47°F to 77°F for hours, minutes, seconds
           9°C to 25°C for hours, minutes, seconds  

        */    
           if(tempUnit == 'F'){
               
               if(requests[0].frozenRmTemp <> 0){
                   currentExcursions.add('47°F to 77°F for '+ requests[0].frozenRmTemp.intValue() +' hours');
               }
               if(requests[0].frozenRefrigTemp <> 0){
                   currentExcursions.add('14°F to 46°F for '+ requests[0].frozenRefrigTemp.intValue() +' hours');
               }
               
               //KRB 5/2023 23R3.0
               
               if((requests[0].frozenUnlimited != null) && (requests[0].frozenUnlimited <> 0)){
                   currentExcursions.add('6°F to 14°F for '+ requests[0].frozenUnlimited.intValue() +' hours'); 
               }
               if((requests[0].frozenWarmer != null) && (requests[0].frozenWarmer <> 0)){
                   currentExcursions.add('78°F or warmer for '+ requests[0].frozenWarmer.intValue() +' hours'); 
               }
               if((requests[0].frozenColder != null) && (requests[0].frozenColder <> 0)){
                   currentExcursions.add('-59°F or colder for '+ requests[0].frozenColder.intValue() +' hours'); 
               }
               
               
           }else if(tempUnit == 'C'){
               
               if(requests[0].frozenRmTemp <> 0){
                   currentExcursions.add('9°C to 25°C for '+ requests[0].frozenRmTemp.intValue() +' hours');
               }
               if(requests[0].frozenRefrigTemp <> 0){
                   currentExcursions.add('-10°C to 8°C for '+ requests[0].frozenRefrigTemp.intValue() +' hours');
               }
               
               //KRB 5/2023 23R3.0
               
               if((requests[0].frozenUnlimited != null) && (requests[0].frozenUnlimited <> 0)){
                   currentExcursions.add('-14°C to -10°C for '+ requests[0].frozenUnlimited.intValue() +' hours'); 
               }
               if((requests[0].frozenWarmer != null) && (requests[0].frozenWarmer <> 0)){
                   currentExcursions.add('26°C or warmer for '+ requests[0].frozenWarmer.intValue() +' hours'); 
               }
               if((requests[0].frozenColder != null) && (requests[0].frozenColder <> 0)){
                   currentExcursions.add('-51°C or colder for '+ requests[0].frozenColder.intValue() +' hours'); 
               }
               
               
           } 
           
        }
        
        
        if(!currentExcursions.isEmpty()){
            
            //if(currentExcursions.size() <= 4){
            if((currentExcursions.size() <= 4) || (assmntType == 'Frozen')){ //KRB 23R3.0 5/2023 added Frozen Condition
               
                for(String excurString : currentExcursions){
                    
                    if(String.isBlank(curResults.tempRangeTimeString)){
                       curResults.tempRangeTimeString = excurString;
                    }else{
                       curResults.tempRangeTimeString = curResults.tempRangeTimeString + '; ' + excurString; 
                    }
                }
                
            }else{
                Integer ctr = 0;
                for(String excurString : currentExcursions){
                    
                    if(ctr < 4){
                        
                       if(String.isBlank(curResults.tempRangeTimeString)){
                          curResults.tempRangeTimeString = excurString;
                       }else{
                          curResults.tempRangeTimeString = curResults.tempRangeTimeString + '; ' + excurString; 
                       }
                       
                       ctr = ctr + 1;
                    }else{
                       currentExcursionsOverFlow.add(excurString);
                    }
                        
                }
            }
        }

        if(!currentExcursionsOverFlow.isEmpty()){
            curResults.overFlowExcursionsList = currentExcursionsOverFlow;
        }
        
        List<Results> resultsList = new List<results>();
        resultsList.add(curResults);
        return resultsList;

    }
    
    global class Requests{
                
        @InvocableVariable
        global List <MSD_CORE_TempExcurExposDetail__c> exposureList;
        @InvocableVariable
        global String temperatureUnit;
        @InvocableVariable
        global String assessmentType;
        @InvocableVariable
        global Double frozenRmTemp;
        @InvocableVariable
        global Double frozenRefrigTemp;
        @InvocableVariable
        global String product;
        
        //KRB 23R3.0
        @InvocableVariable
        global Double frozenUnlimited;
        @InvocableVariable
        global Double frozenWarmer; 
        @InvocableVariable
        global Double frozenColder; 
        
    }
    
    global class Results{
        
        @InvocableVariable
        global String tempRangeTimeString = '';
        
        @InvocableVariable
        global List <String> overFlowExcursionsList;

    }
    

}