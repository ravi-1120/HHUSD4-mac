/*
* Company		: Merck Co.
* Date			: 07-02-2018	
* Author		: Ramesh Elapakurthi
* Description	: Class to encapsulate AWS Api(Real-time-bus) to submit data like PIR.
* History		: First version
* 				: KRB 10/19/2022 22R4.1 - Parent account needs to be passed with account. 
*/
public class MSD_CORE_AwsApiIntegration {
    
    
    /* Method: submitPirToBus
	 * Description: Async Method to submit PIR Medical_Information__c to RTB.
		- It accepts multiple Medical_Information__c Ids.
		- It queries Medical_Information__c object with all Ids
		- Builds the case information to be submitted to RTB
		- Formats the data into a JSON String
		- Invokes RTB Api 
	*/
    @future(callout=true)
    public static void submitPirToBus(List<String> pirIdList) {
        
        Http h = new Http();
        HttpRequest req; 
        HttpResponse res=null; 
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = piRequestInfo();
        String requestId = generateNewRequestId();
        MSD_CORE_Aws_Api__c awsApi = awsApiSettings();
        
        //KRB 10/19/2022 22R4.1 - required for Parent Account requirement
        Set <Id> PrimaryParentNullAccountIdSet = new Set <Id>();
        List <Id> PrimaryParentNullAccountIdList = new List <Id>();
        List <Child_Account_vod__c> parentAccounts = new List <Child_Account_vod__c>();

        
        try{
            //KRB 10/19/2022 22R4.1 - updated queryPirData method to return Primary Parent Name
            List<Medical_Inquiry_vod__c> pDataList = queryPirData(pirIdList);
            
            //KRB 10/19/2022 22R4.1 Start - addition logic added to process account Parents.
            for(Medical_Inquiry_vod__c medInqry: pDataList){
               system.debug('Account_vod__c: ' + medInqry.Account_vod__c + ' medInqry.Account_vod__r.Primary_Parent_vod__r.name: ' + medInqry.Account_vod__r.Primary_Parent_vod__r.name);  
    
               if ((String.isBlank(medInqry.Account_vod__r.Primary_Parent_vod__r.name)) && (String.isNotBlank(medInqry.Account_vod__c))){
                  System.debug('Primary Parent was blank/null...adding Account Id to Set...');
                  PrimaryParentNullAccountIdSet.add(medInqry.Account_vod__c);
               }
            }

            if (!PrimaryParentNullAccountIdSet.isEmpty()){
               //Transfer the Set to a List for Querying...
               for(Id acctId: PrimaryParentNullAccountIdSet){
                  PrimaryParentNullAccountIdList.add(acctId);    
               }
            }
            
            //Pull list of Parent Accounts for given Children Accounts...
            parentAccounts = [SELECT Child_Account_vod__c, Parent_Name_vod__c 
                              FROM   Child_Account_vod__c 
                              WHERE  Parent_Name_vod__c != null
		 			          AND    Parent_Account_vod__c != null
				              AND    Inactive_MRK__c = false
				              AND    Parent_Account_vod__r.Status_MRK__c = 'ACTIVE'
                              AND    Child_Account_vod__c IN :PrimaryParentNullAccountIdList];

            //KRB 10/19/2022 22R4.1  End - addition logic added to process account Parents.
           
            //KRB 10/19/2022 22R4.1 - added addition Parameter to the buildPirData Method to pass in Parent List.
            //List<MSD_CORE_PirData> pirList = buildPirData(pDataList, pirInfo);
            List<MSD_CORE_PirData> pirList = buildPirData(pDataList, pirInfo, parentAccounts);
            
            String sourceSystem = '';
            If(pirList.get(0).case_source ==pirInfo.MS_Case_Source__c)
            	sourceSystem = pirInfo.MS_Source_System__c;
            else
                sourceSystem = pirInfo.FS_Source_System__c;
            MSD_CORE_PIRequest piRequest = new MSD_CORE_PIRequest(pirInfo, pirList, requestId, sourceSystem);
            
            String pirDataJson = serializePir(piRequest);
            System.debug('pir data json'+ pirDataJson);
            
            req = buildWebServiceRequest(pirDataJson, awsApi);
            
            res = invokeAwsApi(h,req); 
            
            //Save PIRequest response
            saveRequestStatus(requestId,pirIdList,res,sourceSystem,'');
            
        } catch(System.Exception e){
            System.debug('Error submitting PIR Request:'+ e);
            
            //Insert a record into MSD_CORE_PIR_Request__c
            saveRequestStatus(requestId,pirIdList, res,pirInfo.FS_Source_System__c, e.getMessage());
        }
        
    }
    
    /* Method: submitCaseToBus
    * Description: Async Method to submit PIR Cases to RTB.
    - It accepts multiple Case Ids.
    - It queries Case object with all case Ids
    - Builds the case information to be submitted to RTB
    - Formats the data into a JSON String
    - Invokes RTB Api 
	- Saves the response to MSD_CORE_PIR_Request__c for Retry when failed.
	- Saves the cases to Integration Log for Admin purpose
	- Updates Integration Status in Case object to submit a case only once to IRMS.
	*/
    @future(callout=true)
    public static void submitCaseToBus(List<String> pirCaseList){
        
        Http h = new Http();
        HttpRequest req; 
        HttpResponse res=null;
        String requestId = generateNewRequestId();
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = piRequestInfo();
        MSD_CORE_Aws_Api__c awsApi = awsApiSettings();
        try{
            List<Case> casePir = queryCasePirs(pirCaseList);
            
            List<MSD_CORE_PirData> pirList = buildPirCaseData(casePir, pirInfo);
            
            MSD_CORE_PIRequest piRequest = new MSD_CORE_PIRequest(pirInfo, pirList, requestId, pirInfo.SC_Source_System__c);
            
            String pirDataJson = serializePir(piRequest);
            
            req = buildWebServiceRequest(pirDataJson, awsApi);
            
            res = invokeAwsApi(h,req); 
            
            //Save to Integration log 
            if(res.getStatusCode() == 200){
                system.debug('response from RTB is successful');
                updateCaseIntegrationStatus(pirCaseList);
            	saveCaseToIntegrationLog(pirCaseList);  
                
            }
            
            //Save PIRequest response
            saveRequestStatus(requestId,pirCaseList,res,pirInfo.SC_Source_System__c,'');
           
            
        } catch( System.Exception e) {
            System.debug('Error submitting PIR Request:'+ e);
            
            //Insert a record into MSD_CORE_PIR_Request__c
            saveRequestStatus(requestId,pirCaseList, res, pirInfo.SC_Source_System__c, e.getMessage());
        }
        
    }
    
    /*
     * Method: saveIntegrationLog
     * Description: Inserts a record into IntegrationLog object once pir case is submitted to RTB
	*/
    public static void saveCaseToIntegrationLog(List<String> pirCaseList){
        List<Case> casePir = queryCasePirs(pirCaseList);
        List<MSD_CORE_Integration_Logs__c> integrationLog = new List<MSD_CORE_Integration_Logs__c>();
        for(Case c: casePir){
            MSD_CORE_Integration_Logs__c log = new MSD_CORE_Integration_Logs__c();
            log.MSD_CORE_Case__c = c.Id;
            log.MSD_CORE_Description__c = 'Data Sent to MIIGS';
            log.MSD_CORE_Destination_Recipient__c = 'Real-time-bus/MIIGS';
            log.MSD_CORE_Case_Type__c = 'MIIGS';
            log.MSD_CORE_Transmission_Date__c = System.now();
            integrationLog.add(log);
        }
        insert integrationLog;
        
        
    }
    /*
     * Method: updateCaseIntegrationStatus
     * Description: Updates Case Integration Status after submitting it to RTB.
	*/
    public static void updateCaseIntegrationStatus(List<String> pirCaseList){
        try{
            List<Case> casePir = queryCasePirs(pirCaseList);
            for(Case c: casePir){
                c.MSD_CORE_RTB_Integration_Status__c = 'Processed to IRMS';
            }
            
            update casePir;
        } catch(System.Exception e){
            throw e;
        }
    }
    /*
    * Method: scPirRetryCount
    * Description: Retrives the number of retries of a Medical_Request__c using Id 
    * This can handle multiple Ids.
    */
    public static Map<String, Integer> veevaPirRetryCount(List<String> pirIdList, String retryStatus){
        
        System.debug('Querying Retry Count for status ' +  retryStatus);
        System.debug(pirIdList);
        
        List<AggregateResult> pirRetries = [SELECT count(Name) RetryCount,PIR_Id__c 
                                            FROM MSD_CORE_PIR_Request__c 
                                            WHERE PIR_Id__c IN : pirIdList AND Status__c =:retryStatus
                                            Group By PIR_Id__c];
        
        Map<String, Integer> pirsRetryCount = new Map<String, Integer>();
        
        for(AggregateResult pir: pirRetries){
            
            System.debug((String)pir.get('PIR_Id__c'));
            System.debug('Retry Count:');
            System.debug((Integer)pir.get('RetryCount'));
            pirsRetryCount.put((String)pir.get('PIR_Id__c'),(Integer)pir.get('RetryCount'));    
        }
        return pirsRetryCount;
        
    }
    /*
    * Method: scPirRetryCount
    * Description: Retrives the number of retries of a Case using Case number
    * This can handle multiple case Ids.
    */
    
    public static Map<String, Integer> scPirRetryCount(List<String> pirIdList, String retryStatus){
        
        List<AggregateResult> pirRetries = [SELECT count(Name) RetryCount,Case_Id__c 
                                            FROM MSD_CORE_PIR_Request__c 
                                            WHERE Case_Id__c IN : pirIdList AND Status__c =:retryStatus
                                            Group By Case_Id__c];
        
        Map<String, Integer> pirsRetryCount = new Map<String, Integer>();
        
        for(AggregateResult pir: pirRetries){
            pirsRetryCount.put((String)pir.get('Case_Id__c'),(Integer)pir.get('RetryCount'));    
        }
        
        return pirsRetryCount;
        
    }
    
    /*Method: saveRequestStatus
     *Description: Saves the response of a request to Real-time-bus.
     *Possible Status values:
        - REQ_STATUS_COMPLETED: Successful completion of request to Real-time-bus
        - REQ_STATUS_RETRY: When a response to the request submitted to RTB is one of the following values
            -> 408: Request Timeout
            -> 503: Service Unavailable
            -> 504: Gateway Timeout
        - REQ_STATUS_ERROR: When a response to the request submitted to RTB returns an error.
    */
    public static void saveRequestStatus(String requestId,List<String> pirIdList, HttpResponse res,String sourceSystem, String error){
        
        String status = '';
        String msg = '';
        Map<String, Integer> pirRetries = null;
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = piRequestInfo();
        
        if(sourceSystem == pirInfo.SC_Source_System__c)
            pirRetries = scPirRetryCount(pirIdList, pirInfo.Request_Retried__c);
        else
            pirRetries = veevaPirRetryCount(pirIdList,pirInfo.Request_Retried__c);
            
        
        MSD_CORE_Aws_Api__c awsApi = awsApiSettings();
        
        if(res == null){
            status = pirInfo.Request_Error__c;// REQ_STATUS_ERROR;
            msg = 'Error submitting PIR data to AWS:-' + error;
        }
        else if(res.getStatusCode() == 200){
            status = pirInfo.Request_Completed__c; //REQ_STATUS_COMPLETED;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getStatus();
        }
        else if(res.getStatusCode() == 408 || res.getStatusCode() == 504 || res.getStatusCode()==503 ){
            status = pirInfo.Request_Retry__c; //REQ_STATUS_RETRY;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getBody() + error;
        }else{
            
            status = pirInfo.Request_Error__c; //REQ_STATUS_ERROR;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getBody() + error;
        }
        
        List<MSD_CORE_PIR_Request__c> requests = new List<MSD_CORE_PIR_Request__c>();
        for(String srcId : pirIdList){
            
            MSD_CORE_PIR_Request__c pirReq = new MSD_CORE_PIR_Request__c();
            
            //There are only two possible Ids: Medical_Inquiry__c Id or Case Id
            if(sourceSystem == pirInfo.SC_Source_System__c )
                pirReq.Case_Id__c = srcId;
            else
                pirReq.PIR_Id__c = srcId;
            
            pirReq.Request_Id__c = requestId;
            pirReq.Message__c = msg;
            
            if(pirRetries.containsKey(srcId) && pirRetries.get(srcId) >= awsApi.Max_Retries__c){
                System.debug('srcId Count');
                System.debug(pirRetries.get(srcId));
                status = pirInfo.Request_Failed__c;  //REQ_STATUS_FAILED;
            }
                
            
            pirReq.Status__c = status;
            pirReq.Source_System__c = sourceSystem;
            pirReq.Timestamp__c = System.now();
            requests.add(pirReq);
        } 
        insert requests;
        //Database.upsert(requests);
    }       
    
    public static List<Case> queryCasePirs(List<String> pirCaseIds) {
        
        List<Case> pirCases = [SELECT Id ,CaseNumber,MSD_CORE_Integration_Status__c ,Type, MSD_CORE_Customer_Contact_Salutation__c,Account.Credentials_vod__c,
                               Account.FirstName, Account.LastName,case_AddressLine1_MVN__c,Owner.FirstName, Owner.LastName,
                               MSD_CORE_Global_MedInfo_Delivery_Method__c,case_AddressLine2_MVN__c,case_City_MVN__c,MSD_CORE_Business_Name__c,
                               case_State_MVN__c,case_Postal_Code_MVN__c,case_Country_MVN__c, case_Account_Phone_MVN__c,
                               case_Account_Fax_MVN__c,case_Account_Email_MVN__c,MSD_CORE_PIR_Concept_Code__c,
                               Product_MVN__r.Name, Case.Details_MVN__c, Referred_By_MVN__r.Preferred_First_Name_MRK__c, 
                               Referred_By_MVN__r.Preferred_Last_Name_MRK__c, Referred_By_MVN__r.Class_of_Trade_MRK__c,
                               Referred_By_MVN__r.MSD_CORE_Merck_Employee_ID__c, Referred_By_MVN__r.MSD_CORE_Employee_Alias__c, Address_MVN__c, AccountId, Account.Merck_ID_MRK__c, Address_MVN__r.Merck_Address_ID_MRK__c
                               FROM Case WHERE Id IN :pirCaseIds];
        return pirCases;
    }
    
    public static List<MSD_CORE_PirData> buildPirCaseData(List<Case> pirCases, MSD_CORE_RTB_Pir_Request_Info__c pirInfo){
        
        List<MSD_CORE_PirData> pirList = new List<MSD_CORE_PirData>();
        for(Case c : pirCases){
            MSD_CORE_PirData pd = new MSD_CORE_PirData(c,pirInfo, getUTCDateTime(System.now()));
            pirList.add(pd);
        }
        return pirList;
    }
    
    
    //Query the PIR object with Id
    public static List<Medical_Inquiry_vod__c> queryPirData(List<String> pirIdList) {
        //KRB 10/19/2022 22R4.1 - added Account_vod__r.Primary_Parent_vod__r.name to Select
        List<Medical_Inquiry_vod__c> pDataList = [SELECT Id ,Name, RecordType.Name,RecordType.DeveloperName, Salutation_MRK__c,Account_vod__c,Account_vod__r.Credentials_vod__c, Account_vod__r.Primary_Parent_vod__r.name,
                                                  Account_vod__r.FirstName, Account_vod__r.LastName,Address_Integration_MRK__c,Address_Line_1_vod__c,Delivery_Method_vod__c,
                                                  Address_Line_2_vod__c,City_vod__c,State_vod__c,Zip_vod__c ,Country_vod__c, Phone_Number_vod__c,
                                                  Fax_Number_vod__c,Email_vod__c,PIR_Concept_Number_MRK__c,PIR_Concept_Product_MRK__c,PIR_Product_MRK__c ,
                                                  Status_vod__c, LastModifiedDate, Inquiry_Text__c,Last_GPIR_Update_MRK__c,CreatedBy.FirstName,CreatedBy.LastName, CreatedBy.Alias
                                                  FROM Medical_Inquiry_vod__c WHERE id IN :pirIdList];
        system.debug('Id is:'+pDataList.get(0).Id);
        
        return pDataList;
    }
    
    //This method builds the PIR to be sent to BUS with defaults and formula fields. 
    //KRB 10/19/2022 22R4.1 - updated method signature to accept a List of Parents...
    public static List<MSD_CORE_PirData> buildPirData(List<Medical_Inquiry_vod__c> pDataList, MSD_CORE_RTB_Pir_Request_Info__c pirInfo, List<Child_Account_vod__c> parentAccountList) {
        
        List<MSD_CORE_PirData> pirList = new List<MSD_CORE_PirData>{};
            for(Medical_Inquiry_vod__c pData : pDataList){

                //KRB 10/19/2022 22R4.1 - updated the method to include the Parent List
                //MSD_CORE_PirData pd = new MSD_CORE_PirData(pData,pirInfo, getUTCDateTime(System.now()));
                MSD_CORE_PirData pd = new MSD_CORE_PirData(pData,pirInfo, getUTCDateTime(System.now()), parentAccountList );

                pirList.Add(pd);
            }
        return pirList;
        
    }
    
    public static HttpResponse invokeAwsApi(Http h, HttpRequest req) {
        
        HttpResponse  res = h.send(req);
        return res;
    }
    
    public static MSD_CORE_Aws_Api__c awsApiSettings(){
        return MSD_CORE_Aws_Api__c.getOrgDefaults();
    }
    public static MSD_CORE_RTB_Pir_Request_Info__c  piRequestInfo() {
        return  MSD_CORE_RTB_Pir_Request_Info__c.getOrgDefaults();
    } 
    
    //builds request object 
    public static HttpRequest buildWebServiceRequest(String pirDataJson, MSD_CORE_Aws_Api__c awsApi) {
        
        HttpRequest req = new HttpRequest();
        system.debug('building webservice request..');
        system.debug('HostName:' + awsApi.Hostname__c);
        req.setHeader('x-api-key', awsApi.Api_Key__c);
        req.setEndpoint('https://' + awsApi.Hostname__c + awsApi.Pir_Endpoint_Url__c);
        req.setMethod('POST');
        req.setBody(pirDataJson);
        system.debug('req:'+ req);
        return req;
    }
    
    //Method to format pirList to JSON to submit it to BUS
    public static String serializePir(MSD_CORE_PIRequest  piRequest) {
        
        String jsonPirString = JSON.serialize(piRequest,true); //ignores null fields
        system.debug('Pir Data JSON String: '+jsonPirString);
        return jsonPirString;
    }
    
    //Generates a unique requestid for each PIR request submitted to IRMS
    public static String generateNewRequestId(){
        
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        //UUID format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        String requestid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        
        system.debug(requestid);
        
        return requestid;
    }
    
    public static DateTime getUTCDateTime(DateTime dt){
        
        Datetime GMTDate = Datetime.newInstanceGmt(
            dt.yearGmt(),
            dt.monthGmt(),
            dt.dayGmt(),
            dt.hourGmt(),
            dt.minuteGmt(),
            dt.secondGmt());
        return GMTDate;
    }
}