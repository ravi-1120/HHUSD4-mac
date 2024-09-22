public class NiceInContactController {
    public static String className = 'NiceInContactController';
    public static String getAccessToken() {
        String responseString = null;
            try {
                 // Fetch all necessary details from custom metadata
                 Nice_In_Contact_Authorization__mdt authorizationDetails = Nice_In_Contact_Authorization__mdt.getInstance('Server_Authorization');
                 if (authorizationDetails != null) {
                    // Retrieve endpoint URL, content type, accept type, clientId, clientSecret, username, password from custom metadata
                    String endPointURL = authorizationDetails.End_Point_URL__c;
                    String contentType = authorizationDetails.Content_Type__c;
                    String acceptType = authorizationDetails.Accept__c;
                    String clientId = authorizationDetails.Client_Id__c;
                    String clientSecret = authorizationDetails.Client_Secret__c;
                    String username = authorizationDetails.User_Name__c;
                    String password = authorizationDetails.Password__c;
                    Blob headerValue = Blob.valueOf(clientId + ':' + clientSecret);
                    String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                    System.debug('Authorization Header is:---->'+authorizationHeader);
                    String reqBody = 'grant_type=password&username=' + username + '&password=' + password;
 
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(endPointURL);
                    request.setMethod('POST');
                    request.setBody(reqBody);
                    request.setHeader('Content-Type', contentType);
                    request.setHeader('Accept', acceptType);
                    request.setHeader('Authorization', authorizationHeader);
                    HttpResponse response = http.send(request);
            
                    if (response.getStatusCode() == 200) {
                        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        responseString = String.valueOf(results.get('access_token'));
                        System.debug('Result is ' + responseString);
                    } else {
                        // Handle non-200 responses appropriately
                        System.debug('getAccessToken response body-->' + String.valueOf(response.getBody()));
                        System.debug('Result is Failed');
                    }
                }
            } catch (Exception e) {
                // Handle exceptions appropriately
                System.debug('Exception in getAccessToken: ' + e.getMessage());
            }
        return responseString;
    }

    public static Map <String,Object> callMeNowHttpRequest(String scheduleDetailsString,String schedulerUniqueId){
        Map <String,Object> responseMap;
        try {
            Map<String, String> scheduleDetails = (Map<String,String>) JSON.deserialize(scheduleDetailsString, Map<String,String>.class);
            Nice_In_Contact_Service_Settings__mdt serviceDetails = [Select MasterLabel,Script_Id__c,Script_Name__c,Skill_Name__c,Skill_Number__c,
                DeveloperName,End_Point_URL__c,Business_Unit_Number__c,Communication_Mode__c,Guid__c
                from Nice_In_Contact_Service_Settings__mdt
                WHERE Skill_Name__c=:scheduleDetails.get('schedulingGroup') AND Communication_Mode__c=:scheduleDetails.get('communicationMode') LIMIT 1];

            if(serviceDetails!=null){
                System.debug('serviceDetails-->'+serviceDetails);
                String url = serviceDetails.End_Point_URL__c;
                String queryParams = '?';
                String scriptName = serviceDetails.Script_Name__c;
                scriptName = scriptName.replace( '\\', '\\' );
                queryParams += 'scriptName='+scriptName+'&bus_no='+serviceDetails.Business_Unit_Number__c+'&scriptId='+serviceDetails.Script_Id__c+'&skill_no='+serviceDetails.Skill_Number__c+'&';
                String dt = String.valueof(Datetime.now());
                dt = dt.replaceAll(' ', '%20'); 
                SYstem.debug('dt-->'+dt);
                String tempProductEnquiry = String.valueOf(scheduleDetails.get('productEnquiry'));
                tempProductEnquiry = EncodingUtil.urlEncode(tempProductEnquiry, 'UTF-8');
                String templateLabel = String.valueOf(scheduleDetails.get('templateLabel'));
                templateLabel = EncodingUtil.urlEncode(templateLabel, 'UTF-8');
                String tempProfessionalDesgination = String.valueOf(scheduleDetails.get('professionalDesignation'));
                tempProfessionalDesgination = EncodingUtil.urlEncode(tempProfessionalDesgination, 'UTF-8');
                String tumorIndication='';
                if(scheduleDetails.get('tumorIndication')!=null){
                    tumorIndication = String.valueOf(scheduleDetails.get('tumorIndication'));
                    tumorIndication = EncodingUtil.urlEncode(tumorIndication, 'UTF-8');
                }
                String tempFirstName = '';
                if(scheduleDetails.get('FirstName')!=null){
                    tempFirstName = String.valueOf(scheduleDetails.get('FirstName'));
                    tempFirstName = EncodingUtil.urlEncode(tempFirstName, 'UTF-8');
                }
                String tempLastName = '';
                if(scheduleDetails.get('LastName')!=null){
                    tempLastName = String.valueOf(scheduleDetails.get('LastName'));
                    tempLastName = EncodingUtil.urlEncode(tempLastName, 'UTF-8');
                }
                queryParams += 'p1='+scheduleDetails.get('Phone');
                queryParams += '&p2='+scheduleDetails.get('Extension');
                queryParams += '&p3='+String.escapeSingleQuotes(tempFirstName)+'%20'+String.escapeSingleQuotes(tempLastName);
                queryParams += '&p4='+schedulerUniqueId;
                queryParams += '&p5='+tempProductEnquiry;
                queryParams += '&p6='+String.escapeSingleQuotes(tumorIndication);
                queryParams += '&p7='+templateLabel;
                //queryParams += '&p8='+System.today();
                queryParams += '&p9='+tempProfessionalDesgination;
                queryParams += '&Guid='+serviceDetails.Guid__c;
                String method = 'GET';
                System.debug('url-->'+url+queryParams);
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                request.setEndpoint(url+queryParams);
                request.setMethod(method);
                request.setHeader('Accept', '*/*');
                response = http.send(request);
                System.debug('re-->'+request);
                if (response.getStatusCode() == 200) {
                    System.debug('callMeNowHttpRequest response body-->'+response.getBody());
                    String spawnId = response.getBody().substringAfter('Contact ID: ');
                    spawnId = spawnId.SubStringBefore('</strong>');
                    System.debug('spawnId-->'+spawnId);
                    responseMap=new Map<String,Object>{
                        'scheduleStatus'=>String.isNotBlank(spawnId)?'Scheduled':'Not Scheduled',
                        'spawnId'=>spawnId,'responseStatusCode'=>response.getStatusCode()
                    };
                }else{
                    responseMap=new Map<String,Object>{'scheduleStatus'=>'Not Scheduled','spawnId'=>'',
                        'responseStatusCode'=>response.getStatusCode()
                    };
                }
                System.debug('res-->'+response);
                System.debug('res code-->'+response.getStatusCode());
            }else{
                AMOExceptionHandler.logRequestResponse('serviceDetails Details empty',scheduleDetailsString,'serviceDetails Details empty','NiceInContactController','callMeNowHttpRequest',null,'Integration');
            }
        }catch(System.CalloutException ex) {
            System.debug('exception-->'+ex);
            AMOExceptionHandler.logException(ex,className,'callMeNowHttpRequest','','Apex');
        }
        return responseMap;
    }
    
    public static Map <String,Object> scheduleCallbackHttpRequest(String scheduleDetailsString,String schedulerUniqueId){
        Map <String,Object> responseMap;
        try {
            Map<String, String> scheduleDetails = (Map<String,String>) JSON.deserialize(scheduleDetailsString, Map<String,String>.class);
            Nice_In_Contact_Service_Settings__mdt serviceDetails = [Select MasterLabel,Script_Id__c,Script_Name__c,Skill_Name__c,Skill_Number__c,
                DeveloperName,End_Point_URL__c,Business_Unit_Number__c,Communication_Mode__c,Guid__c
                from Nice_In_Contact_Service_Settings__mdt
                WHERE Skill_Name__c=:scheduleDetails.get('schedulingGroup') AND Communication_Mode__c=:scheduleDetails.get('communicationMode') LIMIT 1];
            if(serviceDetails!=null){
                System.debug('serviceDetails-->'+serviceDetails);
                String url = serviceDetails.End_Point_URL__c;
                String queryParams = '?';
                String scriptName = serviceDetails.Script_Name__c;
                scriptName = scriptName.replace( '\\', '\\' );
                queryParams += 'scriptName='+scriptName+'&bus_no='+serviceDetails.Business_Unit_Number__c+'&scriptId='+serviceDetails.Script_Id__c+'&skill_no='+serviceDetails.Skill_Number__c+'&';
                String tempProductEnquiry = String.valueOf(scheduleDetails.get('productEnquiry'));
                tempProductEnquiry = EncodingUtil.urlEncode(tempProductEnquiry, 'UTF-8');
                String templateLabel = String.valueOf(scheduleDetails.get('templateLabel'));
                templateLabel = EncodingUtil.urlEncode(templateLabel, 'UTF-8');
                String tempProfessionalDesgination = String.valueOf(scheduleDetails.get('professionalDesignation'));
                tempProfessionalDesgination = EncodingUtil.urlEncode(tempProfessionalDesgination, 'UTF-8');
                String tumorIndication='';
                if(scheduleDetails.get('tumorIndication')!=null){
                    tumorIndication = String.valueOf(scheduleDetails.get('tumorIndication'));
                    tumorIndication = EncodingUtil.urlEncode(tumorIndication, 'UTF-8');
                }
                String tempFirstName = '';
                if(scheduleDetails.get('FirstName')!=null){
                    tempFirstName = String.valueOf(scheduleDetails.get('FirstName'));
                    tempFirstName = EncodingUtil.urlEncode(tempFirstName, 'UTF-8');
                }
                String tempLastName = '';
                if(scheduleDetails.get('LastName')!=null){
                    tempLastName = String.valueOf(scheduleDetails.get('LastName'));
                    tempLastName = EncodingUtil.urlEncode(tempLastName, 'UTF-8');
                }
                queryParams += 'p1='+String.valueOf(scheduleDetails.get('Phone'));
                queryParams += '&p2='+String.valueOf(scheduleDetails.get('Extension'));
                queryParams += '&p3='+String.escapeSingleQuotes(tempFirstName)+'%20'+String.escapeSingleQuotes(tempLastName);
                queryParams += '&p4='+schedulerUniqueId;
                queryParams += '&p5='+tempProductEnquiry;
                queryParams += '&p6='+String.escapeSingleQuotes(tumorIndication);
                queryParams += '&p7='+templateLabel;
                queryParams += '&p8='+scheduleDetails.get('dateValue')+'%20'+scheduleDetails.get('timeSlotValue');
                queryParams += '&p9='+tempProfessionalDesgination;
                queryParams += '&Guid='+serviceDetails.Guid__c;
                String method = 'GET';
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                request.setEndpoint(url+queryParams);
                request.setMethod(method);
                //request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', '*/*');
                response = http.send(request);
                if (response.getStatusCode() == 200) {
                    System.debug('scheduleCallbackHttpRequest response body-->'+String.ValueOF(response.getBody()));
                    String spawnId = response.getBody().substringAfter('Contact ID: ');
                    spawnId = spawnId.SubStringBefore('</strong>');
                    System.debug('spawnId-->'+spawnId);
                    responseMap=new Map<String,Object>{'scheduleStatus'=>String.isNotBlank(spawnId)?'Scheduled':'Not Scheduled',
                        'spawnId'=>(spawnId)!=null?spawnId:'','responseStatusCode'=>response.getStatusCode()
                    };
                }
                else {
                    responseMap=new Map<String,Object>{'scheduleStatus'=>'Not Scheduled','spawnId'=>'',
                        'responseStatusCode'=>response.getStatusCode()
                    };
                }
                System.debug('res-->'+response); 
            }else{
                AMOExceptionHandler.logRequestResponse('serviceDetails Details empty',scheduleDetailsString,'serviceDetails Details empty','NiceInContactController','scheduleCallbackHttpRequest',null,'Integration');
            }
        } catch(System.CalloutException ex) {
            System.debug('exception-->'+ex); 
            AMOExceptionHandler.logException(ex,className,'scheduleCallbackHttpRequest','','Apex');
        }
        return responseMap;
    }
    
    @AuraEnabled
    public static Map <String,Object> getAgentAvilability(Map<String, Object> scheduleDetails){
        Map <String,Object> responseMap;
        try{
            String schedulingGroup = String.valueOf(scheduleDetails.get('schedulingGroup'));
            String communicationMode = String.valueOf(scheduleDetails.get('communicationMode'));
            
            System.debug('Scheduling Group: ' + schedulingGroup);
       		System.debug('Communication Mode: ' + communicationMode);
            Nice_In_Contact_Agent_Availability__mdt serviceDetails = [Select MasterLabel,Skill_Name__c,Skill_Number__c,
                DeveloperName,End_Point_URL__c,Request_Path__c,Communication_Mode__c from Nice_In_Contact_Agent_Availability__mdt
                WHERE Skill_Name__c=:schedulingGroup AND Communication_Mode__c=:communicationMode LIMIT 1];
            if(serviceDetails!=null){
                System.debug('Service Details: ' + serviceDetails);
                System.debug('Nice_In_Contact_Agent_Availability__mdt-->'+serviceDetails);
                String url = serviceDetails.End_Point_URL__c;
                url += serviceDetails.Request_Path__c+serviceDetails.Skill_Number__c+'/'+'activity';
                System.debug('Constructed URL: ' + url);
                String method = 'GET';
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                request.setEndpoint(url);
                request.setMethod(method);
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', 'application/json');
                request.setHeader('Authorization', 'Bearer '+getAccessToken());
                System.debug('HTTP Request: ' + request);
                response = http.send(request);
                System.debug('HTTP Response: ' + response);
                if (response.getStatusCode() == 200) {
                    System.debug('HTTP Response Body: ' + response.getBody());
                    System.debug('getAgentAvilability response body-->'+String.ValueOF(response.getBody()));
                    responseMap = (Map <String,Object> ) JSON.deserializeUntyped(response.getBody());
                }else {
                    String errorMessage = 'Status=' + response.getStatus() + ', Status Code=' + response.getStatusCode();
                    System.debug('Error in HTTP Request: ' + errorMessage);
                    AMOExceptionHandler.logRequestResponse(serviceDetails.Request_Path__c+serviceDetails.Skill_Number__c+'/'+'activity','Status='+String.ValueOF(response.getStatus())+'Status Code='+String.ValueOF(response.getStatusCode()),url,'NiceInContactController','getAgentAvilability',null,'Integration');
                }
            }else{
                
                System.debug('Service Details not found for provided scheduling group and communication mode.');
                AMOExceptionHandler.logRequestResponse('serviceDetails Details empty',JSON.serialize(scheduleDetails),'serviceDetails Details empty','NiceInContactController','getAgentAvilability',null,'Integration');
            }
        }catch(exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'getAgentAvilability','','Apex');
        }
        System.debug('Returning Response Map: ' + responseMap);
        return responseMap;
    }
    
}