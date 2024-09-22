/*
    Created by -  RK Koluri
    Description - Controller class to define Business Rules
    Last Modified By - Joshi Jigyasu
    Last Modified Date - 25-05-2023
*/
public with sharing class BusinessRulesController {
    public static String className = 'BusinessRulesController';
    
    public class TemplatesGroupsMapping {
        @AuraEnabled public String groupName;
        @AuraEnabled public Id groupId;
        @AuraEnabled public String professionalDesignation;
        @AuraEnabled public String template;
        @AuraEnabled public String businessHours;
        @AuraEnabled public String operatingHours;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TemplatesGroupsMapping> getTemplatesMapping(){
        List<TemplatesGroupsMapping> tMappingList = new List<TemplatesGroupsMapping>();
        try{
        List<Scheduling_Groups__c> groups = [select id,Operating_Hours__r.Name, name,Operating_Hours_Message__c, IsActive__c from Scheduling_Groups__c where IsActive__c = true];
        for(Scheduling_Groups__c gObj : groups){
            TemplatesGroupsMapping tMapObj = new TemplatesGroupsMapping();
            tMapObj.groupName = 'Group Name - '+gObj.name;
            tMapObj.groupId = gObj.id;
            tMapObj.businessHours = gObj.Operating_Hours_Message__c;
            tMapObj.operatingHours = gObj.Operating_Hours__r.Name;
            tMappingList.add(tMapObj);
        }
    }catch(Exception ex){
        System.debug('ex-->'+ ex);
        AMOExceptionHandler.logException(ex,className,'getTemplatesMapping','','Apex');

    }
        return tMappingList;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,List<String>> getSelectedTemplates(String recordId){
        List<String> templateNames = new List<String>();
        List<String> productsList = new List<String>();
        Map<String,List<String>> templatesMap = new Map<String,List<String>>();
        try{
        Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
        ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(configRecord.JSON_Payload__c, ScheduleRequest.class);
        for(ScheduleRequest.templates str : payload.templates){
            if(str.isSchedulable){
                templateNames.add(str.label);
            }
        }
        for(ScheduleRequest.products pro : payload.products){
            productsList.add(pro.label);
        }
        templatesMap.put('templates', templateNames);
        templatesMap.put('products', productsList);
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'getSelectedTemplates','','Apex');
        }
        return templatesMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<Group_Holidays__c> getHolidays(String groupId){
        return [Select Id,  Holiday__r.Name,Holiday__r.Date__c from Group_Holidays__c where Scheduling_Group__c =: groupId and Holiday__r.Date__c = THIS_YEAR ];
    }


    @AuraEnabled
    public static String saveHolidays(String holidayName, String holidayDate, String groupId){
        Holidays__c newHoliday = new Holidays__c();
        Group_Holidays__c grpHoliday = new Group_Holidays__c();
        try{
            newHoliday.Name = holidayName;
            newHoliday.Date__c = Date.valueOf(holidayDate);
            insert newHoliday;
            
            grpHoliday.Holiday__c = newHoliday.Id;
            grpHoliday.Scheduling_Group__c  = groupId;
            insert grpHoliday;
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'saveHolidays','','Apex');
        }
        return (String.isNotBlank(newHoliday.ID) && String.isNotBlank(grpHoliday.ID)) ? 'SUCCESS' : 'ERROR';
    }

    @AuraEnabled
    public static void addHolidaysByGroup(String recordId){
        try{
            Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
            ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(configRecord.JSON_Payload__c, ScheduleRequest.class);
            List<Scheduling_Groups__c> groups = [select id, name, IsActive__c, (select id, name, Holiday__c, Holiday__r.name, Holiday__r.Date__c from Group_Holidays__r) from Scheduling_Groups__c where IsActive__c = true];
            List<ScheduleRequest.HolidaysByGroup> wrapperList = new List<ScheduleRequest.HolidaysByGroup>();
            for(Scheduling_Groups__c gObj : groups){
                ScheduleRequest.HolidaysByGroup hObj = new ScheduleRequest.HolidaysByGroup();
                hObj.groupName = gObj.Name;
                hObj.groupId = gObj.Id;
                hObj.holidays = new List<String>();
                for(Group_Holidays__c ghObj : gObj.Group_Holidays__r){
                    hObj.holidays.add(String.valueOf(ghObj.Holiday__r.Date__c));    
                }
                wrapperList.add(hObj);    
            }
            System.debug('holidaysByGrp '+ JSON.serialize(wrapperList));
            payload.holidaysByGroup=wrapperList;
            configRecord.JSON_Payload__c = JSON.serializePretty(payload, true);
            update configRecord;
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'addHolidaysByGroup','','Apex');

        }
    }

    @AuraEnabled
    public static String getCallRouting(List<String> appointmentTemplates,List<String> products,String recordId){
        String decisionString;
        try {
            List<String> profDesignationList= new List<String>();
            Schema.DescribeFieldResult fieldResult = Event.Professional_Designation__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                profDesignationList.add(pickListVal.getLabel());
            }
            List<Object> grpObj = new List<Object>();
            for(Scheduling_Groups__c grp :[Select Id,Name FROM Scheduling_Groups__c]){
                grpObj.add(new Map<String, String> {'groupId' => grp.Id,'groupName' => grp.Name});
            }
            Map<String,List<Object>> schedulingGroupsObj = new Map<String,List<Object>> ();
            schedulingGroupsObj.put('appointmentTemplate', new List<String> (appointmentTemplates));
            schedulingGroupsObj.put('professionalDesignation',new List<String> (profDesignationList));
            schedulingGroupsObj.put('product',new List<String> (products));
            Map<String,Object> schedulingGroupsMap = new Map<String,Object> ();
            schedulingGroupsMap.put('schedulingGroups',schedulingGroupsObj);
            schedulingGroupsMap.put('groupInfo',new List<Object>(grpObj));
            System.debug('schedulingGroupsMap-->'+schedulingGroupsMap);
            Map<String,Object> tempresponse = new Map<String,Object>();
            decisionString = getDecisionByRules(schedulingGroupsMap);
            System.debug('decisionString-->'+decisionString);
            tempresponse= (Map<String,Object>)JSON.deserializeUntyped(decisionString);
            String tempDecisionString = decisionString.substring(1, decisionString.length() - 1);
            tempDecisionString = tempDecisionString.removeEnd('}');
            //tempDecisionString = tempDecisionString.replaceAll('professionalDesignation', 'profesionalDesgination');
            Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
            String payload = String.valueOf(configRecord.JSON_Payload__c);
            System.debug('tempDecisionString-->'+tempDecisionString);  
            payload = payload.replace('"assignmentGroups" : [ ]', tempDecisionString);
            configRecord.JSON_Payload__c = payload;
            update configRecord;
        } catch (Exception ex) {
            System.debug('ex-->'+ ex);
            System.debug('ex-line->'+ ex.getLineNumber());
            AMOExceptionHandler.logException(ex,className,'getCallRouting','','Apex');
        }
        return decisionString;
    }
    
    @AuraEnabled
    public static string getDecisionByRules(Map<String,Object> schedulingGroupsMap){
        String routingResponse = '';
        try {
            String jsonBody = json.serialize(schedulingGroupsMap);
            Aws_Api_Settings__mdt authorzationDetails = Aws_Api_Settings__mdt.getInstance('AMO_Decision_Manager');
            if ( authorzationDetails != null ){
                String endpoint = authorzationDetails.Hostname__c+authorzationDetails.End_Point_URL__c;
                System.debug('jsonBody-->'+jsonBody);
                String method = 'POST';
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                // request.setEndpoint('https://6dm9ax3raj.execute-api.us-east-2.amazonaws.com/test/assignment-groups');
                request.setEndpoint(endpoint);
                request.setMethod(method);
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', '*/*');
                request.setHeader('x-api-key', authorzationDetails.Api_Key__c);
                request.setBody(jsonBody);
                request.setTimeout(120000);
                response = http.send(request);
                system.debug('response.getStatusCode():'+response.getStatusCode());
                if (response.getStatusCode() == 200) {
                    System.debug('res--->'+response.getBody());
                    routingResponse = String.valueOf(response.getBody());
                }
            }
        } catch (Exception ex) {
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'getDecisionByRules','','Apex');
        }
        return routingResponse;
    }

}