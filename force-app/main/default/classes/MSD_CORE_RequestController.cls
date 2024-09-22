/**
 * Component Name : MSD_CORE_RequestController
 * Created By : Focal CXM
 * Description: Server side controller for c-msd_core_requestandappointment LWC component
 * Test class : MSD_CORE_RequestControllerTest
 * @description MSD_CORE_RequestController
 */

public without sharing class MSD_CORE_RequestController {
    /**
     * @description getRequest
     * @param requestType 
     * @param pageSize
     * @param pageNumber
     * @param product
     * @param userid
     * @return getRequest
     */
   @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getRequest(String requestType,String pageSize,String pageNumber, String product, String userid) {
        Integer ps = Integer.valueOf(pageSize);
        Integer pn = Integer.valueOf(pageNumber) - 1;
        Integer offsetValue = ps * pn;
        if(requestType=='Rejected'){
            return [Select Id,Name, MSD_CORE_Resource_Type__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_Resource__r.MSD_CORE_Delivery_Framework__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE MSD_CORE_Status__c IN ('Rejected','Closed') AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Product_Payor__c =: product AND MSD_CORE_Resource__c != null ORDER BY CreatedDate ASC LIMIT :ps OFFSET :offsetValue];
        }
        else{
            if(requestType=='Pending')
            {
                return [Select Id,Name, MSD_CORE_Resource_Type__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_Resource__r.MSD_CORE_Delivery_Framework__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE MSD_CORE_Status__c =: requestType AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Product_Payor__c =: product AND MSD_CORE_Resource__c != null ORDER BY CreatedDate ASC LIMIT :ps OFFSET :offsetValue];
            }else{
                return [Select Id,Name, MSD_CORE_Resource_Type__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_Resource__r.MSD_CORE_Delivery_Framework__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE MSD_CORE_Status__c =: requestType AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Product_Payor__c =: product AND MSD_CORE_Resource__c != null ORDER BY Start_DateTime_vod__c ASC LIMIT :ps OFFSET :offsetValue];
            }
        }
    }
   
    /**
     * @description getActiveRequestsTest
     * @return null
     * @return activitylist
     */
    @AuraEnabled(cacheable=true) 
    public static List<Meeting_Request_vod__c> getActiveRequestsTest(){
        List<Meeting_Request_vod__c> activitylist = new List<Meeting_Request_vod__c>();
        //string payorid = UserInfo.getUserID();
        try {
            activitylist = [ SELECT Id, Name, MHEE_Name__c, Account_vod__r.MSD_CORE_Medical_AE__pr.Name, Account_vod__r.MSD_CORE_Oncology_AE__pr.Name, MSD_CORE_Resource__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_attendee__c, MSD_CORE_Resource_Type__c, CreatedDate, MSD_CORE_Source__c, ScheduleFilter__c FROM Meeting_Request_vod__c WHERE MSD_CORE_Source__c = 'MHEE' AND MSD_CORE_Status__c = 'pending' AND MSD_CORE_Payor__c =: UserInfo.getUserID()  ORDER BY CreatedDate DESC LIMIT 5];
            return activitylist;
        }catch (Exception e){
            System.debug(LoggingLevel.WARN,e.getLineNumber());
            System.debug(LoggingLevel.WARN,e.getMessage());
            return null;
        }
    }  
    
    @AuraEnabled(cacheable=true) 
	public static List<AppointmentWrapper> getMeetingRequestsWrapper() {
        Map<String, List<AppointmentDetailWrapper>> groupedAppointments = new Map<String, List<AppointmentDetailWrapper>>();
        Date today = Date.today();
        String detailscls;
    
        Integer currentMonth = today.month();
        Integer currentYear = today.year();
    
    				try {
                        List<MSD_CORE_Meeting_Time__c> allmeetrequests = [
                    SELECT Id, 
                           Name, 
                           MSD_CORE_Meeting_Request__r.Name, 
                           MSD_CORE_Meeting_Request__r.Assignee_vod__r.Name, 
                           MSD_CORE_Meeting_Request__r.MSD_CORE_Payor__r.Name,   
                           MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName,
                           MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName,
                           MSD_CORE_Meeting_Request__r.ScheduleFilter__c, 
                           MSD_CORE_Time_Slot__c, 
                           MSD_CORE_Meeting_Date__c, 
                           MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c
                    FROM MSD_CORE_Meeting_Time__c 
                    WHERE MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MHEE' 
                      AND MSD_CORE_Meeting_Request__r.MSD_CORE_Status__c = 'pending' 
                      AND MSD_CORE_Meeting_Request__r.MSD_CORE_Payor__r.Id = :UserInfo.getUserId()
                      //AND CALENDAR_MONTH(MSD_CORE_Meeting_Date__c) = :currentMonth
                      AND CALENDAR_YEAR(MSD_CORE_Meeting_Date__c) = :currentYear
                      AND MSD_CORE_Meeting_Date__c >= :today
                    ORDER BY MSD_CORE_Meeting_Date__c ASC
                    LIMIT 5
                ];
                
                System.debug('allmeetrequests>>' + allmeetrequests);
                System.debug('Number of allmeetrequests: ' + allmeetrequests.size());
                System.debug('Assignee Name ' + allmeetrequests[0].MSD_CORE_Meeting_Request__r.MSD_CORE_Payor__r.Name);
                        
                for (MSD_CORE_Meeting_Time__c meeting : allmeetrequests) {
                	String heading;
                    
                    if (meeting.MSD_CORE_Meeting_Date__c == today) {
                        heading = 'Today';
                        detailscls = 'backseccls';
                    } else {
                        //heading = String.valueOf(meeting.MSD_CORE_Meeting_Date__c.format('MMMM yyyy'));
                        Date meetingDate = meeting.MSD_CORE_Meeting_Date__c;
                        DateTime meetingDateTime = DateTime.newInstance(meetingDate.year(), meetingDate.month(), meetingDate.day());
                        heading = meetingDateTime.format('MMMM');
                        detailscls = 'backseccls1';
                        //heading = meeting.MSD_CORE_Meeting_Date__c.format('MMMM yyyy');
                    }
        
                    AppointmentDetailWrapper detail = new AppointmentDetailWrapper();
                    
                    detail.title = meeting.MSD_CORE_Meeting_Request__r.ScheduleFilter__c;
                    detail.type = meeting.MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c;
                    detail.description = 'with ' + meeting.MSD_CORE_Meeting_Request__r.Assignee_vod__r.FirstName + ' ' + meeting.MSD_CORE_Meeting_Request__r.Assignee_vod__r.LastName;
        			detail.appdate = String.valueOf(meeting.MSD_CORE_Meeting_Date__c);
                    detail.apptime = meeting.MSD_CORE_Time_Slot__c;
                    detail.recordid = meeting.MSD_CORE_Meeting_Request__r.Id;
                    System.debug('Assignee Name wrapper ' + detail.description); 
                    if (!groupedAppointments.containsKey(heading)) {
                        groupedAppointments.put(heading, new List<AppointmentDetailWrapper>());
                    }
                    groupedAppointments.get(heading).add(detail);
            	}
                        
        		
                        
                List<AppointmentWrapper> appointments = new List<AppointmentWrapper>();
        
                for (String heading : groupedAppointments.keySet()) {
                        AppointmentWrapper wrapper = new AppointmentWrapper();
                        wrapper.appointmentHeading = heading;
                    	wrapper.detailsbackclass = detailscls;
                        wrapper.appointmentDetails = groupedAppointments.get(heading);
                        appointments.add(wrapper);
                	}
        	System.debug('appointments>> ' +  appointments);
            System.debug('appointments>> 123' +JSON.serializePretty(appointments));
            return appointments;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return new List<AppointmentWrapper>(); // Return an empty wrapper in case of an exception
        }
     } 

    public class AppointmentWrapper {
        @AuraEnabled
        public String appointmentHeading { get; set; }
        @AuraEnabled
        public String detailsbackclass { get; set; }
        @AuraEnabled
        public List<AppointmentDetailWrapper> appointmentDetails { get; set; }
    }
    
    public class AppointmentDetailWrapper {
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String appdate { get; set; }
        @AuraEnabled
        public String apptime { get; set; }
        @AuraEnabled
        public String recordid { get; set; }
    }
    
    /**
     * @description getupcomingappointments
     * @return productlst
     * @return null
     */
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getupcomingappointments(){   
         
        try {
            
           //system.debug('userId'+userId);  
            datetime dt = System.now();
            List<Meeting_Request_vod__c> productlst = [select Name,id,MHEE_Name__c,ScheduleFilter__c,Start_DateTime_vod__c,Invitee_Display_Name_vod__c,Assignee_vod__r.name, Assignee_vod__r.FirstName, Assignee_vod__r.LastName, MSD_CORE_Product_Payor__r.name, MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__c,createddate  from Meeting_Request_vod__c  where MSD_CORE_Status__c='Approved' and MSD_CORE_Source__c ='MHEE' and MSD_CORE_Payor__c =: UserInfo.getUserID() and Start_DateTime_vod__c>:dt order by Start_DateTime_vod__c asc limit 5];
           // where MSD_CORE_Status__c='Approved' and MSD_CORE_Source__c ='MHEE' and MSD_CORE_Payor__c =: UserInfo.getUserID() and Start_DateTime_vod__c>:dt
            System.debug(LoggingLevel.WARN,'test'+productlst);
            return productlst;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,e.getLineNumber());
            System.debug(LoggingLevel.WARN,e.getMessage());
            return null;
        }
    } 
    /**
     * @description getRequestsCount
     * @param product
     * @param userid
     * @return strSqlQuery
     */   
    @AuraEnabled(cacheable=true)
    public static list<Meeting_Request_vod__c> getRequestsCount(String product, String userid) {
        String strSqlQuery ='Select count(id) , MSD_CORE_Status__c  from Meeting_Request_vod__c where MSD_CORE_Status__c!=null AND MSD_CORE_Payor__c =: userid AND MSD_CORE_Product_Payor__c =: product AND MSD_CORE_Resource__c != null GROUP BY MSD_CORE_Status__c';
        return Database.query(strSqlQuery);
    }
    
    //Display Status wise request count in Requests & appointments
    /**
     * @description getMHEERequestsCount
     * @param userid
     * @return strSqlQuery
     */
    @AuraEnabled(cacheable=true)
    public static list<Meeting_Request_vod__c> getMHEERequestsCount(String userid) {
        String strSqlQuery ='Select count(id) , MSD_CORE_Status__c  from Meeting_Request_vod__c where MSD_CORE_Status__c!=null AND MSD_CORE_Source__c=\'MHEE\'  AND MSD_CORE_Payor__c =: userid  GROUP BY MSD_CORE_Status__c';
        return Database.query(strSqlQuery);
    }

    //Get Request Detail for MHEE as per Source
    /**
     * @description getMHHERequest
     * @param requestType
     * @param pageSize
     * @param pageNumber
     * @param userid
     * @param sortBy
     * @param searchFilter
     * @return requestWrapperobj
     */
    @AuraEnabled(cacheable=true)
    public static RequestWrapper getMHHERequest(String requestType,String pageSize,String pageNumber, String userid,String sortBy,String searchFilter) {
        Integer ps = Integer.valueOf(pageSize);
        Integer pn = Integer.valueOf(pageNumber) - 1;
        Integer offsetValue = ps * pn;
        String sql = '';
        String uID = '\'' + userid +'\'';
        RequestWrapper requestWrapperobj= new RequestWrapper();
        list<Meeting_Request_vod__c> meetingRequestList= new list<Meeting_Request_vod__c>();
        if(!String.isBlank(searchFilter)){
          //  offsetValue = 0;
            string key1 ='\''+'%' + searchFilter+'%' +'\'';
           // searchFilter =' AND ( MHEE_Name__c like' +  key1 + ') ';
           searchFilter ='*'+ searchFilter+'*';
          // // searchFilter='*' + searchFilter+'*';
          //  string soslQuery='FIND {*: searchFilter*} RETURNING Meeting_Request_vod__c (Id where MSD_CORE_Status__c='+ requestType + ' and MSD_CORE_Payor__c='+ userid  +')';
          List<List<SObject>> searchList = [FIND :searchFilter RETURNING Meeting_Request_vod__c (Id where MSD_CORE_Status__c=: requestType  and MSD_CORE_Payor__c=: userid AND MSD_CORE_Source__c='MHEE') ];
           // System.debug('searchList'+ searchList[0]);
                List<Id> meetingIds =new List<Id>();
                String strIDs = '';
                Meeting_Request_vod__c [] meetingobj = (Meeting_Request_vod__c[])searchList[0];

                for (Meeting_Request_vod__c meeting : meetingobj) {
                    meetingIds.add(meeting.Id);
                    strIDs += '\''+meeting.Id+'\',';
                }
                strIDs = strIDs.removeEnd(',');
                
            requestWrapperobj.meetingCount = meetingIds.size();
           system.debug(LoggingLevel.WARN,'IDS' +   strIDs);
         //  system.debug('sql ' + sql);
        //    meetingRequestList = [Select Id,Name,MHEE_Name__c,ScheduleFilter__c, MSD_CORE_Meeting_preference__c, MSD_CORE_Resource__r.Name, Start_DateTime_vod__c, CreatedDate, 
        //                         MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Invitee__c,MSD_CORE_Status__c, 
        //                         (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r) 
        //                         from Meeting_Request_vod__c WHERE Id IN : meetingIds LIMIT :ps OFFSET :offsetValue];
            
            if(strIDs != '') {
                sql = 'Select Id,Name,MHEE_Name__c,ScheduleFilter__c, MSD_CORE_Resource_Type__c, MSD_CORE_Meeting_preference__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE Id IN ('+ strIDs +') ORDER BY ' + sortBy + ' ASC LIMIT '+ ps  +' OFFSET ' + offsetValue;
                system.debug(LoggingLevel.WARN,'sql ' + sql);
                meetingRequestList = Database.query(sql);
            } else {
                meetingRequestList = new List<Meeting_Request_vod__c>();
            }

         // system.debug('meetingRequestList ' + meetingRequestList);
          requestWrapperobj.MeetingRequestList = meetingRequestList;
         //  sql ='Select Id,Name,MHEE_Name__c,ScheduleFilter__c, MSD_CORE_Meeting_preference__c, MSD_CORE_Resource__r.Name, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE Id IN ('+ meetingIds +') ORDER BY ' + sortBy + ' DESC LIMIT '+ ps  +' OFFSET ' + offsetValue;
        }else{
            if(requestType=='Closed'){
                if(String.isBlank(sortBy)){
                    sortBy = 'LastModifiedDate';
                }
                sql ='Select Id,Name,MHEE_Name__c,ScheduleFilter__c,  MSD_CORE_Resource_Type__c, MSD_CORE_Meeting_preference__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE MSD_CORE_Status__c IN (\'Rejected\',\'Closed\') AND MSD_CORE_Payor__c ='+  uID + '    AND MSD_CORE_Source__c=\'MHEE\' ORDER BY ' + sortBy + ' ASC LIMIT '+ ps  +' OFFSET ' + offsetValue;
                system.debug(LoggingLevel.WARN,'sqlclosed ' + 'Select Id,Name,MHEE_Name__c,ScheduleFilter__c from Meeting_Request_vod__c WHERE MSD_CORE_Status__c IN (\'Rejected\',\'Closed\') AND MSD_CORE_Payor__c ='+  uID + '    AND MSD_CORE_Source__c=\'MHEE\' ORDER BY ' + sortBy + ' DESC LIMIT '+ ps  +' OFFSET ' + offsetValue);
               // sql ='Select Id,Name from Meeting_Request_vod__c WHERE MSD_CORE_Status__c IN (\'Rejected\',\'Closed\') AND MSD_CORE_Payor__c ='+  uID +  searchFilter + '  AND MSD_CORE_Source__c=\'MHEE\' ORDER BY ' + sortBy + ' DESC LIMIT '+ ps  +' OFFSET ' + offsetValue;
            }
            else{
                if(requestType=='Pending')
                {
                    if(String.isBlank(sortBy)){
                        sortBy = 'CreatedDate';
                    }
                sql = 'Select Id,Name,MHEE_Name__c, ScheduleFilter__c,  MSD_CORE_Resource_Type__c, MSD_CORE_Meeting_preference__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE MSD_CORE_Status__c =\'Pending\'  AND MSD_CORE_Payor__c = ' + uID +  ' AND MSD_CORE_Source__c=\'MHEE\' ORDER BY ' + sortBy + ' ASC LIMIT '+ ps  +' OFFSET ' + offsetValue;
                }else{
                    if(String.isBlank(sortBy)){
                        sortBy = 'Start_DateTime_vod__c';
                    }
                    sql = 'Select Id,Name,MHEE_Name__c,ScheduleFilter__c,  MSD_CORE_Resource_Type__c, MSD_CORE_Meeting_preference__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, Start_DateTime_vod__c, CreatedDate, MSD_CORE_Request_Resolution__c, MSD_CORE_attendee__c, Assignee_vod__r.name, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Invitee__c,MSD_CORE_Status__c, (SELECT ID, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c FROM Meeting_Times__r)  from Meeting_Request_vod__c WHERE MSD_CORE_Status__c =\'Approved\' AND MSD_CORE_Payor__c =' + uID +  ' AND MSD_CORE_Source__c=\'MHEE\' ORDER BY ' + sortBy + ' ASC LIMIT '+ ps  +' OFFSET ' + offsetValue;
                }
            }
            requestWrapperobj.meetingCount = -1;
            meetingRequestList = Database.query(sql);
            requestWrapperobj.MeetingRequestList = meetingRequestList;
        }
      
        return requestWrapperobj;
    }

    // Get Meeting Request Name
    /**
     * @description getmeetingname
     * @param reqId
     * @return meetreq
     * @return null
     */
    @AuraEnabled
    public static Meeting_Request_vod__c getmeetingname(String reqId){
        try {
            Meeting_Request_vod__c meetreq = [SELECT Id, Name, MSD_CORE_Status__c,MSD_CORE_Resource__r.MSD_CORE_Content_Type__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c FROM Meeting_Request_vod__c WHERE Id =: reqId LIMIT 1];
            // if (meetreq != null) {
            //     return meetreq.Name;
            // }else {
            //     return null;
            // }
            return meetreq;

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,e.getLineNumber());
            System.debug(LoggingLevel.WARN,e.getMessage());
            return null;
        }
    }

    // For Update Meeting Request Status to Closed
     /**
     * @description updatestatus
     * @param reqId
     * @return String
     * @return null
     * @return null
     */
    @AuraEnabled
    public static string updatestatus(String reqId){
        try {
            Meeting_Request_vod__c meetreq = [SELECT Id, Name, MSD_CORE_Status__c FROM Meeting_Request_vod__c WHERE Id =: reqId LIMIT 1];

            if (meetreq != null) {
                meetreq.MSD_CORE_Status__c = 'Closed';
                meetreq.MSD_CORE_Request_Resolution__c = 'Request cancelled';
                meetreq.RecordTypeId = Schema.SObjectType.Meeting_Request_vod__c.getRecordTypeInfosByName().get('Cancelled').getRecordTypeId();
                update meetreq;
                return 'Success';
            }else {
                return null;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,e.getLineNumber());
            System.debug(LoggingLevel.WARN,e.getMessage());
            return null;
        }
    }

    /**
     * @description RequestWrapper
     */
    public class RequestWrapper {
        @AuraEnabled public List<Meeting_Request_vod__c> MeetingRequestList;
        @AuraEnabled public Integer meetingCount;
    }
    
    public class MeetingRequestWrapper {
        @AuraEnabled public List<Meeting_Request_vod__c> listOne { get; set; }
        @AuraEnabled public List<Meeting_Request_vod__c> listTwo { get; set; }
    }
}