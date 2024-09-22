public without sharing class MSD_CORE_SignUpController {
    
    @AuraEnabled
    public static List<MSD_CORE_Organization__c> getOrganizations(String searchKey){
        string key1  = searchKey+'%';
        string key2  = '%'+searchKey;
        string key3  = '%'+searchKey+'%';
        try {
            if(String.isNotBlank(searchKey)){
               
                return [SELECT Id, Name FROM MSD_CORE_Organization__c WHERE Name like: key1 OR Name like: key2 OR Name like: key3];
            }else{
               
                 return [SELECT Id, Name FROM MSD_CORE_Organization__c Order by Name ASC];
            }
            
        } catch (Exception e) { 
            return null;
        }
    }
    
    @AuraEnabled()
    public static List<String> getPicklistValue(String objectType, String selectedField){
        
        try {
            List<String> pickListValuesList = new List<String>();
            Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
            Schema.DescribeSObjectResult res = convertToObj.getDescribe();
            Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }     
            return pickListValuesList;
        } catch (Exception e) {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getRoles(){
        List<PicklistOption> roleList = new List<PicklistOption>();

        for (Schema.PicklistEntry picklist : MSD_CORE_Eligibility__c.MSD_CORE_Role__c.getDescribe().getPicklistValues()) {
            roleList.add(new PicklistOption(picklist.getLabel(), picklist.getValue()));
        }

        return roleList;
    }

    /*createEligibility*/
    @AuraEnabled
    public static Map<Id, Boolean> createEligibility(String accountid, String data, Boolean consultantChecked, Boolean ptChecked, String hcDMakerChecked, String portalType, String orgListJSON){
        Map<Id, Boolean> resultMapping = new Map<Id, Boolean>();
        Boolean isNewOrgAdded = false;
        try {
            
            // Query the record type for HCP Person Account
            RecordType hcpRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'HCP' LIMIT 1];

            // If accountid is blank or undefined, create a new Person Account with HCP record type
            if (String.isBlank(accountid)) {
                Map<String, Object> mainmap = (Map<String, Object>)JSON.deserializeUntyped(data);
                CustomMetadataHelper.MetadataSettings metadataSettings = CustomMetadataHelper.getMetadataSettings();
                Account newAccount = new Account(
                    FirstName = String.valueOf(mainmap.get('FirstName')),
                    LastName = String.valueOf(mainmap.get('LastName')),
                    PersonEmail = String.valueOf(mainmap.get('Email')),
                    Phone = String.valueOf(mainmap.get('Phone')),
                    RecordTypeId = hcpRecordType.Id,
                    MSD_CORE_Health_Care_Decision_Maker__pc = true,
                    Primary_Executive__pc = metadataSettings.primaryExecutiveId, 
                    MSD_CORE_Medical_AE__pc = metadataSettings.medicalAEId,     
                    MSD_CORE_Oncology_AE__pc = metadataSettings.oncologyAEId,
                    MSD_CORE_Created_outside_of_DCR_Process__c = null
                );
                insert newAccount;
                accountid = newAccount.Id;
            }
            
            List<MSD_CORE_Eligibility__c> eligibilitylst = [SELECT ID, MSD_CORE_Account__c, MSD_CORE_Approver__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c = :accountid LIMIT 1];
            List<OrganizationInfo> orgList = new List<OrganizationInfo>();
            MSD_CORE_Eligibility__c rec;
            if (eligibilitylst.size() > 0) {
                rec = eligibilitylst[0];
            } else {
                rec = new MSD_CORE_Eligibility__c();
                rec.MSD_CORE_Account__c = accountid;
            }
            
            Map<String, Object> mainmap = (Map<String, Object>)JSON.deserializeUntyped(data);
            
            rec.MSD_CORE_First_Name__c = String.valueOf(mainmap.get('FirstName'));
            rec.MSD_CORE_Last_Name__c = String.valueOf(mainmap.get('LastName'));
            rec.MSD_CORE_Organization_Type__c = String.valueOf(mainmap.get('OrganizationType'));
            rec.MSD_CORE_Organization_ZIP__c = String.valueOf(mainmap.get('Zip'));
            rec.MSD_CORE_Organization_Street_1__c = String.valueOf(mainmap.get('WorkAddress'));
            rec.MSD_CORE_Organization_Street_2__c = String.valueOf(mainmap.get('Unit'));
            rec.MSD_CORE_Organization_City__c = String.valueOf(mainmap.get('City'));
            rec.MS_CORE_Organization_State_Code__c = String.valueOf(mainmap.get('State'));
            rec.MSD_CORE_Email__c = String.valueOf(mainmap.get('Email'));
            rec.MSD_CORE_Organization_Phone__c = String.valueOf(mainmap.get('Phone'));
            rec.MSD_CORE_Role__c = String.valueOf(mainmap.get('Role'));
            rec.MSD_CORE_Other_Role__c = String.valueOf(mainmap.get('PleaseSpecify'));
            
            if(ptChecked != null) {
                rec.MSD_CORE_P_T_Process__c = ptChecked;
            }

            rec.MSD_CORE_Agency_Email__c = String.valueOf(mainmap.get('AgencyEmail'));
            rec.MSD_CORE_Consultancy_Agency__c = String.valueOf(mainmap.get('ConsultancyAgency'));
            rec.MSD_CORE_Status__c = 'In Progress';
            rec.MSD_CORE_Stage__c = 'Eligibility';
            rec.MSD_CORE_Portal_Type__c = portalType;
            rec.Name = rec.MSD_CORE_First_Name__c + ' ' + rec.MSD_CORE_Last_Name__c;

            Boolean isHCDDMakerChecked = hcDMakerChecked != null && hcDMakerChecked.equalsIgnoreCase('Yes');
            rec.MSD_CORE_Healthcare_Professional__c = isHCDDMakerChecked;

            List<Account> accList = [SELECT Id, Name, PersonEmail, FirstName, Primary_Executive__pc FROM Account WHERE Id = :accountid];
            if (accList.size() > 0) {
                rec.MSD_CORE_Approver__c = accList[0].Primary_Executive__pc;
            }

            String orgId = String.valueOf(mainmap.get('Organization'));
            
            List<MSD_CORE_Organization__c> orglst = [SELECT Id, Name FROM MSD_CORE_Organization__c WHERE Id = :orgId OR Name =: orgId LIMIT 1];
            if (orglst.size() > 0) {
                rec.MSD_CORE_Organization__c = orgId;
            } else {
                MSD_CORE_Organization__c org = new MSD_CORE_Organization__c(Name = orgId);
                insert org;
                rec.MSD_CORE_Organization__c = org.Id;
                isNewOrgAdded = true;
            }

            upsert rec;
            
            // Check if manual or auto approval is needed
            boolean approvalNeeded = isManualOrAutoApproval(mainmap, ptChecked, isNewOrgAdded);
            resultMapping.put(accountid, approvalNeeded);
            
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            //return false;
        }
        return resultMapping;
    }

    @AuraEnabled
    public static Map<Id, Boolean> createEligibilityConsultancy(String accountid, String data, Boolean consultantChecked, Boolean ptChecked, String hcDMakerChecked, String portalType, String orgListJSON){
        Map<Id, Boolean> resultMapping = new Map<Id, Boolean>();
        try {
            Map<String, Object> mainmap = (Map<String, Object>)JSON.deserializeUntyped(data);
            List<MSD_CORE_Eligibility__c> eligibilitylst = [SELECT ID, MSD_CORE_Account__c, MSD_CORE_Approver__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c = :accountid LIMIT 1];
            List<OrganizationInfo> orgList = new List<OrganizationInfo>();
            MSD_CORE_Related_Organizations__c relatedOrgObj = new MSD_CORE_Related_Organizations__c();
            List<MSD_CORE_Organization__c> newOrgLst = new List<MSD_CORE_Organization__c>();
            List<MSD_CORE_Related_Organizations__c> lstRelatedOrgs = new List<MSD_CORE_Related_Organizations__c>();

            MSD_CORE_Eligibility__c rec;
            if (eligibilitylst.size() > 0)
                rec = eligibilitylst[0];

            if(rec != null) {
                
                rec.MSD_CORE_Agency_Email__c = String.valueOf(mainmap.get('AgencyEmail'));
                rec.MSD_CORE_Consultancy_Agency__c = String.valueOf(mainmap.get('ConsultancyAgency'));
                rec.MSD_CORE_Status__c = 'Pending';
                
                if(!Test.isRunningTest())
                    upsert rec;
                
                String orgId = String.valueOf(mainmap.get('Organization'));
                String orgType = String.valueOf(mainmap.get('OrganizationType'));
                String orgEmail = String.valueOf(mainmap.get('OrganizationEmail'));

                List<MSD_CORE_Organization__c> orglst = [SELECT Id, Name FROM MSD_CORE_Organization__c WHERE Id = :orgId OR Name =: orgId LIMIT 1];
                
                if (orglst.size() > 0) {
                    relatedOrgObj = new MSD_CORE_Related_Organizations__c();
                    relatedOrgObj.MSD_CORE_Organization__c = orglst[0].Id;
                    relatedOrgObj.MSD_CORE_Organization_Type__c = orgType;
                    relatedOrgObj.MSD_CORE_Email__c = orgEmail;
                    relatedOrgObj.MSD_CORE_Eligibility__c = rec.Id;
                    lstRelatedOrgs.add(relatedOrgObj);
                } else if(String.isNotBlank(orgId)) {
                    MSD_CORE_Organization__c org = new MSD_CORE_Organization__c(Name = orgId);
                    insert org;

                    relatedOrgObj = new MSD_CORE_Related_Organizations__c();
                    relatedOrgObj.MSD_CORE_Organization__c = org.Id;
                    relatedOrgObj.MSD_CORE_Organization_Type__c = orgType;
                    relatedOrgObj.MSD_CORE_Email__c = orgEmail;
                    relatedOrgObj.MSD_CORE_Eligibility__c = rec.Id;
                    lstRelatedOrgs.add(relatedOrgObj);
                }
                
                // Handle Related Organizations
                if (String.isNotBlank(orgListJSON)) {
                    orgList = (List<OrganizationInfo>) JSON.deserialize(orgListJSON, List<OrganizationInfo>.class);

                    if (orgList != null && orgList.size() > 0) {
                        Set<String> orgSet = new Set<String>();
                        Map<String, MSD_CORE_Organization__c> orgMap = new Map<String, MSD_CORE_Organization__c>();
                        
                        for (OrganizationInfo orgInfo : orgList) {
                            if (orgInfo != null && orgInfo.Organization.fieldValue != null) {
                                orgSet.add(orgInfo.Organization.fieldValue);
                            }
                        }

                        if(orgSet.size() > 0) {
                            for(MSD_CORE_Organization__c r : [SELECT Id, Name FROM MSD_CORE_Organization__c WHERE Id IN : orgSet OR Name IN : orgSet]) {
                                orgMap.put(r.Id, r);
                                orgMap.put(r.Name, r);
                            }
                        }
                        
                        for(String r : orgSet) {
                            if(!orgMap.containskey(r)) {
                                newOrgLst.add(new MSD_CORE_Organization__c(Name = r));
                            }
                        }

                        if(newOrgLst.size() > 0) {
                            insert newOrgLst;
                        }

                        for(MSD_CORE_Organization__c r : newOrgLst) {
                            orgMap.put(r.Name, r);
                            orgMap.put(r.id, r); 
                        }

                        for (OrganizationInfo orgInfo : orgList) {
                            if (orgInfo != null) {
                                relatedOrgObj = new MSD_CORE_Related_Organizations__c();
                                relatedOrgObj.MSD_CORE_Organization__c = orgMap.get(orgInfo.Organization.fieldValue).Id;
                                relatedOrgObj.MSD_CORE_Organization_Type__c = orgInfo.OrganizationType.fieldValue;
                                relatedOrgObj.MSD_CORE_Email__c = orgInfo.OrganizationEmail.fieldValue;
                                relatedOrgObj.MSD_CORE_Eligibility__c = rec.Id;
                                lstRelatedOrgs.add(relatedOrgObj);
                            }
                        }

                        if (lstRelatedOrgs.size() > 0) {
                            insert lstRelatedOrgs;
                        }
                    }
                }
            }

            // Check if manual or auto approval is needed
            boolean approvalNeeded = isManualOrAutoApproval(mainmap, ptChecked, true);
            resultMapping.put(accountid, approvalNeeded);

        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
        return resultMapping;
    }

    // Method to check if the email domain is valid
    public static Boolean isEmailDomainValid(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        
        // Split the email to extract the domain
        List<String> emailParts = email.split('@');
        if (emailParts.size() != 2) {
            return false;
        }
        
        String domain = emailParts[1];
        
        // Check if the domain or the whole email is in the valid sets
        return getValidDomainsAndEmails().contains(domain) || getExactMatchEmails().contains(email);
    }

    // Retrieve valid domains and exact match emails from custom metadata
    private static Set<String> getValidDomainsAndEmails() {
        Set<String> validDomainsAndEmails = new Set<String>();
        
        // Query the custom metadata type for valid domains and exact match emails
        for (MSD_CORE_Email_Domain_Setting__mdt domainRecord : [
            SELECT Domain__c, Is_Exact_Match__c 
            FROM MSD_CORE_Email_Domain_Setting__mdt
        ]) {
                validDomainsAndEmails.add(domainRecord.Domain__c);
        }
        
        return validDomainsAndEmails;
    }

    // Retrieve valid domains and exact match emails from custom metadata
    private static Set<String> getExactMatchEmails() {
        Set<String> validDomainsAndEmails = new Set<String>();
        
        // Query the custom metadata type for valid domains and exact match emails
        for (MSD_CORE_Email_Domain_Setting__mdt domainRecord : [
            SELECT Domain__c, Is_Exact_Match__c 
            FROM MSD_CORE_Email_Domain_Setting__mdt 
        ]) {
                validDomainsAndEmails.add(domainRecord.Domain__c);
        }
        
        return validDomainsAndEmails;
    }

    // Method to check if manual approval is required
    public static Boolean isManualOrAutoApproval(Map<String,object> mainmap, Boolean ptChecked, Boolean isOrgAdded) {
        
        if (isOrgAdded == true || String.valueof(mainmap.get('OrganizationType')) == 'Other' ||
            !isEmailDomainValid(String.valueof(mainmap.get('Email'))) ||
            String.valueof(mainmap.get('Role')) == 'Consultant' ||
            String.valueof(mainmap.get('Role')) == 'Student in Rotation' ||
            String.valueof(mainmap.get('Role')) == 'Other' || 
            (String.valueof(mainmap.get('Role')) == 'Clinician / Physician' && ptChecked == false)) {
            return true; // Manual approval required
        } else {
            return false; // Auto approval
        }
    }

    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String description;
    
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    
        public PicklistOption(String label, String value, String description) {
            this.label = label + ' - ' + description;
            this.value = value;
        }
    }

    public class OrganizationInfo {
        public Field Organization;
        public Field OrganizationType;
        public Field OrganizationEmail;
    }

    public class Field {
        public String fieldValue;
        public Boolean required;
        public Boolean error;
        public String errorMessage;
        public Boolean showLabel;
    }

    /**
     * Method Name  :   createOTP
     * @param       :   recordId - account id
     * @description :   Use to create OTP Record
     * @return      :   OTP Stringe
     * Created By   :   Ramana (Focal CXM)
     * Created Date :   May 29 2024
     */
    @AuraEnabled
    public static String createOTP(String recordId){
        String returnval;
        try {
            List<MSD_CORE_OTP__c> otplst = [SELECT Id, MSD_CORE_Token__c, MSD_CORE_Customer__c FROM MSD_CORE_OTP__c WHERE MSD_CORE_Customer__c =: recordId];
            delete otplst;
            Decimal duration = [SELECT Id, Label, MSD_CORE_Duration__c FROM MFR_Config__mdt WHERE Label = 'OTP Expiration Duration'].MSD_CORE_Duration__c;
            MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
            otp.MSD_CORE_Customer__c = recordId;
            otp.MSD_CORE_Expiration_DateTime__c = System.now().addMinutes(Integer.valueOf(duration));
            otp.MSD_CORE_Type__c = 'Self Registration';
            otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
            otp.MSD_CORE_Status__c = 'New';
            insert otp;
            returnval =  otp.Id;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Exeception-->'+e.getMessage() + '---'+ e.getLineNumber());
            returnval = e.getMessage() +'=='+e.getLineNumber();
        }
        return returnval;
    }


    /**
     * Method Name  :   submitOTP
     * @param       :   recordId - account id
     * @param       :   otpval - OTP
     * @description :   Use to check OTP Record
     * @return      :   String
     * Created By   :   Rammana (Focal CXM)
     * Created Date :   May 29 2024
     */
    @AuraEnabled
    public static String submitOTP(String recordId, String otpval){
        String returnval;
        try {
            List<MSD_CORE_OTP__c> otplst = [SELECT Id, MSD_CORE_Token__c, MSD_CORE_Expired__c FROM MSD_CORE_OTP__c WHERE MSD_CORE_Customer__c =: recordId];
            
            if (otplst.size()>0) {
                if (!otplst[0].MSD_CORE_Expired__c) {
                    if (otplst[0].MSD_CORE_Token__c == otpval) {
                        returnval = 'Valid OTP!';
                    } else {
                        returnval = 'Invalid OTP!';
                    }
                } else {
                    returnval = 'Exiperd OTP!';
                }
            } else{
                returnval = 'OTP is Not exist!';
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Exeception-->'+e.getMessage() + '---'+ e.getLineNumber());
            returnval = e.getMessage() +'=='+e.getLineNumber();
        }
        return returnval;
    }

    /**
     * Method Name  :   submitEligibility
     * @param       :   wrapData - Wrapper Data
     * @param       :   accountid - account id
     * @param       :   licensedata - Object Field API Name
     * @description :   Use to store record in backend
     * @return      :   String
     * Created By   :   Rammana (Focal CXM)
     * Created Date :   May 29 2024
     */
    @AuraEnabled
    public static String submitEligibility(String accountid) {
        try {
            // Query the eligibility record for the given account ID
            MSD_CORE_Eligibility__c eli = [
                SELECT ID, MSD_CORE_Account__c, MSD_CORE_Approver__c, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c
                FROM MSD_CORE_Eligibility__c 
                WHERE MSD_CORE_Account__c = :accountid 
                LIMIT 1
            ];
        
            // Query the active approval process instance related to the eligibility record
            List<ProcessInstance> approvalProcesses = [
                SELECT Id, Status, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems LIMIT 1)
                FROM ProcessInstance
                WHERE TargetObjectId = :eli.Id AND Status = 'Pending'
            ];

            if (!approvalProcesses.isEmpty()) {
                ProcessInstanceWorkitem workitem = approvalProcesses[0].Workitems[0];

                if (workitem != null) {
                    // Create the approval request
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workitem.Id);
                    req.setAction('Approve');
                    req.setComments('Approved via Apex');

                    // Submit the request for approval
                    Approval.ProcessResult result = Approval.process(req);

                    if (result.isSuccess()) {
                        // Update the status to Approved after successful approval
                        eli.MSD_CORE_Status__c = 'Approved';
                        update eli;

                        return 'Success';
                    } else {
                        System.debug('Failed to process approval request: ' + result.getErrors());
                        return 'Failed to process approval request: ' + result.getErrors();
                    }
                } else {
                    System.debug('No workitems found for the current user.');
                    return 'No workitems found for the current user.';
                }
            } else {
                System.debug('No pending approval processes found for the target object.');
                return 'No pending approval processes found for the target object.';
            }
        } catch (Exception e) {
            return 'Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber();
        }
    }

    /**
     * Method Name  :   updateEligibilityManualProcess
     * @param       :   accountid - account id
     * @description :   Use to update eligibility record status with Pending
     * @return      :   String
     * Created By   :   Rammana (Focal CXM)
     * Created Date :   May 29 2024
     */
    /**
     * Method Name  :   updateEligibilityManualProcess
     * @param       :   accountid - Account Id
     * @description :   Use to update eligibility record status with Pending
     * @return      :   String
     * Created By   :   Rammana (Focal CXM)
     * Created Date :   May 29 2024
     */
    @AuraEnabled
    public static String updateEligibilityManualProcess(String accountid) {
        try {
            // Query the eligibility record for the given account ID
            MSD_CORE_Eligibility__c eli = [
                SELECT Id, MSD_CORE_Account__c, MSD_CORE_Approver__c, MSD_CORE_Account__r.Primary_Executive__pc, 
                       MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, 
                       MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c
                FROM MSD_CORE_Eligibility__c 
                WHERE MSD_CORE_Account__c = :accountid 
                LIMIT 1
            ];

            // Check if the eligibility record was found
            if (eli != null) {
                // Update fields on the eligibility record
                
                eli.MSD_CORE_Status__c = 'Pending';
                eli.MSD_CORE_Stage__c = 'Personal';
                
                // Update the record
                update eli;
                return 'Success: Eligibility status updated to Pending';
            } else {
                return 'Error: No eligibility record found for the given account ID';
            }
        } catch (Exception e) {
            // Log the exception
            System.debug('Exception: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            return 'Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber();
        }
    }

}