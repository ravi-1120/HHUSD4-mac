global class MSD_CORE_PQCRTBRetryBatchClass implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public static final String REQ_STATUS_RETRY = 'RETRY';
    public static final String REQ_CASE_TYPE = 'PQC Only';
    public static final String REQ_CASE_TYPE2 = 'AE and PQC';
    public static final MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id,Case_Id__c, Status__c,MSD_CORE_Retry_Count__c,Request_Id__c,Message__c FROM MSD_CORE_PIR_Request__c WHERE Case_Id__c != null AND Status__c = :REQ_STATUS_RETRY AND (MSD_CORE_Case_Type__c = :REQ_CASE_TYPE OR MSD_CORE_Case_Type__c = :REQ_CASE_TYPE2)';
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
            List<case> caseRecs = [SELECT Id,CaseNumber,Status,MSD_CORE_Status_List__c,MSD_CORE_Catalog_Number__c,MSD_CORE_External_Response_value__c,AE_Start_Date_MVN__c,MSD_CORE_CDT__c,case_City_MVN__c,MSD_CORE_Customer_Feedback__c,
                                MSD_CORE_Customer_Contact_First_Name__c,MSD_CORE_Customer_Contact_Last_Name__c,MSD_CORE_Model_Number__c,MSD_CORE_Operator_of_Device__c,
                                Parent.casenumber,case_Account_Phone_MVN__c,MSD_CORE_PQC_QIR_Requested__c,MSD_CORE_Serial_Number__c,case_State_MVN__c,
                                MSD_CORE_Unique_Identifier__c,case_Postal_Code_MVN__c,Description,Address_MVN__c, MSD_CORE_Event_Case_Type__c,case_Account_Email_MVN__c,MSD_CORE_AE_Description__c,
                              	MSD_CORE_Date_PQC_first_identified__c,MSD_CORE_Product_Quantity__c,Account.Class_of_Trade_MRK__C,
                            	MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,PQC_Integration_Processed_Date_Time__c,MSD_CORE_PQC_To_Be_Processed__c,
                              	PQC_ATN_To_be_Processed__c,MSD_CORE_PQC_Sample_Expected_Indicator__c,Owner.name,MSD_CORE_Initial_Notes__c,MSD_CORE_COVE_Veeva_ID__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,MSD_CORE_PQC_Lot_Numbers__c,
                              	case_AddressLine1_MVN__c,case_AddressLine2_MVN__c,MSD_CORE_Customer_Contact_Type__c,MSD_CORE_Sample_Expected_Initial_Value__c
                                 FROM Case 
                                   WHERE Id in :caseIDs];
            List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> PQCList = new List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>();
            PQCList =  MSD_CORE_PQCRTBCaseJsonClass.getJSONWrap(caseIDs,caseRecs,currentJobRunDateTime);
            if(PQCList.size() > 0)
            {
                MSD_CORE_PQCRTBCaseJsonClass.submitPqcToRtb(PQCList, currentJobRunDateTime,reqInfo,scope);  
            }
            
        }
        
    }   
    
    global void finish( Database.BatchableContext BC ) {
        
        
    }
    
}