/*
  Kevin R. Brace 20R3.0 
  creates a Cumulative Hour:Minute:Seconds string given a List of MSD_CORE_TempExcurExposDetail__c Records.

  Testing:
     MSD_CORE_TempExcurExposDetail__c x = new MSD_CORE_TempExcurExposDetail__c();
     x.MSD_CORE_Min__c = 0;
     x.MSD_CORE_Seconds__c = 59;
     x.MSD_CORE_hours__c = 0;

     MSD_CORE_TempExcurExposDetail__c x1 = new MSD_CORE_TempExcurExposDetail__c();
     x1.MSD_CORE_Min__c = 0;
     x1.MSD_CORE_Seconds__c = 1;
     x1.MSD_CORE_hours__c = 1;

     List <MSD_CORE_TempExcurExposDetail__c> detailList = new List <MSD_CORE_TempExcurExposDetail__c>();
     detailList.add(x);
     detailList.add(x1);

     MSD_CORE_CalcCumulativeExcurTime ct = new MSD_CORE_CalcCumulativeExcurTime();
     ct.calculateCumulativeExposureTime(detailList);

*/
//List<MSD_CORE_TempExcurExposDetail__c> exposureList
global with sharing class MSD_CORE_CalcCumulativeExcurTime {
    
    @InvocableMethod
    public static List<Results> calculateCumulativeExposureTime(List<Requests> requests){
        String timeString = '';
        Double minutes = 0;
        Double seconds = 0;
        Double hours = 0;
        Double calcHours = 0;
        Double calcMinutes = 0;
        Double calcSeconds = 0;

        
        List <MSD_CORE_TempExcurExposDetail__c> exposureList = requests[0].exposureList;
        
        for(MSD_CORE_TempExcurExposDetail__c exposure : exposureList){
            minutes = minutes + exposure.MSD_CORE_Min__c;
            seconds = seconds + exposure.MSD_CORE_Seconds__c;
            hours   = hours   + exposure.MSD_CORE_hours__c;
        }
        
        //Get total Seconds, easier to work with. 
        seconds = seconds + (minutes * 60);
        seconds = seconds + (hours * 3600);
        
        //Calculate the String:
        calcHours = Math.floor(seconds/3600);
        calcMinutes = Math.floor(Math.mod(Integer.valueOf(seconds), 3600)/60);
        calcSeconds = Math.mod(Math.mod(Integer.valueOf(seconds),3600),60);
        
        System.debug('calcHours: ' + calcHours);
        System.debug('calcMinutes: ' + calcMinutes);
        System.debug('calcSeconds: ' + calcSeconds);
        
        if (Integer.valueOf(calcHours) == 1){
           timeString = Integer.valueOf(calcHours) + ' Hour '; 
        }else{
           timeString = Integer.valueOf(calcHours) + ' Hours '; 
        }

        if (Integer.valueOf(calcMinutes) == 1){
           timeString = timeString + Integer.valueOf(calcMinutes) + ' Minute '; 
        }else{
           timeString = timeString + Integer.valueOf(calcMinutes) + ' Minutes ';
        }
        
        if (Integer.valueOf(calcSeconds) == 1){
           timeString = timeString + Integer.valueOf(calcSeconds) + ' Second '; 
        }else{
           timeString = timeString + Integer.valueOf(calcSeconds) + ' Seconds '; 
        }
        
        System.debug('timeString: ' + timeString);

        /*
        IF(
        ISBLANK(Seconds__c),"",
        TEXT(FLOOR(Seconds__c/3600)) + ":" + TEXT( FLOOR(MOD(Seconds__c,3600)/60)) + ":" + TEXT(MOD(MOD(Seconds__c,3600),60)))
        */
        
        //return timeString;
        Results curResults = new Results();
        curResults.cumulativeTimeString =  timeString;
                  
        List<Results> resultsList = new List<results>();
        resultsList.add(curResults);
        return resultsList;

    }
    
    global class Requests{
                
        @InvocableVariable
        global List <MSD_CORE_TempExcurExposDetail__c> exposureList;
        
    }
    
    global class Results{
        
        @InvocableVariable
        global String cumulativeTimeString = '';

    }
    

}