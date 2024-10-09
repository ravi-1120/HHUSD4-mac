public without sharing class AppointmentSchedulerController {
    public static String className = 'AppointmentSchedulerController';

    public class WeekWrapper{
        @AuraEnabled public String dateLabel {get;set;}
        @AuraEnabled public Date dateValue {get;set;}
        @AuraEnabled public Boolean showdate {get;set;}
        
        public WeekWrapper(String dateLabel,Date dateValue){
            this.dateLabel = dateLabel;
            this.dateValue = dateValue;
            date currDate = System.today();
            this.showdate = (currDate<=dateValue)?true:false;
        }
    }
    
    public static String getDateFormat(Date dt)
    {
        DateTime myDateTime = (DateTime) dt;
        String dayOfWeek = myDateTime.format('EEEEEE, MMMM dd');
        
        return dayOfWeek;
    }
    
    @AuraEnabled
    public static List<WeekWrapper> getAppointmentDates(date currentDate)
    {  
        List<WeekWrapper> weekList = new List<WeekWrapper>();
        try{
            String dayOfWeek = getDateFormat(currentDate);
            System.debug('dt-->'+currentDate);
            System.debug('dayOfWeek-->'+dayOfWeek);
            if(dayOfWeek.SubStringBefore(',')=='Saturday') {
                currentDate=currentDate.addDays(1);
            }
            Date weekStartDate = currentDate.toStartofWeek().addDays(1);//global change toStartofWeek is Sunday for US & Monday for Europe
            System.debug('weekStartDate-->'+weekStartDate);
            for(Integer i=0; i < 5; i++)
            {
                weekList.add(new WeekWrapper(getDateFormat(weekStartDate.addDays(i)), weekStartDate.addDays(i)));
            }
            System.debug('weekList-->'+weekList);
        }catch(exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'getAppointmentDates','','Apex');
        }
        return weekList;
    }
    
    @AuraEnabled
    public static Map<String,Object> saveAppointmentScheduleDetails(Map<String, Object> scheduleDetails){
        Map<String,Object> appointmentDetailsMap = new Map<String,Object>();
        try{
            Event scheduleEvent = new Event();
            System.debug('scheduleDetails->'+scheduleDetails);
            scheduleEvent.Subject = String.valueOf(scheduleDetails.get('templateLabel'));
            scheduleEvent.Schedule_Status__c = 'InProgress';
            String contactDateTime;
            String dateString = Datetime.now().format('ddMMYYYYHHmmss');
            String randomInteger = String.valueOf(Crypto.getRandomInteger()).substring(1,5);

            if(scheduleDetails.get('isCallMeNow')==false){
                String localMonthZero = Integer.valueOf(monthVal(String.valueOf(scheduleDetails.get('localDateValue')).subString(4,7))) < 10 ? '0' : '';
                String tempLocalDate = String.valueOf(scheduleDetails.get('localDateValue')).subString(11,15) + '-' + localMonthZero + monthVal(String.valueOf(scheduleDetails.get('localDateValue')).subString(4,7)) + '-' + String.valueOf(scheduleDetails.get('localDateValue')).subString(8,10) + ' ' + String.valueOf(scheduleDetails.get('localDateValue')).subString(16,24);
                system.debug('tempLocalDate: '+tempLocalDate);
                scheduleDetails.put('finalLocalDateTime',tempLocalDate);
                contactDateTime = scheduleDetails.get('dateValue')+' '+scheduleDetails.get('timeSlotValue');
                List<String> dateLst = String.valueOf(scheduleDetails.get('dateValue')).split('-');
                List<String> timeLst = String.valueOf(scheduleDetails.get('timeSlotValue')).split(':');
                /*JJ_25-01-2024_TimeZoneGMTConvert*/
                // Datetime GMTDate = Datetime.newInstanceGmt(integer.valueOf(dateLst[0]),integer.valueOf(dateLst[1]),integer.valueOf(dateLst[2]),integer.valueOf(timeLst[0]),integer.valueOf(timeLst[1]),integer.valueOf(timeLst[2]));
                // System.debug('GMTDate '+GMTDate);
                // scheduleEvent.StartDateTime = DateTime.valueOf(GMTDate);
                // scheduleEvent.EndDateTime = DateTime.valueOf(GMTDate).addMinutes(15);
                Datetime GMTDate = Datetime.newInstance(integer.valueOf(dateLst[0]),integer.valueOf(dateLst[1]),integer.valueOf(dateLst[2]),integer.valueOf(timeLst[0]),integer.valueOf(timeLst[1]),integer.valueOf(timeLst[2]));
                scheduleEvent.StartDateTime = GMTDate;
                scheduleEvent.EndDateTime = GMTDate.addMinutes(15);
                /*JJ_25-01-2024_TimeZoneGMTConvert*/
            }else{
                contactDateTime = scheduleDetails.get('currESTDate')+' '+scheduleDetails.get('currESTTime');
                scheduleEvent.StartDateTime = DateTime.valueOf(contactDateTime);
                scheduleEvent.EndDateTime = DateTime.valueOf(contactDateTime).addMinutes(15);
            }
            scheduleEvent.DurationInMinutes = 15;
            scheduleEvent.Communication_Mode__c = String.valueOf(scheduleDetails.get('communicationMode'));
            scheduleEvent.Appointment_Template__c = String.valueOf(scheduleDetails.get('templateId'));
            scheduleEvent.Scheduling_Group__c = String.valueOf(scheduleDetails.get('schedulingGroupId'));
            scheduleEvent.Professional_Designation__c = String.valueOf(scheduleDetails.get('professionalDesignation'));
            if (scheduleDetails.get('tumorIndication')!=null){
                scheduleEvent.Tumor_Indication__c = String.valueOf(scheduleDetails.get('tumorIndication'));
            }
            if (scheduleDetails.get('FirstName')!=null){
                scheduleEvent.First_Name__c = String.valueOf(scheduleDetails.get('FirstName'));
            }
            scheduleEvent.Last_Name__c = String.valueOf(scheduleDetails.get('LastName'));
            scheduleEvent.Phone__c = String.valueOf(scheduleDetails.get('Phone'));
            if (scheduleDetails.get('Extension')!=null){
                scheduleEvent.Extension__c = String.valueOf(scheduleDetails.get('Extension'));
            }
            if (scheduleDetails.get('schedulerOwner')!=null){
                scheduleEvent.OwnerId = String.valueOf(scheduleDetails.get('schedulerOwner'));
            }
            if (scheduleDetails.get('Email')!=null){
                scheduleEvent.Email__c = String.valueOf(scheduleDetails.get('Email'));
            }
            if (scheduleDetails.get('productEnquiryValue')!=null){
                scheduleEvent.Product_Payor__c = String.valueOf(scheduleDetails.get('productEnquiryValue'));
            }
            if (String.isNotBlank((String)scheduleDetails.get('productParent'))){
                scheduleEvent.Product_Enquiry__c = String.valueOf(scheduleDetails.get('productParent'));
            }
            if(Boolean.valueOf(scheduleDetails.get('isCallMeNow'))){
                Map <String,Object> getAgentAvilability = NiceInContactController.getAgentAvilability(scheduleDetails);
                appointmentDetailsMap.put('agentAvilability',getAgentAvilability);
                Map <String,Object>calloutResponse = NiceInContactController.callMeNowHttpRequest(JSON.serialize(scheduleDetails),dateString+randomInteger);
                scheduleEvent.Schedule_Status__c = String.valueOf(calloutResponse.get('scheduleStatus'));
                if (String.valueOf(calloutResponse.get('spawnId'))!=null){
                    scheduleEvent.NIC_External_Id__c = String.valueOf(calloutResponse.get('spawnId'));
                }
                appointmentDetailsMap.put('calloutResponse',calloutResponse);
            }else{
                Map <String,Object>calloutResponse= NiceInContactController.scheduleCallbackHttpRequest(JSON.serialize(scheduleDetails), dateString+randomInteger);
                System.debug('calloutResponse-->');
                System.debug(calloutResponse);
                scheduleEvent.Schedule_Status__c = String.valueOf(calloutResponse.get('scheduleStatus'));
                if (String.valueOf(calloutResponse.get('spawnId'))!=null){
                    scheduleEvent.NIC_External_Id__c = String.valueOf(calloutResponse.get('spawnId'));
                }
                appointmentDetailsMap.put('calloutResponse',calloutResponse);
            }
            scheduleEvent.Scheduler_Unique_Id__c = dateString+randomInteger;
            insert scheduleEvent;
            
            if(scheduleDetails.get('isCallMeNow')==false && String.isNotBlank(String.valueOf(scheduleDetails.get('Email'))) && String.isNotBlank(scheduleEvent.NIC_External_Id__c)){
                sendEmailInvite(scheduleDetails,scheduleEvent);
            }
            appointmentDetailsMap.put('scheduledEvent',scheduleEvent);
            
        }catch(Exception ex){
            System.debug('saveschedular Exception-->'+ex);
            AMOExceptionHandler.logException(ex,className,'saveAppointmentScheduleDetails','','Apex');
        }
        return appointmentDetailsMap;
    }
  
    @testVisible
    private static String monthVal(String monthAbb){
        switch on monthAbb {
            when 'Jan' {return '1';}
            when 'Feb' {return '2';}
            when 'Mar' {return '3';}
            when 'Apr' {return '4';}
            when 'May' {return '5';}
            when 'Jun' {return '6';}
            when 'Jul' {return '7';}
            when 'Aug' {return '8';}
            when 'Sep' {return '9';}
            when 'Oct' {return '10';}
            when 'Nov' {return '11';}
            when 'Dec' {return '12';}
        }
        return '';
    }
    
    @AuraEnabled
    public static List<Event> getScheduledSlots(String schedulingGroupName,String scheduleDate){
        Date tmpScheduleDate = Date.valueOf(scheduleDate);

        return ([SELECT Id,Subject,Appointment_Template__r.Name,Scheduling_Group__r.Name,ActivityDate,StartDateTime,EndDateTime FROM Event
                 WHERE ActivityDate=: tmpScheduleDate AND Scheduling_Group__r.Name=: schedulingGroupName AND Schedule_Status__c = 'Scheduled']);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getHCPData(String href,date currDate){
        if(href!=null && href.contains('schedulerId=')){
            return getHCPDataStructurebyId(href.split('schedulerId=')[1],currDate);
        }else if(href!=null){
            return getHCPDataStructurebyId(href,currDate);
        }else{
            return getHCPDataStructureAMO(currDate);
        }
    }
    
    @AuraEnabled
    public static Map<String,Object> getHCPDataStructurebyId(String schedulerId,date currDate){
        Map<String,Object> schedulerDataStructure = new Map<String,Object>();
        try{
            String tmpSchedulerId = schedulerId;
            Scheduler_Configuration__c schedulerconfig = [SELECT Id,Name,JSON_Payload__c,CreatedbyId From Scheduler_Configuration__c
                                                          WHERE Id =:tmpSchedulerId LIMIT 1];
            schedulerDataStructure = (Map<String,Object>)JSON.deserializeUntyped(schedulerconfig.JSON_Payload__c);
            List<Object> getScheduleDates = getAppointmentDates(currDate);
            schedulerDataStructure.put('scheduleDates',getScheduleDates);
            schedulerDataStructure.put('schedulerOwner',schedulerconfig.CreatedbyId);
        }
        catch(Exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'getHCPDataStructurebyId','','Apex');
        }
        return schedulerDataStructure;
    }
        
    @AuraEnabled
    public static Map<String,Object> getHCPDataStructureAMO(date currDate){
        Map<String,Object> schedulerDataStructure = new Map<String,Object>();
        try{
            System.debug('schedulerconfigschedulerconfig');
            Scheduler_Configuration__c schedulerconfig = [SELECT Id,Name,JSON_Payload__c,CreatedbyId From Scheduler_Configuration__c
                                                          WHERE Name='AMO' LIMIT 1];
            System.debug('schedulerconfig Id-->'+schedulerconfig.Id);
            schedulerDataStructure = (Map<String,Object>)JSON.deserializeUntyped(schedulerconfig.JSON_Payload__c);
            List<Object> getScheduleDates = getAppointmentDates(currDate);
            schedulerDataStructure.put('scheduleDates',getScheduleDates);
            schedulerDataStructure.put('schedulerOwner',schedulerconfig.CreatedbyId);
        }catch(Exception ex){
            System.debug('ex-->'+ex);
        AMOExceptionHandler.logException(ex,className,'getHCPDataStructureAMO','','Apex');

    }
        return schedulerDataStructure;
    }
    
    @AuraEnabled
    public static void sendEmailInvite(Map<String,Object> scheduleDetails, Event eventdetails){
        try{
            EmailTemplate emailTemp = [SELECT id, body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'MOD_Schedule_Call_Back_V2' LIMIT 1];
            String htmlBody = emailTemp.HtmlValue;
            String dt;
            if(scheduleDetails.get('isCallMeNow')==false){
                dt = String.valueOf(scheduleDetails.get('dateLabel')).split(',')[1];
                htmlBody = htmlBody.replace('{!Event.StartDateTime}', dt +' at '+String.valueOf(scheduleDetails.get('timeSlotLabel'))+ ' ET') ;
            }else{
                String dtString = String.valueOf(scheduleDetails.get('currESTDate'))+' '+ String.valueOf(scheduleDetails.get('currESTTime'));
                DateTime formattedTime = DateTime.valueOf(dtString);
                dt = formattedTime.format();
                String tempESTDate = formattedTime.format('EEEEEE, MMMM dd');
                htmlBody = htmlBody.replace('{!Event.StartDateTime}', tempESTDate.split(',')[1] +' at '+ dt.split(' ')[1]+' '+ dt.split(' ')[2]+ ' ET') ;
            }
            System.debug('dt-->'+dt);
            htmlBody = htmlBody.replace('{!Event.Subject}', String.valueOf(scheduleDetails.get('templateLabel')));
           // htmlBody = htmlBody.replace('{!SiteDetail.SecureURL}', getFeedbackLink(eventdetails.Id,String.valueOf(scheduleDetails.get('schedulerId'))));
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Ask Merck' LIMIT 1];
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.id,null,UserInfo.getUserId()); 
            mail.setToAddresses(new List<String>{String.valueOf(scheduleDetails.get('Email'))});
            mail.setOrgWideEmailAddressId(owea.Id);
            //mail.setSubject(templateLabel);
            mail.setSubject('Your Ask Merck callback is confirmed');
            System.debug('----'+htmlBody);
            mail.setHtmlBody(htmlBody);
            mail.setTemplateId(emailTemp.Id);
            mail.setSaveAsActivity(false);
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();   
            attach.filename = 'reminder.ics'; 
            attach.ContentType = 'text/calendar';     
            attach.inline = true;     
            attach.body = invite(scheduleDetails,eventdetails);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});   
            Messaging.SendEmailResult[] er = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'sendEmailInvite','','Apex');
        }
    }
    
    @AuraEnabled
    public static Blob invite(Map<String,Object> scheduleDetails, Event eventdetails) {
        String txtInvite = ''; 
        try{
            String templateLabel = String.valueOf(scheduleDetails.get('templateLabel'));
            String scheduledDateTime;
            if(scheduleDetails.get('isCallMeNow')==false){
                // scheduledDateTime = String.valueOf(scheduleDetails.get('finalLocalDateTime'));
                Datetime startDt = eventdetails.StartDateTime;
                String formatted = startDt.formatGMT('yyyyMMdd HHmmss');
                scheduledDateTime = formatted+'Z';
            }else {
                scheduledDateTime = String.valueOf(scheduleDetails.get('currESTDate'))+' '+ String.valueOf(scheduleDetails.get('currESTTime'));
            }
            String body = '<h1> This is a calendar hold for your scheduled call with a Merck Associate. </h1><br/><hr size="3" width="100%" color="#00857C">  <br/>';
            body += '<b style="color: rgb(0, 133, 124); font-family: Invention, sans-serif; font-size: medium;">The associate will reach out to you directly.</b>';
            body += '<br/><br/>This service is for US health care professionals only.';
            body += '<br/><br/>This meeting is automatically generated. <br/>';
            body +='<br/><br/><p style="color:rgb(128,128,128); font-family: Invention,sans-serif;font-size: small;"> Copyright © 2024 Merck & Co., Inc., Rahway, NJ, USA and its affiliates. All rights reserved.  <br/>US-NON-17263 10/24</p>';
            String subject = 'Call with an Ask Merck Associate';
            String dt = String.valueOfGmt(dateTime.now());
            dt = dt.replace(' ','T');
            dt = dt.replaceAll('-','');
            dt = dt.replaceAll(':','');
            scheduledDateTime = scheduledDateTime.replace(' ','T');
            scheduledDateTime = scheduledDateTime.replaceAll('-','');
            scheduledDateTime = scheduledDateTime.replaceAll(':','');
            System.debug('dt-->'+dt);
            System.debug('scheduledDateTime-->'+scheduledDateTime);

            //body = body.replace('{!SiteDetail.SecureURL}', getFeedbackLink(eventdetails.Id,String.valueOf(scheduleDetails.get('schedulerId'))));
            txtInvite = 'BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//salesforce.com//Calendar//EN\nBEGIN:VEVENT\n';
            txtInvite += 'DTSTAMP:' + dt + '\nSUMMARY:' + subject + '\nCATEGORIES:salesforce.com\n';
            txtInvite += 'DESCRIPTION: This is a calendar hold for your scheduled call with a Merck Associate.\n';
            txtInvite += 'X-ALT-DESC;FMTTYPE=text/html:'+body+'\n' + 'CREATED:' + dt + '\nLAST-MODIFIED:' + dt;
            txtInvite += '\nSTATUS:CONFIRMED\n' + 'DTSTART:' + scheduledDateTime + '\nDURATION:PT15M\nEND:VEVENT\nEND:VCALENDAR'; 
        } catch(Exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'invite','','Apex');
        }
        return Blob.valueOf(txtInvite);
    }
        
    /*@AuraEnabled
    public static List<MenuWrapper> getAppointmentTypes()
    {
        List<MenuWrapper> menuList = new List<MenuWrapper>();
        try{
            for(Appointment_Template__c at : [SELECT Id, Name,IsSchedulable__c,Template_Message__c,Convey_Tumor__c
                                              FROM Appointment_Template__c WHERE isActive__c=true  ORDER BY Name ASC NULLS LAST])
            {
                menuList.add(new MenuWrapper(at.Name, at.Id,at.IsSchedulable__c,at.Template_Message__c,at.Convey_Tumor__c));
            }
        }catch(exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'getAppointmentTypes','','Apex');
        }
        return menuList;
    }*/

    /*public class MenuWrapper{
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public Boolean isSchedulable {get;set;}
        @AuraEnabled public String templateMessage {get;set;}
        @AuraEnabled public Integer order {get;set;}
        @AuraEnabled public Boolean conveyTumor {get;set;}
        
        public MenuWrapper(String label,String value,
                           Boolean isSchedulable,String templateMessage,Boolean conveyTumor)
        {
            this.label = label;
            this.value = value;
            this.isSchedulable = isSchedulable;
            this.templateMessage = templateMessage;
            this.conveyTumor = conveyTumor;
            if(label =='Clinical Study Information'){
                this.order =1;
            }
            else if(label =='General Adverse Event Management'){
                this.order =2;
            }
            else if(label =='Patient Education'){
                this.order =3;
            }
            else if(label =='Product Access Inquires: Coverage and Reimbursement; Coding and Billing'){
                this.order =4;
            }
            else{
                this.order =5;
            }
        }
    }*/
    
    /*Public static Datetime formatDateTime(String scheduleDate,String scheduleTime){
        Datetime formattedDate;
        try{   
            String contactDateTime = scheduleDate+' '+scheduleTime;
            System.debug('contactDateTime->'+contactDateTime);
            formattedDate = Datetime.parse( contactDateTime );
            System.debug('formattedDate->'+formattedDate);
        }
        catch(Exception ex){
            System.debug('ex-->'+ex);
        AMOExceptionHandler.logException(ex,className,'formatDateTime','','Apex');

    }
        return formattedDate;
    } */

   /* @AuraEnabled // commenting as moved feedback out of scope for R2.
    Public static Event saveFeedback(Map<String,Object> feedbackResponse,String eventId){
        Event evt = new Event();
        try {
            System.debug('feedback res-->'+feedbackResponse);
            System.debug('eventId-->'+eventId);
            evt.Id = eventId;
            evt.AMO_Scheduler_Satisfaction_Feedback__c = String.valueOf(feedbackResponse.get('AMO_Scheduler_Satisfaction_Feedback__c'));
            evt.AMO_Was_Original_Issue_Resolved__c = String.valueOf(feedbackResponse.get('AMO_Was_Original_Issue_Resolved__c'));
            evt.AMO_Would_you_recommend_this_experience__c = String.valueOf(feedbackResponse.get('AMO_Would_you_recommend_this_experience__c'));
            evt.AMO_Would_you_use_this_tool_again__c = String.valueOf(feedbackResponse.get('AMO_Would_you_use_this_tool_again__c'));
            update evt;
        } catch (Exception e) {
            System.debug('feedback ex--->'+e);
        }
        return evt;
    } */
    
  /*  @AuraEnabled
    public static string getFeedbackLink(String eventId,String schedulerId) {
        String feedbackLink = '';
        try {
            Site sObj = [SELECT Id FROM Site where Name = 'MOD_HCP_Scheduler' LIMIT 1];
            SiteDetail sdObj = [SELECT SecureURL FROM SiteDetail where DurableId =: sObj.Id LIMIT 1];
            feedbackLink = sdObj.SecureURL+'#feedback'+'?eventId='+eventId+'&schedulerId='+schedulerId;
            system.debug('feedbackLink-->'+feedbackLink);
        } catch (Exception e) {
            System.debug('getFeedbackLink ex-->'+e);
        }
        return feedbackLink;
    } */
    
    
}