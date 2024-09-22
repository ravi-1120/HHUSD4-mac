/**
 * Component Name:      MSD_CORE_RegistrationController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        24th May 2023
 * @description:        Server side controller for MSD_CORE_Registration LWC component
 * Test Class:          MSD_CORE_RegistrationControllerTest
 */

public without sharing class MSD_CORE_RegistrationController {
 
 
    /**
     * Method Name  :   savePassword
     * @param       :   recordId - Account record Id
     * @param       :   passwordval - Password Value
     * @description :   Use to store password value
     * @return      :   String
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   24th May 2023
     */
    @AuraEnabled
    public static String savePassword(String recordId, String passwordval){
        
        String returnval = '';
        try {
            List<MSD_CORE_Eligibility__c> eligibilitylst = [SELECT Id, MSD_CORE_Account__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Email__c, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Approver__c, MSD_CORE_Portal_User_Password__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c =: recordId LIMIT 1];
            if (eligibilitylst.size() > 0) {
                eligibilitylst[0].MSD_CORE_Portal_User_Password__c = passwordval;
                eligibilitylst[0].MSD_CORE_Status__c = 'In Progress';
                eligibilitylst[0].MSD_CORE_Stage__c = 'Password';
                eligibilitylst[0].MSD_CORE_Approver__c = eligibilitylst[0].MSD_CORE_Account__r.Primary_Executive__pc;
                update eligibilitylst;
            } else {
                Account ac = [SELECT Id, Name, PersonEmail, FirstName, Primary_Executive__pc FROM Account WHERE Id =: recordId];
                MSD_CORE_Eligibility__c ele = new MSD_CORE_Eligibility__c();
                ele.MSD_CORE_Portal_User_Password__c = passwordval;
                ele.MSD_CORE_Account__c = recordId;
                ele.Name = ac.Name;
                ele.MSD_CORE_First_Name__c = ac.FirstName;
                ele.MSD_CORE_Status__c = 'In Progress';
                ele.MSD_CORE_Stage__c = 'Password';
                ele.MSD_CORE_Approver__c = ac.Primary_Executive__pc;
                ele.MSD_CORE_Email__c = ac.PersonEmail;
                insert ele;
            }
            returnval = 'Record Save Successfully!';
        } catch (Exception e) {
            returnval = e.getMessage() + '----' +e.getLineNumber();
        }
        return returnval;
    }

    
    /**
     * Method Name  :   getAccountDetail
     * @param       :   recordId - Account record Id
     * @description :   Use to return Account record
     * @return      :   Account
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   29th May 2023
     */
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetail(String recordId){
        
        try {
            return [SELECT ID, Preferred_Salutation_MRK__c, Preferred_First_Name_MRK__c, Preferred_Last_Name_MRK__c, Preferred_Suffix_MRK__c, IMS_Sub_Specialty_MRK__c, MSD_CORE_IDS_Customer_Designation__c  FROM Account WHERE Id =: recordId];
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Method Name  :   getEligibilityDetail
     * @description :   Use to return eligibility record
     * @return      :   Eligibility
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   01 Aug 2023
     */
    @AuraEnabled
    public static MSD_CORE_Eligibility__c getEligibilityDetail(){
        try {
            return [SELECT Id, Name, MSD_CORE_Salutation__c, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Designation__c, MSD_CORE_Specialty__c, (SELECT Id, Name, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, MSD_CORE_Type_of_license__c FROM Licenses__r), MSD_CORE_Payor__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: UserInfo.getUserId() ORDER BY LastmodifiedDate DESC LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Method Name  :   getOrganizations
     * @param       :   searchKey
     * @description :   Use to retrieve Organization records
     * @return      :   MSD_CORE_Organization__c
     * Created By   :   Focal CXM
     */
    @AuraEnabled
    public static List<MSD_CORE_Organization__c> getOrganizations(String searchKey){
        string key1  = searchKey+'%';
        string key2  = '%'+searchKey;
        string key3  = '%'+searchKey+'%';
        try {
            if(String.isNotBlank(searchKey)){
               
                return [SELECT Id, Name FROM MSD_CORE_Organization__c WHERE Name like: key1 OR Name like: key2 OR Name like: key3 LIMIT 10 ];
            }else{
               
                 return [SELECT Id, Name FROM MSD_CORE_Organization__c Order by Name ASC LIMIT 10 ];
            }
            
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Method Name  :   getPicklistValue
     * @param       :   objectType - Object Field Api Name
     * @param       :   selectedField - Object Field Api Name
     * @description :   Use to return Picklist field value
     * @return      :   List<String>
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   31th May 2023
     */
    @AuraEnabled(cacheable=true)
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

    /**
     * Method Name  :   submitEligibility
     * @param       :   wrapData - Wrapper Data
     * @param       :   accountid - account id
     * @param       :   licensedata - Object Field API Name
     * @description :   Use to store record in backend
     * @return      :   String
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   31th May 2023
     */
    @AuraEnabled
    public static String submitEligibility(String accountid, String wrapData, String licensedata){
        
        String returnval = '';
        try {
            Map<String,object> mainmap = new Map<String, Object>();
            Map<String,object> mapdata = new Map<String, Object>();
            mainmap = (Map<String, Object>)JSON.deserializeUntyped(licensedata);

            MSD_CORE_Eligibility__c eli = [SELECT ID, MSD_CORE_Account__c,MSD_CORE_Approver__c, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c  FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c =: accountid];

            eligibilityWrap elewrap = (eligibilityWrap)JSON.deserialize(wrapData,eligibilityWrap.class);

            eli.MSD_CORE_Salutation__c = elewrap.salutation;
            eli.MSD_CORE_First_Name__c = elewrap.firstname;
            eli.MSD_CORE_Last_Name__c = elewrap.lastname;
            eli.Name = elewrap.firstname + ' ' + elewrap.lastname;
            eli.MSD_CORE_Suffix__c = elewrap.suffix;
            eli.MSD_CORE_Specialty__c = elewrap.specialty;
            eli.MSD_CORE_Designation__c = elewrap.designation;
            eli.MSD_CORE_Status__c = 'Pending';
            eli.MSD_CORE_Stage__c = 'Personal';
            
            update eli;
            
            List<License__c> liclst = new List<License__c>();

            for(String key: mainmap.keySet()){
                Object obj = mainmap.get(key);
                mapdata = (Map<String, Object>)obj;

                License__c lic = new License__c();
                lic.Name = String.ValueOf(mapdata.get('nameval'));
                lic.MSD_CORE_License_Number__c = String.ValueOf(mapdata.get('numberval'));
                lic.MSD_CORE_License_State__c = String.ValueOf(mapdata.get('stateval'));
                lic.MSD_CORE_Type_of_license__c = String.ValueOf(mapdata.get('typeval'));
                lic.MSD_CORE_Eligibility__c = eli.Id;

                liclst.add(lic);
            }

            insert liclst;
            returnval = 'Success';
            return returnval;
        } catch (Exception e) {
            return e.getMessage() +'----'+e.getLineNumber();
        }
    }

    /**
     * Method Name  :   getEligibilityDetails
     * @param       :   accountid - account id
     * @description :   Use to get Eligibility Details
     * @return      :   List<String>
     */
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Eligibility__c getEligibilityDetails(String accountid){
        List<MSD_CORE_Eligibility__c> eliList = new List<MSD_CORE_Eligibility__c>();
        MSD_CORE_Eligibility__c eli = new MSD_CORE_Eligibility__c();

        eliList = [Select Id,MSD_CORE_Organization_Type__c,MSD_CORE_Healthcare_Professional__c , MSD_CORE_Account__r.PersonEmail, MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c, MSD_CORE_Organization_Street_1__c, MSD_CORE_Organization_Street_2__c,MSD_CORE_Organization_City__c, MSD_CORE_Organization_ZIP__c, MSD_CORE_Organization_Phone__c, MSD_CORE_Organization_Extension__c, MS_CORE_Organization_State_Code__c, MSD_CORE_P_T_Process__c, MSD_CORE_Other_Role__c,MSD_CORE_Organization__c,MSD_CORE_Organization__r.Name, (Select Id,MSD_CORE_Email__c, MSD_CORE_Organization_Type__c, MSD_CORE_Organization__c, MSD_CORE_Organization__r.Name from Related_Organizations__r LIMIT 200) from MSD_CORE_Eligibility__c where MSD_CORE_Account__c=: accountid LIMIT 1];
        if( eliList.size() > 0){
            eli = eliList[0];
        }
       return  eli;
    }   

    /**
     * Method Name  :   saveEligibility
     * @param       :   accountid - account id
     * @param       :   wrapData - Wrapper Data
     * @description :   Use to Save Eligibility Details
     * @return      :   String
     */
    @AuraEnabled
    public static String saveEligibility(String accountid, String wrapData){
        String returnval = '';
        try {
            Map<String,object> mainmap = new Map<String, Object>();
            List<object> relatedOrgList = new List<object>();
            map<String, List<object>> orgNameMap = new Map<String, List<object>>();
            Map<String,object> mapdata = new Map<String, Object>();
            mainmap = (Map<String, Object>)JSON.deserializeUntyped(wrapData);
            relatedOrgList = (List<Object>)JSON.deserializeUntyped(JSON.serialize(mainmap.get('relatedOrg')));

            MSD_CORE_Eligibility__c eli;
            List<MSD_CORE_Eligibility__c> eligibilitylst = [SELECT ID, MSD_CORE_Account__c,MSD_CORE_Approver__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c  FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c =: accountid LIMIT 1];
            if (eligibilitylst.size() > 0) {
                eli = eligibilitylst[0];
                eli.MSD_CORE_Approver__c = eligibilitylst[0].MSD_CORE_Account__r.Primary_Executive__pc;
                
            } else {
                Account ac = [SELECT Id, Name, PersonEmail, FirstName, Primary_Executive__pc FROM Account WHERE Id =: accountid];
                eli = new MSD_CORE_Eligibility__c();
                eli.MSD_CORE_Account__c = accountid;
                eli.Name = ac.Name;
                eli.MSD_CORE_First_Name__c = ac.FirstName;
                eli.MSD_CORE_Email__c = ac.PersonEmail;
                eli.MSD_CORE_Approver__c = ac.Primary_Executive__pc;
            }
            eli.MSD_CORE_Status__c = 'In Progress';
            eli.MSD_CORE_Stage__c  = 'Eligibility';
            
            // MSD_CORE_Eligibility__c eli = [SELECT ID, MSD_CORE_Account__c,MSD_CORE_Approver__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c  FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c =: accountid];

            List<MSD_CORE_Related_Organizations__c> relatedOrganizationList = new List<MSD_CORE_Related_Organizations__c>();
            if(mainmap.get('orgId')!=null && String.isNotBlank(String.valueof(mainmap.get('orgId')))){
                eli.MSD_CORE_Organization__c = String.valueof(mainmap.get('orgId'));
            }else{
                String newOrgName = String.valueof(mainmap.get('orgname'));
                List<MSD_CORE_Organization__c> orglst = new List<MSD_CORE_Organization__c>();
                orglst = [Select Id, Name from MSD_CORE_Organization__c where Name=:newOrgName LIMIT 1];
                if(orglst.size() > 0 ){
                    eli.MSD_CORE_Organization__c = orglst[0].Id;
                }else{
                    MSD_CORE_Organization__c objMainOrg = new MSD_CORE_Organization__c();
                    objMainOrg.Name = String.valueof(mainmap.get('orgname'));
                    Insert objMainOrg;
                    eli.MSD_CORE_Organization__c = objMainOrg.Id;
                }
            }
            
            eli.MSD_CORE_Organization_Type__c = String.valueof(mainmap.get('orgtype'));
            eli.MSD_CORE_Role__c = String.valueof(mainmap.get('role'));
            eli.MSD_CORE_Organization_Street_1__c = String.valueof(mainmap.get('workstreetAddrVal'));
            eli.MSD_CORE_Organization_Street_2__c = String.valueof(mainmap.get('unitsuitVal'));
            eli.MSD_CORE_Organization_City__c = String.valueof(mainmap.get('cityVal'));
            eli.MSD_CORE_Organization_ZIP__c = String.valueof(mainmap.get('zipVal'));
            eli.MSD_CORE_Organization_Phone__c = String.valueof(mainmap.get('workPhoneVal'));
            eli.MSD_CORE_Organization_Extension__c = String.valueof(mainmap.get('extVal'));
            eli.MS_CORE_Organization_State_Code__c = String.valueof(mainmap.get('state'));
            eli.MSD_CORE_P_T_Process__c = Boolean.valueof(mainmap.get('pt'));
            eli.MSD_CORE_Other_Role__c = String.valueof(mainmap.get('otherRole'));
            eli.MSD_CORE_Healthcare_Professional__c = Boolean.valueof(mainmap.get('healthdecisionmaker'));
            Set<String> orgNameSet = new Set<String>();
            if(relatedOrgList.size() >0 && eli.MSD_CORE_Role__c == 'Consultant' ){
                for(object relatedOrg: relatedOrgList){
                    Map<String,object> relatedOrgMapValues = new Map<String, Object>();
                    relatedOrgMapValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(relatedOrg)); 
                    MSD_CORE_Related_Organizations__c relatedOrgObj = new MSD_CORE_Related_Organizations__c();
                    relatedOrgObj.MSD_CORE_Eligibility__c = eli.Id;
                    if(relatedOrgMapValues.get('orgId')!=null){
                        relatedOrgObj.MSD_CORE_Organization__c = String.valueOf(relatedOrgMapValues.get('orgId'));
                    }else {
                        if(relatedOrgMapValues.get('orgname')!=null){
                            orgNameSet.add(String.valueOf(relatedOrgMapValues.get('orgname')));
                            if(!orgNameMap.containsKey(String.valueOf(relatedOrgMapValues.get('orgname')))){
                                orgNameMap.put(String.valueOf(relatedOrgMapValues.get('orgname')), new List<object>{relatedOrg}  );
                            }else{
                                orgNameMap.get(String.valueOf(relatedOrgMapValues.get('orgname'))).add(relatedOrg );
                            }
                        }
                    }
                    
                    if(Boolean.valueOf(relatedOrgMapValues.get('diffemail'))){
                        relatedOrgObj.MSD_CORE_Email__c = String.valueOf(relatedOrgMapValues.get('diffemailAddress'));
                    }else{
                        relatedOrgObj.MSD_CORE_Email__c = eli.MSD_CORE_Account__r.PersonEmail;
                    }
                    if(relatedOrgMapValues.get('relatedOrgId')!=null){
                        if(String.isNotBlank(String.valueOf(relatedOrgMapValues.get('relatedOrgId')))){
                            relatedOrgObj.Id = String.valueOf(relatedOrgMapValues.get('relatedOrgId'));
                        }
                    }
                    relatedOrgObj.MSD_CORE_Organization_Type__c = String.valueOf(relatedOrgMapValues.get('orgtype'));
                    if(relatedOrgMapValues.get('orgId')!=null){
                        relatedOrganizationList.add(relatedOrgObj);
                    }
                }
            }
            
            List<MSD_CORE_Organization__c> existingOrgList = [SELECT Id, Name FROM MSD_CORE_Organization__c WHERE Name IN : orgNameMap.keyset()];
            Map<String, MSD_CORE_Organization__c> existingOrgMap = new Map<String, MSD_CORE_Organization__c>();
            if( eli.MSD_CORE_Role__c == 'Consultant' ){
                for(MSD_CORE_Organization__c existOrg: existingOrgList){
                    if(!existingOrgMap.containsKey(existOrg.Name)){
                        existingOrgMap.put(existOrg.Name, existOrg);
                    }
                }
            }
            if( eli.MSD_CORE_Role__c == 'Consultant' ){
                List<MSD_CORE_Organization__c> orgList = new List<MSD_CORE_Organization__c>();
                for(String orgName: orgNameMap.keyset()){
                    if(!existingOrgMap.containsKey(orgName)){
                        MSD_CORE_Organization__c objOrg = new MSD_CORE_Organization__c();
                        objOrg.Name = orgName;
                        orgList.add(objOrg);
                    }
                }
                insert orgList;
                Map<String, MSD_CORE_Organization__c> mapOrg = new Map<String, MSD_CORE_Organization__c>();
                for(MSD_CORE_Organization__c objOrg: orgList){
                    if(!mapOrg.containsKey(objOrg.Name)){
                        mapOrg.put(objOrg.Name, objOrg);
                    }
                }
                mapOrg.putAll(existingOrgMap);
            
                for(String orgName: orgNameSet){
                    if(orgNameMap.containskey(orgName)){
                        for(object relatedOrg: orgNameMap.get(orgName) ){
                            Map<String,object> relatedOrgMapValues = new Map<String, Object>();
                            relatedOrgMapValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(relatedOrg)); 
                            MSD_CORE_Related_Organizations__c relatedOrgObj = new MSD_CORE_Related_Organizations__c();
                            relatedOrgObj.MSD_CORE_Eligibility__c = eli.Id;
                            relatedOrgObj.MSD_CORE_Organization__c = mapOrg.get(orgName).Id;
                            
                            if(Boolean.valueOf(relatedOrgMapValues.get('diffemail'))){
                                relatedOrgObj.MSD_CORE_Email__c = String.valueOf(relatedOrgMapValues.get('diffemailAddress'));
                            }else{
                                relatedOrgObj.MSD_CORE_Email__c = eli.MSD_CORE_Account__r.PersonEmail;
                            }
                            relatedOrgObj.MSD_CORE_Organization_Type__c = String.valueOf(relatedOrgMapValues.get('orgtype'));
                            relatedOrganizationList.add(relatedOrgObj);
                        }
                    }
                }
            }
            upsert eli;

            if(relatedOrgList.size()>0 && eli.MSD_CORE_Role__c == 'Consultant' ){
                Upsert relatedOrganizationList;
            }
            returnval = 'Success';
            return returnval;
        } catch (Exception e) {
            return e.getMessage() +'----'+e.getLineNumber();
        }
    }

    /**
     * Method Name  :   checkExistingUser
     * @param       :   recordId - account id
     * @param       :   checkExpiration 
     * @param       :   isResend 
     * @description :   Use to store record in backend
     * @return      :   registrationwrap
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   18 July 2023
     */
    @AuraEnabled
    public static registrationwrap checkExistingUser(String recordId, Boolean checkExpiration, Boolean isResend){
        try {

            Datetime timestamp;
            List<Account> acclst = [SELECT Id, Name, PersonEmail, IsPersonAccount, IsCustomerPortal, MSD_CORE_Registration_Inv_Timestamp__c FROM Account WHERE Id =: recordId LIMIT 1];    
            
            registrationwrap wrap = new registrationwrap();
            if (isResend) {
                timestamp = acclst[0].MSD_CORE_Registration_Inv_Timestamp__c;
            } else {
                List<Sent_Email_vod__c> sentemail = [SELECT Id, Email_Sent_Date_vod__c, Approved_Email_Template_vod__r.Name, Account_vod__c FROM Sent_Email_vod__c WHERE Approved_Email_Template_vod__c =: System.Label.MSD_CORE_MFRPortalRegistrationInvitation AND Account_vod__c =: recordId  ORDER BY Email_Sent_Date_vod__c DESC LIMIT 1];
                if (sentemail.size()>0) {
                    timestamp = sentemail[0].Email_Sent_Date_vod__c;
                } else {
                    wrap.isLinkInvalid = true;
                }
            }

            if (acclst.size()>0) {
                wrap.accEmail = acclst[0].PersonEmail;
                Decimal duration = [SELECT Id, Label, MSD_CORE_Duration__c FROM MFR_Config__mdt WHERE Label = 'Registration Invitation Expiration'].MSD_CORE_Duration__c;
                if(timestamp != null && checkExpiration){
                    if (timestamp.addHours(Integer.valueOf(duration)) < System.now()) {
                        wrap.isExpiredInvitation = true;
                    } else {
                        wrap.isExpiredInvitation = false;
                    }
                    if(acclst[0].IsCustomerPortal == true){
                        wrap.isExistingCustomer = true;
                    } else {
                        wrap.isExistingCustomer = false;
                    }
                }
                List<MSD_CORE_Eligibility__c> elilst = [SELECT Id, MSD_CORE_Account__c, MSD_CORE_Stage__c, MSD_CORE_Status__c  FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c =: acclst[0].Id LIMIT 1];
                if (elilst.size()>0) {
                    wrap.isEligibilityExist = true;
                    wrap.eligibilityStatus = elilst[0].MSD_CORE_Status__c;
                    wrap.eligibilityStage = elilst[0].MSD_CORE_Stage__c;
                } else {
                    wrap.isEligibilityExist = false;
                    wrap.eligibilityStatus = '';
                    wrap.eligibilityStage = '';
                }
                wrap.checkUserExist = true;
            } else {
                wrap.checkUserExist = false;
            }
            return wrap;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Exeception-->'+e.getMessage() + '---'+ e.getLineNumber());
            return null;
        }
    }

    /**
     * Method Name  :   createOTP
     * @param       :   recordId - account id
     * @description :   Use to create OTP Record
     * @return      :   OTP Stringe
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   31 July 2023
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
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   01 Aug 2023
     */
    @AuraEnabled
    public static String submitOTP(String recordId, String otpval){
        String returnval;
        try {
            List<MSD_CORE_OTP__c> otplst = [SELECT Id, MSD_CORE_Token__c, MSD_CORE_Expired__c FROM MSD_CORE_OTP__c WHERE Id =: recordId];
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
     * Method Name  :   resetUserPassword
     * @param       :   request - Input values from flow
     * @description :   Reset password for portal user. Invoked from Eligibility_RT_Flow
     * @return      :   List<String>
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   01 June 2023
     */
    @InvocableMethod(label='Reset portal user password')
    public static List<String> resetUserPassword(List<Requests> request) {
        try {
            // Blob cryptoKey = Crypto.generateAesKey(256);        
            // Blob data = Blob.valueOf(request[0].password);
            // Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);        
            // Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, data);
            System.setPassword(request[0].userid,request[0].password);
            return new List<String>{'Success'};
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getMessage());
            return new List<String>{e.getMessage()};
        }
    }

    /**
     * @description Requests
     */
    public class Requests {
        @InvocableVariable(label='UserId' description='userid' required=true)
        public String userid;
        @InvocableVariable(label='Password' description='password' required=true)
        public String password;
    }

    /**
     * @description eligibilityWrap
     */
    public class eligibilityWrap{
        
         /**
         * @description salutation
         * @return salutation
         */
        @AuraEnabled
        public String salutation{get;set;}
        /**
         * @description firstname
         * @return firstname
         */
        @AuraEnabled
        public String firstname{get;set;}
        /**
         * @description lastname
         * @return lastname
         */
        @AuraEnabled
        public String lastname{get;set;}
        /**
         * @description suffix
         * @return suffix
         */
        @AuraEnabled
        public String suffix{get;set;}
        /**
         * @description designation
         * @return designation
         */
        @AuraEnabled
        public String designation{get;set;}
        /**
         * @description specialty
         * @return specialty
         */
        @AuraEnabled
        public String specialty{get;set;}
    }

    /**
     * @description licensewrap
     */
    public class licensewrap{
        /**
         * @description nameval
         * @return nameval
         */
        @AuraEnabled
        public String nameval{get;set;}
        /**
         * @description numberval
         * @return numberval
         */
        @AuraEnabled
        public String numberval{get;set;}
        /**
         * @description stateval
         * @return stateval
         */
        @AuraEnabled
        public String stateval{get;set;}
        /**
         * @description typeval
         * @return typeval
         */
        @AuraEnabled
        public String typeval{get;set;}
    }

    /**
     * @description registrationwrap
     */
    public class registrationwrap{
        /**
         * @description isExpiredInvitation
         * @return isExpiredInvitation
         */
        @AuraEnabled
        public Boolean isExpiredInvitation{get;set;}
        /**
         * @description isExistingCustomer
         * @return isExistingCustomer
         */
        @AuraEnabled
        public Boolean isExistingCustomer{get;set;}
        /**
         * @description eligibilityStatus
         * @return eligibilityStatus
         */
        @AuraEnabled
        public String eligibilityStatus{get;set;}
        /**
         * @description eligibilityStage
         * @return eligibilityStage
         */
        @AuraEnabled
        public String eligibilityStage{get;set;}
        /**
         * @description checkUserExist
         * @return checkUserExist
         */
        @AuraEnabled
        public Boolean checkUserExist{get;set;}
        /**
         * @description isEligibilityExist
         * @return isEligibilityExist
         */
        @AuraEnabled
        public Boolean isEligibilityExist{get;set;}
        /**
         * @description isLinkInvalid
         * @return isLinkInvalid
         */
        @AuraEnabled
        public Boolean isLinkInvalid{get;set;}
        /**
         * @description accEmail
         * @return accEmail
         */
        @AuraEnabled
        public String accEmail{get;set;}
    }

    @AuraEnabled 
     public static void updateResendInvitation (String accountid){
         Account acc = [SELECT Id, MSD_CORE_Resend_Invitation__c FROM Account WHERE Id = :accountid];
         acc.MSD_CORE_Resend_Invitation__c = true;
         update acc;
     }
 

}