global class MSD_CORE_AERTBRetryBatchClass implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public static final String REQ_STATUS_RETRY = 'RETRY';
    public static final String REQ_CASE_TYPE = 'AE';
    public static final MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_AERTBCaseJsonClass.scRTBAEPQCRequestInfo();
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id,Case_Id__c, Status__c,MSD_CORE_Retry_Count__c,Request_Id__c,Message__c FROM MSD_CORE_PIR_Request__c WHERE Case_Id__c != null AND Status__c = :REQ_STATUS_RETRY AND MSD_CORE_Case_Type__c = :REQ_CASE_TYPE';
        return Database.getQueryLocator(query);
    }
    
    global void execute( Database.BatchableContext BC, List<MSD_CORE_PIR_Request__c> scope ) {
        DateTime currentJobRunDateTime = system.now();
        Set<ID> caseSetIDs = new Set<ID>(); 
        List<ID> caseIDs = new List<ID>(); 
        for(MSD_CORE_PIR_Request__c rtb : scope)
        {   
            caseSetIDs.add(rtb.Case_Id__c);  
        }        
        caseIDs.addAll(caseSetIDs);
        if(caseIDs.size() > 0)
        {
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
                                   MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,MSD_CORE_Integration_Processed_Dt__c,MSD_CORE_To_Be_Processed__c,MSD_CORE_AEATN_To_be_Processed__c
                                   FROM Case 
                                   WHERE Id in :caseIDs];
            List<MSD_CORE_AERequest.ServiceCloudSafetyCase> aeList = new List<MSD_CORE_AERequest.ServiceCloudSafetyCase>();
            aeList =  MSD_CORE_AERTBCaseJsonClass.getJSONWrap(caseIDs,caseRecs,currentJobRunDateTime);
            if(aeList.size() > 0)
            {
                MSD_CORE_AERTBCaseJsonClass.submitAeToPv(aeList, currentJobRunDateTime,reqInfo,scope);  
            }
            
        }
        
    }   
    
    global void finish( Database.BatchableContext BC ) {
        
        
    }
    
}