public class MSD_CORE_AERTBCustomIterable implements Iterable<MSD_CORE_AERequest.ServiceCloudSafetyCase> {
    public Set<String> caseSetIDs = new Set<String>();
    public Set<Case> caseSetRecs = new Set<Case>();
    public List<Case> caseFinalRecs = new List<Case>();
    public List<String> caseFinalIDs = new  List<String>();
    public DateTime processedDateTime;
    
    public MSD_CORE_AERTBCustomIterable(List<String> conditions,DateTime currentJobRunTime)
    {
        MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_AERTBCaseJsonClass.scRTBAEPQCRequestInfo();
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
            // Open Condition
            if(s.touppercase() == 'OPEN')
                
            {
                for( Case c: [select Id,Status,ParentId,Parent.CaseNumber,Parent.MSD_CORE_PQC_Present__c,Parent.MSD_CORE_ChatUniqueID__c,
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
                              WHERE  Case.Owner.Name <>:System.Label.AEOpenQueue AND LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName = 'Adverse_Event_MVN'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Open'  AND  
                              MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only') AND Type != 'Other Company Product'AND MSD_CORE_To_Be_Processed__c = true  AND MSD_CORE_Opened_Date__c <= :bufferDateTime])
                {
                    
                    this.caseSetIDs.add(c.Id);
                    this.caseSetRecs.add(c);
                }                
                
            }
            
            // Submitted Condition
            if(s.touppercase() == 'SUBMITTED')
            {
                for( Case c: [SELECT Id,Status,ParentId,Parent.CaseNumber,Parent.MSD_CORE_PQC_Present__c,Parent.MSD_CORE_ChatUniqueID__c,
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
                              WHERE LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName = 'Adverse_Event_Submitted'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Submitted' AND 
                              MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only') AND Type != 'Other Company Product' AND MSD_CORE_To_Be_Processed__c = true AND MSD_CORE_Submitted_Date__c <= :bufferDateTime])
                {
                    this.caseSetIDs.add(c.Id);
                    this.caseSetRecs.add(c);
                }
                
            }
            
            // Closed Condition
            if(s.touppercase() == 'CLOSED')
            {
                for( Case c: [SELECT Id,Status,ParentId,Parent.CaseNumber,Parent.MSD_CORE_PQC_Present__c,Parent.MSD_CORE_ChatUniqueID__c,
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
                              WHERE LastModifiedDate >= :cutOffDate AND (RecordType.DeveloperName = 'Adverse_Event_Closed_MVN' OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Closed' AND
                              MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only') AND Type != 'Other Company Product' AND MSD_CORE_To_Be_Processed__c = true AND ClosedDate <= :bufferDateTime])
                {
                    this.caseSetIDs.add(c.Id);
                    this.caseSetRecs.add(c);
                }
            }
            
           /* // Notes Condition                     
            if(s.touppercase() == 'NOTES')
            {
                for(MSD_CORE_Note__c n :[SELECT Id,MSD_CORE_Case__c,LastModifiedDate FROM MSD_CORE_Note__c 
                                         WHERE  LastModifiedDate >= :cutOffDate AND MSD_CORE_Case__c != null AND 
                                         (((MSD_CORE_Case__r.RecordType.DeveloperName = 'Adverse_Event_MVN'  OR MSD_CORE_Case__r.RecordType.DeveloperName LIKE 'Combo%') AND MSD_CORE_Case__r.Status = 'Open') OR
                                          ((MSD_CORE_Case__r.RecordType.DeveloperName = 'Adverse_Event_Closed_MVN' OR MSD_CORE_Case__r.RecordType.DeveloperName LIKE 'Combo%') AND MSD_CORE_Case__r.Status = 'Closed') OR
                                          ((MSD_CORE_Case__r.RecordType.DeveloperName = 'Adverse_Event_Submitted'  OR MSD_CORE_Case__r.RecordType.DeveloperName LIKE 'Combo%') AND MSD_CORE_Case__r.Status = 'Submitted')) AND
                                         MSD_CORE_Case__r.MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only') AND MSD_CORE_Case__r.Type != 'Other Company Product' AND MSD_CORE_To_Be_Processed__c = true])
                {
                    this.caseSetIDs.add(n.MSD_CORE_Case__c);
                }
                
            }
            // Attachemnts Condition
            if(s.touppercase() == 'ATTACHMENTS')
            {             
                for(Case c : [SELECT Id FROM Case
                              WHERE  LastModifiedDate >= :cutOffDate AND (((RecordType.DeveloperName = 'Adverse_Event_MVN'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Open') OR
                                     ((RecordType.DeveloperName = 'Adverse_Event_Closed_MVN' OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Closed') OR
                                     ((RecordType.DeveloperName = 'Adverse_Event_Submitted'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Submitted')) AND
                              MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only') AND Type != 'Other Company Product' AND MSD_CORE_To_Be_Processed__c = true])
                {
                    this.caseSetIDs.add(c.Id); 
                }
            }
            */
            //Notes&Attachments Condition
            if(s.touppercase() == 'NOTES&ATTACHMENTS')
            {             
                for(Case c : [SELECT Id,Status,ParentId,Parent.CaseNumber,Parent.MSD_CORE_PQC_Present__c,Parent.MSD_CORE_ChatUniqueID__c,
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
                              WHERE  LastModifiedDate >= :cutOffDate AND (((RecordType.DeveloperName = 'Adverse_Event_MVN'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Open' AND Case.Owner.Name <>:System.Label.AEOpenQueue ) OR
                                     ((RecordType.DeveloperName = 'Adverse_Event_Closed_MVN' OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Closed') OR
                                     ((RecordType.DeveloperName = 'Adverse_Event_Submitted'  OR RecordType.DeveloperName LIKE 'Combo%') AND Status = 'Submitted')) AND
                              MSD_CORE_EVENT_CASE_TYPE__c in ('AE and PQC','AE Only') AND Type != 'Other Company Product' AND MSD_CORE_AEATN_To_be_Processed__c = true])
                {
                    this.caseSetIDs.add(c.Id); 
                    this.caseSetRecs.add(c);
                }
            }
            
        }
        caseFinalIDs.addAll(caseSetIDs);
        caseFinalRecs.addAll(caseSetRecs);
        
    }
    public Iterator<MSD_CORE_AERequest.ServiceCloudSafetyCase> iterator(){
        List<MSD_CORE_AERequest.ServiceCloudSafetyCase> aeList = new List<MSD_CORE_AERequest.ServiceCloudSafetyCase>();       
        if(caseFinalIDs.size() > 0)
        {            
            aeList =  MSD_CORE_AERTBCaseJsonClass.getJSONWrap(caseFinalIDs,caseFinalRecs,processedDateTime);
        }
        system.debug('@@@@@aeList'+aeList.size());
        system.debug('@@@@@aeList'+aeList);
        return new MSD_CORE_AERTBCustomIterator(aeList);
    }
}