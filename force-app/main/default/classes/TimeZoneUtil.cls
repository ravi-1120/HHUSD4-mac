public class TimeZoneUtil { 
    
    @AuraEnabled
    public static List<Object> generateTimeSlots(Map<String,Object> scheduleDetails) {
        List<Object> timeSlotsAvaliable = new List<Object> ();
        try{
            // startTime = startTime.setTimeZone(timeZone);
            //  endTime = endTime.setTimeZone(timeZone);
            String timeZone = String.valueOf(scheduleDetails.get('timeZone'));
            Integer y = Integer.valueOf(scheduleDetails.get('year'));
            Integer m = Integer.valueOf(scheduleDetails.get('month'));
            Integer d = Integer.valueOf(scheduleDetails.get('date'));
            Integer sh = Integer.valueOf(scheduleDetails.get('startHours'));
            Integer sm = Integer.valueOf(scheduleDetails.get('startMinutes'));
            Integer ss = Integer.valueOf(scheduleDetails.get('startSeconds'));
            Integer eh = Integer.valueOf(scheduleDetails.get('endHours'));
            Integer em = Integer.valueOf(scheduleDetails.get('endMinutes'));
            Integer es = Integer.valueOf(scheduleDetails.get('endSeconds'));
            DateTime startTime = DateTime.newInstance(y, m, d, sh, sm, ss);
            DateTime endTime = DateTime.newInstance(y, m, d, eh, em, es);
            
            List<Object> timeSlotsObjLst = new List<Object>();
            
            DateTime currentTime = startTime;
            System.debug('currentTime str-->'+String.valueOf(currentTime));
            while (currentTime < endTime) {
                String tmpCurrTime = String.valueOf(currentTime);
                tmpCurrTime = tmpCurrTime.replaceAll(' ','T');
                tmpCurrTime = tmpCurrTime + '-05:00';
                Map<String,Object> timeSlotsObj = new Map<String,Object> ();
                timeSlotsObj = getGMTTimeValue(tmpCurrTime,timeZone);
                if(!(timeSlotsObj.isEmpty())){
                	timeSlotsObjLst.add(timeSlotsObj);
                }
                currentTime = currentTime.addMinutes(15);
            }
            System.debug('timeSlotsObjLst-> '+timeSlotsObjLst);
            timeSlotsAvaliable = getTimeSlots(String.valueOf(scheduleDetails.get('schedulingGroup')),String.valueOf(scheduleDetails.get('selectedDate')),timeSlotsObjLst);
            System.debug('timeSlotsAvaliable-> '+timeSlotsAvaliable);
        }catch(Exception ex){ 
            System.debug('ex-->'+ex);
        }
        return timeSlotsAvaliable;
    }

    @AuraEnabled
    public static Map<String,Object> getGMTTimeValue(String dt,String timeZone){
        Map<String,Object> timeSlotMap;
        String datetimeStr = dt;
        // String timeValue = datetimeStr;
        System.debug('=======datetimeStr=' + datetimeStr);
        Datetime datetimeGMT = (Datetime)Json.deserialize('"' + datetimeStr + '"', Datetime.class);
        System.debug('=======datetimeGMT=' + datetimeGMT);
        system.debug('after-->'+datetimeGMT.hourGmt()+':'+datetimeGMT.minuteGmt()+':'+datetimeGMT.secondGmt());
        System.debug('time->'+datetimeGMT.timeGmt());
        String timeGMT = string.valueOf(datetimeGMT.timeGmt()).SubStringBefore('.');
        System.debug('time->'+timeGMT);
        String currTimeLabel = datetimeGMT.format('h:mm a', timeZone);

        // String datetimeISTStr = datetimeGMT.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'IST');
        // System.debug('=======datetimeISTStr=' + datetimeISTStr);
        // String strConvertedDate = datetimeGMT.format('MM/dd/yyyy HH:mm:ss', 'America/New_York');
        // System.debug('strConvertedDate'+strConvertedDate);
        // String convertedLabel = datetimeGMT.format('h:mm a', 'Asia/Calcutta');
        // system.debug('convertedLabel --> '+ convertedLabel);
        // system.debug('ist --> '+ datetimeGMT.format('h:mm a', 'IST'));
        // system.debug('est --> '+ datetimeGMT.format('h:mm a', 'EST'));
        //String tempDt = dt.SubStringBefore('T');
        //date dtValue = date.valueOf(tempDt);
        //date formatedDt = date.valueOf(datetimeGMT.format('yyyy-MM-dd HH:mm:ss', timeZone));
        //System.debug('dtValue--> '+dtValue);
        //System.debug('formatedDt--> '+formatedDt);
        // if(!(dtValue<formatedDt)){
            timeSlotMap = new Map<String,Object> {'label'=>currTimeLabel, 'value'=>timeGMT, 'timeSlotAvialable' => true};
		//	}
       // else{
           // timeSlotMap = new Map<String,Object> ();
       // }
        System.debug('TimeSlotMap-> '+timeSlotMap);
        return timeSlotMap;   
    }

    @AuraEnabled
    public static List<Object> getTimeSlots(String schedulingGroup, String scheduledDate, List<Object> timeSlotsObjLst){
        List<Object> timeSlotsObj = new List<Object> ();
        try{
            List<Event> scheduledEvents = AppointmentSchedulerController.getScheduledSlots(schedulingGroup,scheduledDate);
            System.debug('scheduledEvents->'+scheduledEvents);
            if(scheduledEvents.size()>0){
                for(Event e: scheduledEvents){
                    for(Object obj: timeSlotsObjLst){
                        Map<String,object> tempobj = (Map<String,object>)obj;
                        String d = (e.StartDateTime).format('yyyy-MM-dd HH:mm:ss', 'UTC');
                        d=d.substringAfter(' ');
                        if(d==String.valueOf(tempobj.get('value'))){
                            tempobj.put('timeSlotAvialable',false);
                        }else{
                            tempobj.put('timeSlotAvialable',true);
                        }
                        timeSlotsObj.add(tempobj);
                    }
                }
            }else{
                timeSlotsObj = timeSlotsObjLst;
            }
        }catch(Exception ex){
            System.debug('ex-->'+ex);
        }
        return timeSlotsObj;
    }

    /*@AuraEnabled
    public static Map<String,Object> configureTimeSlots(String startTime,String endTime) {
        Map<String,Object> slotConfig = new  Map<String,Object>();
        try{
            slotConfig.put('configSlotHours','00');
            slotConfig.put('configSlotMinutes','15');
            slotConfig.put('configSlotPreparation','00');
            List<Object> timeArrObj = new List<Object> {new Map<String,Object>{'startTime'=>'16:00', 'endTime'=>'20:00'}};
                System.debug('timeArrObj-->'+timeArrObj);
            slotConfig.put('timeArr',timeArrObj);
            System.debug('slotConfig-->');
            System.debug(slotConfig);
        }catch(Exception ex){System.debug('ex-->'+ex);}
        return slotConfig;
    }*/
    
    /*@AuraEnabled
    public static void DateTimeConversion(integer y, integer d,integer m, integer h,integer min,integer s)
    {
        Datetime GMTDate = 
            Datetime.newInstanceGmt(y,m,d,h,min,s);
        System.debug('GMTDate '+GMTDate);
        String strConvertedDate = GMTDate.format('MM/dd/yyyy HH:mm:ss', 'America/New_York');
        System.debug('strConvertedDate'+strConvertedDate);
    }*/
    
    /*@AuraEnabled
    public static void convertGMTtoTargetTimeZone(integer y, integer d,integer m, integer h,integer min,integer s){
        Datetime GMTDt = 
            Datetime.newInstance(y,m,d,h,min,s);
        System.debug('GMTDt '+GMTDt);
        String strConvertedDate = GMTDt.format('MM/dd/yyyy HH:mm:ss', 'America/New_York');
        System.debug('convertGMTtoTargetTimeZone'+strConvertedDate);
    }*/
    
    /*@AuraEnabled
    public static Datetime getDateTimeGmt(String tzId, Date d, Time t) {
        DateTime    res;
        if (tzId == null || d == null || t == null) return res;
        Timezone    tz          = Timezone.getTimeZone(tzId);
        DateTime    dt          = DateTime.newInstanceGmt(d,t);
        Integer     offsetMs    = tz.getOffset(dt);                 // #ms offset from datetime in Tz to GMT
        Integer     offsetMins  = offsetMs / (1000 * 60);
        res = dt.addMinutes(-1 * offsetMins);

        return res;
    } */
    
}