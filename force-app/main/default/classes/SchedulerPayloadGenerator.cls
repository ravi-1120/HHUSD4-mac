/*
    Created By - RK Kolluri
    Description - Controller to generate JSON payload based on admin configurations for scheduler Admin App
    Last Modified By - Joshi Jigyasu
    Last Modified Date - 22-05-2023
*/
public with sharing class SchedulerPayloadGenerator {
    public static String className = 'SchedulerPayloadGenerator';
         
	//Use the method to generate JSON payload
    public static void generateJSON(Set<Id> schedulerIds, boolean templatesChanged){
        
        try{
            //Query scheduler and their child objects like Appointment Templates etc
            List<Scheduler_Configuration__c> updateList = new List<Scheduler_Configuration__c>();
            Map<Id, Scheduler_Configuration__c> schedulers = new Map<Id, Scheduler_Configuration__c>();
            Map<Id, List<String>> productsTemplates = new Map<Id, List<String>>();
            set<Id> productsIds= new set<Id>();
            for(Scheduler_Configuration__c sObj : [Select Id, Name, JSON_Payload__c, 
                Communication_Channels__c,Background_Color__c, Color__c,IFrame_Source_Link__c, 
                (select id, name,Order__c, Appointment_Template__c, Appointment_Template__r.name,
                    Appointment_Template__r.IsSchedulable__c, Appointment_Template__r.Convey_Tumor__c, 
                    Appointment_Template__r.Template_Message__c from Scheduler_Templates__r),
                (select id, Name, Order__c,Product_Payor__c,Product_Payor__r.Name,Product_Payor__r.Is_Blackbox_Product__c,
                    Product_Payor__r.Product_Thumbnail__c,Product_Payor__r.Product_Message_Body__c,Product_Payor__r.MSD_CORE_Product_Catalog__c,
                    Product_Payor__r.Product_Message_Footer__c,Product_Payor__r.Product_Message_Header__c from Admin_Products__r)
                    from Scheduler_Configuration__c where Id in : schedulerIds])
            {
                schedulers.put(sObj.id, sObj);
                if(sObj.Admin_Products__r!=null && !sObj.Admin_Products__r.isEmpty()){
                    for(Admin_Product__c ap:sObj.Admin_Products__r){
                        productsIds.add(ap.Product_Payor__c);
                    }
                }
            }

            List<ScheduleRequest.BusinessHoursNew> businessHours=addBusinessHours();

            for(Product_Template__c pt : [select Id,Product_Payor__c, Appointment_Template__r.Name from Product_Template__c where Product_Payor__c in:productsIds]){
                if(productsTemplates.containsKey(pt.Product_Payor__c)){
                    productsTemplates.get(pt.Product_Payor__c).add(pt.Appointment_Template__r.Name);
                }else{
                    productsTemplates.put(pt.Product_Payor__c, new List<String>{pt.Appointment_Template__r.Name});
                }
            }
            
            //Loop over all Schedulers and contruct JSON payload
            for(Scheduler_Configuration__c sObj : schedulers.values()){
                ScheduleRequest srObj = new ScheduleRequest();
                srObj.name = sObj.Name;
                srObj.id = sObj.Id;
                ScheduleRequest.UICss uObj = new ScheduleRequest.UICss();
                uObj.bgColor = sObj.Background_Color__c;
                uObj.fgColor = sObj.Color__c;
                srObj.uiCss = uObj;
                System.debug('*** Channels'+sObj.Communication_Channels__c);
                if(sObj.Communication_Channels__c != null){
                    srObj = addChannels(srObj, sObj.Communication_Channels__c);
                }
                /*** Adding the templates dynamically to JSON paylaod */
                srObj.templates = new List<ScheduleRequest.Templates>();
                for(Integer i = 0; i < sObj.Scheduler_Templates__r.size(); i++){
                    ScheduleRequest.Templates temp = new ScheduleRequest.Templates();
                    Scheduler_Template__c adminTemp = sObj.Scheduler_Templates__r[i];
                    temp.label = adminTemp.Appointment_Template__r.name;
                    temp.order = Integer.valueOf(adminTemp.Order__c);
                    temp.isSchedulable = adminTemp.Appointment_Template__r.IsSchedulable__c;
                    temp.templateMessage = adminTemp.Appointment_Template__r.Template_Message__c;
                    temp.value = adminTemp.Appointment_Template__c;
                    temp.conveyTumor = adminTemp.Appointment_Template__r.Convey_Tumor__c;
                    srObj.templates.add(temp);
                }
                
                srObj.products = new List<ScheduleRequest.Products>();
                for(Integer i = 0; i < sObj.Admin_Products__r.size(); i++){
                    ScheduleRequest.Products prod = new ScheduleRequest.Products();
                    ScheduleRequest.ProductAcessInquiry productAcessInquiry = new ScheduleRequest.ProductAcessInquiry();
                    Admin_Product__c adminProd = sObj.Admin_Products__r[i];
                    prod.label = adminProd.Product_Payor__r.Name;
                    prod.order = Integer.valueOf(adminProd.Order__c);
                    prod.Value=adminProd.Product_Payor__c;

                    prod.parentID = adminProd.Product_Payor__r.MSD_CORE_Product_Catalog__c!=null ? 
                        (String)adminProd.Product_Payor__r.MSD_CORE_Product_Catalog__c:' '; //storing Product Catalog Id
                    
                    prod.isBlackBox=adminProd.Product_Payor__r.Is_Blackbox_Product__c;
                    if(prod.isBlackBox){
                        prod.additionalInformation=adminProd.Product_Payor__r.Product_Thumbnail__c;
                    }
                    productAcessInquiry.header=adminProd.Product_Payor__r.Product_Message_Header__c;
                    productAcessInquiry.body=adminProd.Product_Payor__r.Product_Message_Body__c;
                    productAcessInquiry.footer=adminProd.Product_Payor__r.Product_Message_Footer__c;
                    prod.productAcessInquiry=productAcessInquiry;
                    prod.inquiryTypes=productsTemplates.containsKey(adminProd.Product_Payor__c)?productsTemplates.get(adminProd.Product_Payor__c):new List<String>();
                    srObj.products.add(prod);
                }
                srObj.businessHours = businessHours;
                
                srObj = addDesignations(srObj);         
                srObj = addGroups(srObj);

                system.debug('templatesChanged:'+templatesChanged);
                if(templatesChanged){
                    srObj.assignmentGroups = new List<ScheduleRequest.AssignmentGroups>();
                }else{
                    ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(sObj.JSON_Payload__c, ScheduleRequest.class);
                    srObj.assignmentGroups=payload.assignmentGroups;
                }
                
                sObj.JSON_Payload__c = JSON.serializePretty(srObj, true);
                system.debug('payload==>');
                system.debug(sObj.JSON_Payload__c);
                updateList.add(sObj);
            }
            if(updateList.size () > 0){
                update updateList;
            }

        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            System.debug('ex-line->'+ ex.getLineNumber());
            System.debug('ex-line->'+ ex.getStackTraceString());
            AMOExceptionHandler.logException(ex,className,'generateJSON','','Apex');
        }
         
     }

    public static ScheduleRequest addChannels(ScheduleRequest srObj, String channels){
        
        try{
            srObj.communicationModes = new List<ScheduleRequest.CommunicateModes>();
            if(channels != null){
                List<String> cChannels = channels.split(';');
                for(String c : cChannels){
                    ScheduleRequest.CommunicateModes cm = new ScheduleRequest.CommunicateModes();
                    cm.label = c;
                    cm.value = c;
                    if(c == 'Call me now'){
                        cm.message = 'Merck Associates are available Mon-Fri, 8am-8pm ET.'; 
                    }
                    srObj.communicationModes.add(cm);  
                    system.debug('cObj'+cm);
                }
            }
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'addChannels','','Apex'); 
        }
        return srObj;
    }

    public static ScheduleRequest addDesignations(ScheduleRequest srObj){
        
        String objectName = 'Event';
        String fieldName ='Professional_Designation__c';
        try{
            Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            srObj.professionalDesignation = new List<ScheduleRequest.ProfessionalDesignation>();
            for( Integer i = 0; i < ple.size(); i++){
                System.debug(ple[i].getLabel() +' '+ple[i].getValue()+' order '+Integer.valueOf(i+1));
                ScheduleRequest.ProfessionalDesignation bObj = new ScheduleRequest.ProfessionalDesignation();
                bObj.label = ple[i].getLabel();
                bObj.value = ple[i].getValue();
                bObj.order = Integer.valueOf(i+1);
                srObj.professionalDesignation.add(bObj);
            }
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'addDesignations','','Apex');   
        }
        return srObj;
    }

    public static List<ScheduleRequest.BusinessHoursNew> addBusinessHours(){
        
        List<ScheduleRequest.BusinessHoursNew> businessHoursNew = new List<ScheduleRequest.BusinessHoursNew>();    
        try{    
            List<Operating_Hours__c> oppHours= new List<Operating_Hours__c>();
            oppHours=[select Id,(select Id,Operating_Hours_Message__c,Out_Side_Operating_Hours_Message__c,Name from Scheduling_Groups__r),
                    (select Id,Start_Time__c,End_Time__c,Day_of_Week__c from Time_Slots__r)
                    from Operating_Hours__c];
            
            for(Operating_Hours__c opph  : oppHours){
                for(Scheduling_Groups__c weekName : opph.Scheduling_Groups__r){
                    ScheduleRequest.BusinessHoursNew businessHour= new ScheduleRequest.BusinessHoursNew();
                    List<ScheduleRequest.OperatingHours> operatingHours = new List<ScheduleRequest.OperatingHours>();
                    
                    for(Time_Slots__c timeslot : opph.Time_Slots__r){
                        ScheduleRequest.OperatingHours bObj = new ScheduleRequest.OperatingHours();
                        bObj.weekName = timeslot.Day_of_Week__c;
                        bObj.startTime = timeslot.Start_Time__c != null ? getFomattedTime(String.valueOf(timeslot.Start_Time__c)) : '';
                        bObj.endTime =  timeslot.End_Time__c != null ? getFomattedTime(String.valueOf(timeslot.End_Time__c)) : '';
                        operatingHours.add(bObj);
                    }
                    businessHour.operatingHours=operatingHours;
                    businessHour.operatingHoursMessage=weekName.Operating_Hours_Message__c;
                    businessHour.OutsideOperatingHoursMessage=weekName.Out_Side_Operating_Hours_Message__c;
                    businessHour.groupName=weekName.Name;
                    businessHour.groupId=weekName.Id;
                    businessHoursNew.add(businessHour);
                }
            }
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'addBusinessHours','','Apex');   
        }
        return businessHoursNew;
    }

    public static ScheduleRequest addGroups(ScheduleRequest srObj){

        try{
            String tempPayload = String.valueOf(srObj);
            Boolean isRoutingCreated = tempPayload.contains('routingGroup');
            System.debug('conatins-->'+isRoutingCreated);
            System.debug('tempPayload-->'+tempPayload);
            
            srObj.holidaysByGroup = new List<ScheduleRequest.HolidaysByGroup>();
            List<Scheduling_Groups__c> groups = [select id, name, IsActive__c, (select id, name, Holiday__c, Holiday__r.name, Holiday__r.Date__c from Group_Holidays__r WHERE Holiday__r.Date__c = THIS_YEAR ) from Scheduling_Groups__c where IsActive__c = true];
            for(Scheduling_Groups__c gObj : groups){
                ScheduleRequest.HolidaysByGroup hObj = new ScheduleRequest.HolidaysByGroup();
                hObj.groupName = gObj.Name;
                hObj.groupId = gObj.Id;
                hObj.holidays = new List<String>();
                for(Group_Holidays__c ghObj : gObj.Group_Holidays__r){
                    hObj.holidays.add(String.valueOf(ghObj.Holiday__r.Date__c));    
                }
                srObj.holidaysByGroup.add(hObj);
            }
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'addGroups','','Apex');   
        }
        return srObj;
    }

    @AuraEnabled
    public static void updateCommunicationChannels(String recordId){

        try {
            generateJSON(new Set<Id>{recordId},false);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getFomattedTime(String timeString){

        String formattedTime;
        try {
            String tempTimeString = timeString;
            tempTimeString =  tempTimeString.substringBefore('.');
            DateTime dt = System.now();
            String dtString = String.valueOf(dt);
            dtString = dtString.substringBefore(' ');
            dtString += ' '+tempTimeString;
            DateTime finalDateTime = DateTime.valueOf(dtString);
            String[] parts = finalDateTime.format().split(' ');
            formattedTime = (parts.size() == 3) ? (parts[1] + ' ' + parts[2]) : parts[1];
        } catch (Exception e) {
            System.debug('exception-->'+e);
            AMOExceptionHandler.logException(e,className,'getFomattedTime','','Apex');
        }
        return formattedTime;
    }

}