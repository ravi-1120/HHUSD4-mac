public class MSD_CORE_PQCRTBCustomIterable implements Iterable<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> {
    public Set<String> caseSetIDs = new Set<String>();
    public Set<Case> caseSetRecs = new Set<Case>();
    public List<Case> caseFinalRecs = new List<Case>();
    public List<String> caseFinalIDs = new  List<String>();
    public DateTime processedDateTime;

    public MSD_CORE_PQCRTBCustomIterable(List<String> conditions,DateTime currentJobRunTime)
    {
        MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
        system.debug('@@@@@@reqInfo'+reqInfo);
        processedDateTime = currentJobRunTime;
        Map<String,MSD_CORE_Integration_Logs__c> caseILMap = new Map<String,MSD_CORE_Integration_Logs__c>();
        DateTime bufferDateTime = currentJobRunTime.addSeconds(Integer.valueof((reqInfo.Buffer_Time_in_Seconds__c)));
        
        system.debug('@@@@@@reqInfo'+bufferDateTime);
        String cutOffStringDate = reqInfo.Cut_off_Year__c + '-' + reqInfo.Cut_off_Month__c + '-' + reqInfo.Cut_off_Day__c + ' ' 
            + reqInfo.Cut_off_Hour__c + ':' + reqInfo.Cut_off_Minute__c  +  ':' + reqInfo.Cut_off_Second__c;
        Datetime cutOffDate = Datetime.valueOf(cutOffStringDate);
        system.debug('@@@@@@cutOffDate'+cutOffDate);
        for(string s : conditions)
        {
            // submitted  Condition
            if(s.touppercase() == 'Submitted')
                
                
            {system.debug('inside Submitted condition '+s.touppercase());
                for( Case c: [SELECT Id,CaseNumber,Status,MSD_CORE_Status_List__c,MSD_CORE_Catalog_Number__c,MSD_CORE_External_Response_value__c,AE_Start_Date_MVN__c,MSD_CORE_CDT__c,case_City_MVN__c,MSD_CORE_Customer_Feedback__c,
                                MSD_CORE_Customer_Contact_First_Name__c,MSD_CORE_Customer_Contact_Last_Name__c,MSD_CORE_Model_Number__c,MSD_CORE_Operator_of_Device__c,
                                Parent.casenumber,case_Account_Phone_MVN__c,MSD_CORE_PQC_QIR_Requested__c,MSD_CORE_Serial_Number__c,case_State_MVN__c,
                                MSD_CORE_Unique_Identifier__c,case_Postal_Code_MVN__c,Description,Address_MVN__c, MSD_CORE_Event_Case_Type__c,case_Account_Email_MVN__c,MSD_CORE_AE_Description__c,
                              	MSD_CORE_Date_PQC_first_identified__c,MSD_CORE_Product_Quantity__c,Account.Class_of_Trade_MRK__C,
                            	MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,PQC_Integration_Processed_Date_Time__c,MSD_CORE_PQC_To_Be_Processed__c,
                              	PQC_ATN_To_be_Processed__c,MSD_CORE_PQC_Sample_Expected_Indicator__c,Owner.name,MSD_CORE_Initial_Notes__c,MSD_CORE_COVE_Veeva_ID__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,MSD_CORE_PQC_Lot_Numbers__c,
                              	case_AddressLine1_MVN__c,case_AddressLine2_MVN__c,MSD_CORE_Customer_Contact_Type__c,MSD_CORE_Sample_Expected_Initial_Value__c,MSD_CORE_Customer_Contact_Sub_Type__c
                                from case
                              	//WHERE LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName = 'MSD_CORE_Product_Complaint_Submitted'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Submitted' AND 
                              //	MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','PQC Only')  AND MSD_CORE_To_Be_Processed__c = true AND MSD_CORE_Submitted_Date__c <= :bufferDateTime])
                            WHERE LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName = 'MSD_CORE_Product_Complaint_Submitted'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Submitted'  AND  
                            MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','PQC Only') AND MSD_CORE_PQC_To_Be_Processed__c = true  AND MSD_CORE_Opened_Date__c <= :bufferDateTime])

                {
                    this.caseSetIDs.add(c.Id);
                    this.caseSetRecs.add(c);
                }
             System.debug('Case records retrived Submitted : '+this.caseSetIDs);
                
            }
            // this is used for open cases nightly job
              if(s.touppercase() == 'Open')
                
                
            {system.debug('inside Open condition '+s.touppercase());
                for( Case c: [SELECT Id,CaseNumber,Status,MSD_CORE_Status_List__c,MSD_CORE_External_Response_value__c,MSD_CORE_Catalog_Number__c,AE_Start_Date_MVN__c,MSD_CORE_CDT__c,case_City_MVN__c,MSD_CORE_Customer_Feedback__c,
                                MSD_CORE_Customer_Contact_First_Name__c,MSD_CORE_Customer_Contact_Last_Name__c,MSD_CORE_Model_Number__c,MSD_CORE_Operator_of_Device__c,
                                Parent.casenumber,case_Account_Phone_MVN__c,MSD_CORE_PQC_QIR_Requested__c,MSD_CORE_Serial_Number__c,case_State_MVN__c,
                                MSD_CORE_Unique_Identifier__c,case_Postal_Code_MVN__c,Description,Address_MVN__c,
                               	MSD_CORE_Event_Case_Type__c,case_Account_Email_MVN__c,MSD_CORE_AE_Description__c,
                              	MSD_CORE_Date_PQC_first_identified__c,MSD_CORE_Product_Quantity__c,Account.Class_of_Trade_MRK__C,
                            	MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,PQC_Integration_Processed_Date_Time__c,MSD_CORE_PQC_To_Be_Processed__c,
                              	PQC_ATN_To_be_Processed__c,MSD_CORE_PQC_Sample_Expected_Indicator__c,Owner.name,MSD_CORE_Initial_Notes__c,MSD_CORE_COVE_Veeva_ID__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,MSD_CORE_PQC_Lot_Numbers__c,
                              	case_AddressLine1_MVN__c,case_AddressLine2_MVN__c,MSD_CORE_Customer_Contact_Type__c,MSD_CORE_Sample_Expected_Initial_Value__c,MSD_CORE_Customer_Contact_Sub_Type__c
                                from case
                              	WHERE LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName ='Product_Complaint_MVN' OR RecordType.DeveloperName LIKE '%Combo%') AND Status = 'Open' AND 
                              	MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','PQC Only')  AND ( MSD_CORE_PQC_To_Be_Processed__c = true OR PQC_ATN_To_be_Processed__c = true)])
                {
                    this.caseSetIDs.add(c.Id);
                    this.caseSetRecs.add(c);
                }
              System.debug('Case records retrived Open night job : '+this.caseSetIDs);
                
            }

            // Closed Condition
            if(s.touppercase() == 'CLOSED')
            {
                for( Case c: [SELECT Id,CaseNumber,Status,MSD_CORE_Status_List__c,MSD_CORE_Catalog_Number__c,MSD_CORE_External_Response_value__c,AE_Start_Date_MVN__c,MSD_CORE_CDT__c,case_City_MVN__c,MSD_CORE_Customer_Feedback__c,
                                MSD_CORE_Customer_Contact_First_Name__c,MSD_CORE_Customer_Contact_Last_Name__c,MSD_CORE_Model_Number__c,MSD_CORE_Operator_of_Device__c,
                                Parent.casenumber,case_Account_Phone_MVN__c,MSD_CORE_PQC_QIR_Requested__c,MSD_CORE_Serial_Number__c,case_State_MVN__c,
                                MSD_CORE_Unique_Identifier__c,case_Postal_Code_MVN__c,Description,Address_MVN__c, MSD_CORE_Event_Case_Type__c,case_Account_Email_MVN__c,MSD_CORE_AE_Description__c,
                              	MSD_CORE_Date_PQC_first_identified__c,MSD_CORE_Product_Quantity__c,Account.Class_of_Trade_MRK__C,
                             	MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,PQC_Integration_Processed_Date_Time__c,MSD_CORE_PQC_To_Be_Processed__c,
                              	PQC_ATN_To_be_Processed__c,MSD_CORE_PQC_Sample_Expected_Indicator__c,Owner.name,MSD_CORE_Initial_Notes__c,MSD_CORE_COVE_Veeva_ID__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,MSD_CORE_PQC_Lot_Numbers__c,
                              	case_AddressLine1_MVN__c,case_AddressLine2_MVN__c,MSD_CORE_Customer_Contact_Type__c,MSD_CORE_Sample_Expected_Initial_Value__c,MSD_CORE_Customer_Contact_Sub_Type__c
            				 from case
                              WHERE LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName = 'Product_Complaint_Closed_MVN'OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Closed' AND
                              MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','PQC Only')  AND MSD_CORE_PQC_To_Be_Processed__c = true AND ClosedDate <= :bufferDateTime])
                {
                    this.caseSetIDs.add(c.Id);
                    this.caseSetRecs.add(c);
                }
                 System.debug('Case records retrived Closed case : '+this.caseSetIDs);
            }
            
           
            //Notes&Attachments Condition
            if(s.touppercase() == 'NOTES&ATTACHMENTS')
            {        System.debug(' In side NOTES&ATTACHMENTS : ');     
                for(Case c : [SELECT Id,CaseNumber,Status,MSD_CORE_Status_List__c,MSD_CORE_Catalog_Number__c,MSD_CORE_External_Response_value__c,AE_Start_Date_MVN__c,MSD_CORE_CDT__c,case_City_MVN__c,MSD_CORE_Customer_Feedback__c,
                                MSD_CORE_Customer_Contact_First_Name__c,MSD_CORE_Customer_Contact_Last_Name__c,MSD_CORE_Model_Number__c,MSD_CORE_Operator_of_Device__c,
                                Parent.casenumber,case_Account_Phone_MVN__c,MSD_CORE_PQC_QIR_Requested__c,MSD_CORE_Serial_Number__c,case_State_MVN__c,
                                MSD_CORE_Unique_Identifier__c,case_Postal_Code_MVN__c,Description,Address_MVN__c, MSD_CORE_Event_Case_Type__c,case_Account_Email_MVN__c,MSD_CORE_AE_Description__c,
                              	MSD_CORE_Date_PQC_first_identified__c,MSD_CORE_Product_Quantity__c,Account.Class_of_Trade_MRK__C,
                             	MSD_CORE_QIR_Received_Date__c,LastModifiedDate,CreatedDate,MSD_CORE_Submitted_Date__c,ClosedDate,MSD_CORE_Opened_Date__c,PQC_Integration_Processed_Date_Time__c,MSD_CORE_PQC_To_Be_Processed__c,
                              	PQC_ATN_To_be_Processed__c,MSD_CORE_PQC_Sample_Expected_Indicator__c,Owner.name,MSD_CORE_Initial_Notes__c,MSD_CORE_COVE_Veeva_ID__c,MSD_CORE_AE_PQC_Company_Awareness_Date__c,MSD_CORE_PQC_Lot_Numbers__c,
                              	case_AddressLine1_MVN__c,case_AddressLine2_MVN__c,MSD_CORE_Customer_Contact_Type__c,MSD_CORE_Sample_Expected_Initial_Value__c,MSD_CORE_Customer_Contact_Sub_Type__c
                             FROM Case
                             WHERE  LastModifiedDate >= :cutOffDate AND (
                                     ((RecordType.DeveloperName = 'Product_Complaint_Closed_MVN' OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Closed') OR
                                  	((RecordType.DeveloperName = 'MSD_CORE_Product_Complaint_Submitted'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Submitted')) AND
										MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','PQC Only') AND PQC_ATN_To_be_Processed__c = true]) {
                    this.caseSetIDs.add(c.Id); 
                    this.caseSetRecs.add(c);
                }
                
              //System.debug('Case records retrived Notes and Atachment  : '+this.caseSetIDs);
            
            }
       
            
        } 
        caseFinalIDs.addAll(caseSetIDs);
        caseFinalRecs.addAll(caseSetRecs);
        
    }
    public Iterator<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> iterator(){
        List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> aeList = new List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>();       
        if(caseFinalIDs.size() > 0)
        {            
            aeList =  MSD_CORE_PQCRTBCaseJsonClass.getJSONWrap(caseFinalIDs,caseFinalRecs,processedDateTime);
        }
        system.debug('@@@@@aeList'+aeList.size());
        system.debug('@@@@@aeList'+aeList);
        return new MSD_CORE_PQCRTBCustomIterator(aeList);
       
    }
}