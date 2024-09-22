/*
Class: MSD_CORE_Submit_MIR_To_RTB_Controller 
Purpose: This is for Support team to be able to push records from VEEVA/SC to RTB. This is only used by Support team.
Author: Ramesh Elapakurthi
*/
public class MSD_CORE_Submit_MIR_To_RTB_Controller {
    
    public List<MIRQueryResult> queryResult { get; set; }
    Public string result{get;set;}
    Public string caseIds{get;set;}
    
    
    public PageReference submitRequest() {
        try{
            if(queryResult==null || queryResult.size() == 0)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'No Records to Submit.Please query before submitting.'));
                return null;
                
            }
            List<String> mirIds = new List<String>();
            for(MIRQueryResult res: queryResult){
                mirIds.add(res.RecordId);
            }
            
            if(sourceType == 'VEEVACRM'){
                
                MSD_CORE_AwsApiIntegration.submitPirToBus(mirIds);
                
            }
            else if(sourceType == 'AE'){
                List<MSD_CORE_PIR_Request__c> aeRequests = new List<MSD_CORE_PIR_Request__c> ();
                aeRequests = [SELECT Id,Case_Id__c, Status__c,MSD_CORE_Retry_Count__c,Request_Id__c,Message__c FROM MSD_CORE_PIR_Request__c WHERE Case_Id__c in :mirIds AND Status__c in ('ERROR','FAILED') AND MSD_CORE_Case_Type__c = 'AE'];
                system.debug('@@@@aeRequests'+aeRequests.size());
                MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_AERTBCaseJsonClass.scRTBAEPQCRequestInfo();
                List<case> caseRecs = [select Id,Status,ParentId,Parent.CaseNumber,Parent.MSD_CORE_PQC_Present__c,Parent.MSD_CORE_ChatUniqueID__c,
                             CaseNumber,MSD_CORE_DHS_Number__c,MSD_Core_Multiple_Patients_Involved__c,OwnerId,Owner.Name,Patient_First_Name_MVN__c,Patient_Last_Name_MVN__c,
                             MSD_CORE_AE_Patient_Date_of_Birth__c,MSD_CORE_AE_Patient_Age__c,
                             MSD_CORE_AE_Patient_Gender__c,MSD_CORE_AE_Is_Patient_Pregnant__c,
                             MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,
                             MSD_CORE_AE_Indication__c,MSD_CORE_AE_Therapy_Start_Date__c,MSD_CORE_AE_Route_of_Administration__c,
                             MSD_CORE_AE_Concomitant_Medication__c,MSD_CORE_AE_Pertinent_Medical_History__c,MSD_CORE_AE_Drug_Reactions_Allergies__c,
                             MSD_CORE_AE_Description__c,MSD_CORE_AE_Was_Treatment_Given_for_AE__c,MSD_CORE_AE_Treatment_Provided__c,
                             AE_Start_Date_MVN__c,MSD_CORE_AE_Lab_Diagnostics_Studies__c,MSD_CORE_AE_Was_Therapy_Discontinued__c,
                             MSD_CORE_AE_Recovery_Date__c,MSD_CORE_AE_Therapy_End_Date__c,MSD_CORE_AE_Dechallenge__c,MSD_CORE_AE_Present_Status__c,
                             MSD_CORE_AE_Rechallenge__c,MSD_CORE_AE_Sought_Medical_Attention__c,MSD_CORE_AE_Intervention_Prevent_Serious__c,
                             MSD_CORE_AE_Is_Was_the_AE_Cancer__c,MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c,MSD_CORE_AE_Did_the_Patient_Die__c,
                             MSD_CORE_AE_Cause_of_Death__c,MSD_CORE_AE_Date_of_Death__c,MSD_CORE_AE_Sig_Disability_or_Incapacity__c,
                             MSD_CORE_AE_Hospitalization_or_Prolonged__c,MSD_CORE_AE_Life_Threatening__c,MSD_CORE_AE_Patient_Overdose__c,
                             MSD_CORE_PQC_Present__c,MSD_CORE_MARRS_Number__c,MSD_CORE_ChatUniqueID__c,MSD_CORE_Event_Case_Type__c,
                             MSD_CORE_Customer_Feedback__c,MSD_CORE_Customer_FeedbackClassification__c,MSD_CORE_CDT__c,MSD_CORE_Alert_Security__c,
                             MSD_CORE_Legal_Alert__c,MSD_CORE_PSP_Program_Name__c,MSD_CORE_PSP_Program_Name_Other__c,MSD_CORE_PSP_Company__c,
                             MSD_CORE_PSP_Company_Other__c,MSD_CORE_PSP_Number__c,MSD_CORE_PSP_Number_Other__c,MSD_CORE_PSP_Agent_Name__c,
                             MSD_CORE_PQC_User_Experience__c,MSD_CORE_Operator_of_Device__c,MSD_CORE_PQC_Priority__c,MSD_CORE_PQC_QIR_Requested__c,
                             MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,MSD_CORE_Integration_Processed_Dt__c,MSD_CORE_To_Be_Processed__c,MSD_CORE_AEATN_To_be_Processed__c
                             FROM Case 
                                       WHERE Id in :mirIds AND MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only')];
                List<MSD_CORE_AERequest.ServiceCloudSafetyCase> aeList = new List<MSD_CORE_AERequest.ServiceCloudSafetyCase>();
                if(mirIds.size() > 0)
                {            
                    aeList =  MSD_CORE_AERTBCaseJsonClass.getJSONWrap(mirIds,caseRecs,system.now());
                    MSD_CORE_AERTBCaseJsonClass.submitAeToPv(aeList, system.now(),reqInfo,aeRequests);
                }
                 system.debug('@@@@aeRequests'+aeList.size());
                
                
            }
             else if(sourceType == 'PQC'){
                List<MSD_CORE_PIR_Request__c> pqcRequests = new List<MSD_CORE_PIR_Request__c> ();
                pqcRequests = [SELECT Id,Case_Id__c, Status__c,MSD_CORE_Retry_Count__c,Request_Id__c,Message__c FROM MSD_CORE_PIR_Request__c WHERE Case_Id__c in :mirIds AND Status__c in ('ERROR','FAILED') AND MSD_CORE_Case_Type__c = 'PQC Only'];
                system.debug('@@@@PQCRequests'+pqcRequests.size());
                MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
                List<case> caseRecs = [select Id,Status,ParentId,Parent.CaseNumber,Parent.MSD_CORE_PQC_Present__c,Parent.MSD_CORE_ChatUniqueID__c,
                                       CaseNumber,OwnerId,Owner.Name,Patient_First_Name_MVN__c,Patient_Last_Name_MVN__c,
                                       MSD_CORE_AE_Patient_Date_of_Birth__c,MSD_CORE_AE_Patient_Age__c,
                                       MSD_CORE_AE_Patient_Gender__c,MSD_CORE_AE_Is_Patient_Pregnant__c,
                                       MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,
                                       MSD_CORE_AE_Indication__c,MSD_CORE_AE_Therapy_Start_Date__c,MSD_CORE_AE_Route_of_Administration__c,
                                       MSD_CORE_AE_Concomitant_Medication__c,MSD_CORE_AE_Pertinent_Medical_History__c,MSD_CORE_AE_Drug_Reactions_Allergies__c,
                                       MSD_CORE_AE_Description__c,MSD_CORE_AE_Was_Treatment_Given_for_AE__c,MSD_CORE_AE_Treatment_Provided__c,
                                       AE_Start_Date_MVN__c,MSD_CORE_AE_Lab_Diagnostics_Studies__c,MSD_CORE_AE_Was_Therapy_Discontinued__c,
                                       MSD_CORE_AE_Recovery_Date__c,MSD_CORE_AE_Therapy_End_Date__c,MSD_CORE_AE_Dechallenge__c,MSD_CORE_AE_Present_Status__c,
                                       MSD_CORE_AE_Rechallenge__c,MSD_CORE_AE_Sought_Medical_Attention__c,MSD_CORE_AE_Intervention_Prevent_Serious__c,
                                       MSD_CORE_AE_Is_Was_the_AE_Cancer__c,MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c,MSD_CORE_AE_Did_the_Patient_Die__c,
                                       MSD_CORE_AE_Cause_of_Death__c,MSD_CORE_AE_Date_of_Death__c,MSD_CORE_AE_Sig_Disability_or_Incapacity__c,
                                       MSD_CORE_AE_Hospitalization_or_Prolonged__c,MSD_CORE_AE_Life_Threatening__c,MSD_CORE_AE_Patient_Overdose__c,
                                       MSD_CORE_PQC_Present__c,MSD_CORE_MARRS_Number__c,MSD_CORE_ChatUniqueID__c,MSD_CORE_Event_Case_Type__c,
                                       MSD_CORE_Customer_Feedback__c,MSD_CORE_Customer_FeedbackClassification__c,MSD_CORE_CDT__c,MSD_CORE_Alert_Security__c,
                                       MSD_CORE_Legal_Alert__c,MSD_CORE_PSP_Program_Name__c,MSD_CORE_PSP_Program_Name_Other__c,MSD_CORE_PSP_Company__c,
                                       MSD_CORE_PSP_Company_Other__c,MSD_CORE_PSP_Number__c,MSD_CORE_PSP_Number_Other__c,MSD_CORE_PSP_Agent_Name__c,
                                       MSD_CORE_PQC_User_Experience__c,MSD_CORE_Operator_of_Device__c,MSD_CORE_PQC_Priority__c,MSD_CORE_PQC_QIR_Requested__c,
                                       MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,PQC_Integration_Processed_Date_Time__c,PQC_ATN_To_be_Processed__c,case_Postal_Code_MVN__c, MSD_CORE_PQC_Lot_Numbers__c, MSD_CORE_PQC_Sample_Expected_Indicator__c, MSD_CORE_PQC_To_Be_Processed__c, MSD_CORE_Catalog_Number__c, MSD_CORE_Model_Number__c, case_AddressLine2_MVN__c, case_AddressLine1_MVN__c, MSD_CORE_Date_PQC_first_identified__c, case_City_MVN__c, case_Account_Email_MVN__c, MSD_CORE_Customer_Contact_First_Name__c, MSD_CORE_Customer_Contact_Last_Name__c, case_Account_Phone_MVN__c,MSD_CORE_Serial_Number__c, MSD_CORE_Unique_Identifier__c, MSD_CORE_Product_Quantity__c, case_State_MVN__c, MSD_CORE_Customer_Contact_Type__c,Account.Class_of_Trade_MRK__C,
                                       MSD_CORE_COVE_Veeva_ID__c
                                       FROM Case 
                                       WHERE Id in :mirIds AND MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','PQC Only')];
                System.debug('case recs size'+caseRecs.size());                     
                List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> pqcList = new List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>();
                if(mirIds.size() > 0)
                {            
                    pqcList =  MSD_CORE_PQCRTBCaseJsonClass.getJSONWrap(mirIds,caseRecs,system.now());
                    System.debug('pqcList size'+pqcList);  
                    MSD_CORE_PQCRTBCaseJsonClass.submitPqcToRtb(pqcList, system.now(),reqInfo,pqcRequests);
                }
                 system.debug('@@@@PQCRequests'+pqcList.size());
                
                
            }
            else{
                
                MSD_CORE_AwsApiIntegration.submitCaseToBus(mirIds);
                
            }
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Records are submitted to RTB. Query for updates in a moment!!'));
            
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Error submitting Data to RTB. Please query for records and try again.'));
            System.debug('exception'+ e);   
        } 
        return null;
    }
    
    
    public PageReference getMIRData() {
        try{
            queryResult = new List<MIRQueryResult>();
            
            List<String> lstcaseIds = caseIds.split(',');
            system.debug('@@@@@lstcaseIds'+lstcaseIds);
            if(sourceType == 'VEEVACRM'){
                //List<Medical_Inquiry_vod__c> mirData = new List<Medical_Inquiry_vod__c>([SELECT Id, Name,Status_vod__c,Last_GPIR_Update_MRK__c, LastModifiedDate FROM Medical_Inquiry_vod__c WHERE LastModifiedDate >=: startTime AND LastModifiedDate <=: endTime AND Status_vod__c=:'Submitted_vod']);
                
                List<Medical_Inquiry_vod__c> mirData = new List<Medical_Inquiry_vod__c>([SELECT Id, Name,Status_vod__c,Last_GPIR_Update_MRK__c, LastModifiedDate FROM Medical_Inquiry_vod__c WHERE Id IN: lstcaseIds]);
                for(Medical_Inquiry_vod__c mir : mirData){
                    MIRQueryResult result = new MIRQueryResult();
                    result.CaseId = mir.Name;
                    result.RecordId = mir.Id;
                    result.Status = mir.Status_vod__c;
                    result.LastGPIRUpdateDate = mir.Last_GPIR_Update_MRK__c;
                    result.LastUpdatedDate = mir.LastModifiedDate;
                    queryResult.add(result);
                }
                
            }
            else if (sourceType == 'AE')
            {
                List<Case> aeData = new List<Case>([SELECT Id, MSD_CORE_To_Be_Processed__c,MSD_CORE_Integration_Processed_Dt__c,CaseNumber,Status,MSD_CORE_Integration_Status__c,MSD_CORE_RTB_Integration_Status__c,LastModifiedDate,MSD_CORE_AEATN_To_be_Processed__c FROM Case WHERE Id IN:lstcaseIds]);
                for(Case ae : aeData ){
                    MIRQueryResult result = new MIRQueryResult();
                    result.CaseId = ae.CaseNumber;
                    result.RecordId = ae.Id;
                    result.Status = ae.Status;
                    result.LastUpdatedDate  = ae.LastModifiedDate;
                    result.LastIntegrationPorcessedDateTime = ae.MSD_CORE_Integration_Processed_Dt__c;
                    if(ae.MSD_CORE_To_Be_Processed__c || ae.MSD_CORE_AEATN_To_be_Processed__c)
                    {
                        result.ToBeProcessed = ae.MSD_CORE_To_Be_Processed__c;
                    }
                    else
                    {
                        result.ToBeProcessed  = false;  
                    }
                    queryResult.add(result);
                }
                
            }
            else if (sourceType == 'PQC')
            {
                List<Case> PQCData = new List<Case>([SELECT Id, MSD_CORE_PQC_To_Be_Processed__c,PQC_Integration_Processed_Date_Time__c,CaseNumber,Status,MSD_CORE_Integration_Status__c,MSD_CORE_RTB_Integration_Status__c,LastModifiedDate,PQC_ATN_To_be_Processed__c FROM Case WHERE Id IN:lstcaseIds]);
               System.debug('inside PQC');
                for(Case pqc : PQCData ){
                    MIRQueryResult result = new MIRQueryResult();
                    result.CaseId = pqc.CaseNumber;
                    result.RecordId = pqc.Id;
                    result.Status = pqc.Status;
                    result.LastUpdatedDate  = pqc.LastModifiedDate;
                    result.LastIntegrationPorcessedDateTime = pqc.PQC_Integration_Processed_Date_Time__c;
                    if(pqc.MSD_CORE_PQC_To_Be_Processed__c || pqc.PQC_ATN_To_be_Processed__c)
                    {
                        result.ToBeProcessed = pqc.MSD_CORE_PQC_To_Be_Processed__c;
                    }
                    else
                    {
                        result.ToBeProcessed  = false;  
                    }
                    queryResult.add(result);
                }
                
            }
            
            else{
                
                //  List<Case> mirCaseData = new List<Case>([SELECT Id, CaseNumber,Status,MSD_CORE_Integration_Status__c,MSD_CORE_RTB_Integration_Status__c,LastModifiedDate FROM Case WHERE ClosedDate >=: startTime AND ClosedDate <=: endTime 
                //                                              AND RecordType.DeveloperName=:'Request_Closed_MVN' AND Status=:'Closed' AND MSD_CORE_Integration_Status__c!=: 'Processed to GPIR' ]);
                List<Case> mirCaseData = new List<Case>([SELECT Id, CaseNumber,Status,MSD_CORE_Integration_Status__c,MSD_CORE_RTB_Integration_Status__c,LastModifiedDate FROM Case WHERE Id IN:lstcaseIds]);
                for(Case mir : mirCaseData ){
                    MIRQueryResult result = new MIRQueryResult();
                    result.CaseId = mir.CaseNumber;
                    result.RecordId = mir.Id;
                    result.Status = mir.Status;
                    result.LegacyIntegrationStatus= mir.MSD_CORE_Integration_Status__c;
                    result.IntegrationStatus = mir.MSD_CORE_RTB_Integration_Status__c;
                    result.LastUpdatedDate  = mir.LastModifiedDate;
                    queryResult.add(result);
                }
                
            }
            if(queryResult.size() == 0){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'No Records Found. Please change your criteria!'));
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, queryResult.size() + ' Record(s) Returned!'));
            }
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Error querying the data. Please Retry!'));
            System.debug('exception'+ e);   
        }   
        return null;
    }
    
    
    public String sourceType { get; set; }
    
    public DateTime startTime {get;set;}
    public DateTime endTime {get;set;}
    public MSD_CORE_Submit_MIR_To_RTB_Controller(){
        
    }
    
    public DateTime getStartTime(){
        
        return startTime;
    }
    
    
    public class MIRQueryResult{
        
        public String CaseId {get;set;}
        public String Status {get;set;}
        public String RecordId {get;set;}
        public DateTime LastUpdatedDate {get;set;}
        public String LegacyIntegrationStatus {get;set;}
        public String IntegrationStatus {get;set;}
        public DateTime LastGPIRUpdateDate {get;set;}
        public DateTime LastIntegrationPorcessedDateTime {get;set;}
        public Boolean ToBeProcessed {get;set;}
    }
    
    
    
}