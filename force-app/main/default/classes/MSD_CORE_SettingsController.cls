/**
 * Component Name:      MSD_CORE_SettingsController 
 * Created By:          (Focal CXM)
 * Description:         Used for login into the community portal
 * Test Class:          MSD_CORE_SettingsController _Test
 * @description :       MSD_CORE_SettingsController 
 */

public without sharing class MSD_CORE_SettingsController {
      /**
     * @description getEligibilityRecords
     * @return cw
     * @param userId
    */
    
    @AuraEnabled(cacheable=true)
    public static Eligibilitywrapper getEligibilityRecords(String userId) {
        System.debug('User ID: ' + userId);
        System.debug('User ID250: ' + userId);
        
        List<MSD_CORE_Eligibility__c> eligibilityRecords = [SELECT Id,MSD_CORE_Last_Review_Date__c, MSD_CORE_Next_Review_Date__c, MSD_CORE_Eligibility_Expired__c,MSD_CORE_Organization_Type__c,MSD_CORE_Healthcare_Professional__c , MSD_CORE_Account__r.PersonEmail, MSD_CORE_First_Name__c,MSD_CORE_Specialty__c,MSD_CORE_Suffix__c,
                                                            MSD_CORE_Last_Name__c,MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c, MSD_CORE_Organization_Street_1__c, MSD_CORE_Organization_Street_2__c,MSD_CORE_Designation__c,
                                                            MSD_CORE_Organization_City__c, MSD_CORE_Organization_ZIP__c, MSD_CORE_Organization_Phone__c, MSD_CORE_Organization_Extension__c,MSD_CORE_Salutation__c,Name,MS_CORE_Organization_State_Code__c,
                                                            MSD_CORE_P_T_Process__c, MSD_CORE_Other_Role__c,MSD_CORE_Organization__c,MSD_CORE_Organization__r.Name,
                                                            (SELECT Id,MSD_CORE_Organization_Type__c,MSD_CORE_Organization__r.Name,MSD_CORE_Email__c,MSD_CORE_Eligibility__r.Name FROM Related_Organizations__r WHERE MSD_CORE_Is_Active__c = True),
                                                            (SELECT Id, MSD_CORE_Organization_Type__c, Contact__c, MSD_CORE_Email_Address__c,
                                                            MSD_CORE_License_Number__c, MSD_CORE_License_State__c, Name, MSD_CORE_Type_of_license__c FROM Licenses__r)
                                                            FROM MSD_CORE_Eligibility__c WHERE  MSD_CORE_Payor__c =:userId]; 
        
        System.debug('eligibilityRecords' +eligibilityRecords);
        List<Eligibilitywrapper> ew = new List<Eligibilitywrapper>();
        if(eligibilityRecords.size() > 0){
            Eligibilitywrapper cw = new Eligibilitywrapper();
            cw.firstName = eligibilityRecords[0].MSD_CORE_First_Name__c;
            cw.lastName =  eligibilityRecords[0]. MSD_CORE_Last_Name__c;	
            cw.organizationName = eligibilityRecords[0].MSD_CORE_Organization__r.Name;
            cw.organizationType = eligibilityRecords[0].MSD_CORE_Organization_Type__c;
            cw.role = eligibilityRecords[0].MSD_CORE_Role__c;
            cw.name = eligibilityRecords[0].Name;
            cw.healthdecisionmaker = eligibilityRecords[0].MSD_CORE_Healthcare_Professional__c;
            cw.work = eligibilityRecords[0].MSD_CORE_Organization_Street_1__c;
            cw.workstreet = eligibilityRecords[0].MSD_CORE_Organization_Street_2__c;
            cw.city = eligibilityRecords[0].MSD_CORE_Organization_City__c;
            cw.zip = eligibilityRecords[0].MSD_CORE_Organization_ZIP__c;
            cw.phone = eligibilityRecords[0].MSD_CORE_Organization_Phone__c;
            cw.extension = eligibilityRecords[0].MSD_CORE_Organization_Extension__c;
            cw.ptprocess = eligibilityRecords[0].MSD_CORE_P_T_Process__c;  
            cw.salutation = eligibilityRecords[0].MSD_CORE_Salutation__c;
            cw.specialty = eligibilityRecords[0].MSD_CORE_Specialty__c;
            cw.statecode = eligibilityRecords[0].MS_CORE_Organization_State_Code__c;
            cw.otherrole = eligibilityRecords[0].MSD_CORE_Other_Role__c;
            cw.suffix = eligibilityRecords[0].MSD_CORE_Suffix__c;
            cw.designation = eligibilityRecords[0].MSD_CORE_Designation__c;
            cw.relatedLicense = new List<LicenseWrapper>();
            Integer i =1;
            for(License__c l: eligibilityRecords[0].Licenses__r){
                cw.relatedLicense.add(new LicenseWrapper(i, l));
                i++;
            }
            cw.relatedOrganizations = eligibilityRecords[0].Related_Organizations__r;
            cw.eligibilityExpired = eligibilityRecords[0].MSD_CORE_Eligibility_Expired__c;
            cw.nextReviewDueDate = eligibilityRecords[0].MSD_CORE_Next_Review_Date__c;
            cw.eligibilityStatus = eligibilityRecords[0].MSD_CORE_Status__c;
            
            
            cw.accountLocked = cw.eligibilityExpired ? true : false;

            if(eligibilityRecords[0].MSD_CORE_Status__c == 'Pending'){
                cw.reviewStatus = 'Under Review';
                cw.showRed = true;
                cw.disableEligibilityUpdate = true;
                cw.hideReviewLabel = false;
            }else if(eligibilityRecords[0].MSD_CORE_Status__c == 'Rejected'){
                cw.reviewStatus = 'Rejected';
                cw.showRed = true;
                cw.disableEligibilityUpdate = true;
                cw.accountLocked = true;
                cw.hideReviewLabel = true;
            }else{
                if(eligibilityRecords[0].MSD_CORE_Eligibility_Expired__c){
                    cw.reviewStatus = 'Eligibility expired';
                    cw.showRed = true;
                    cw.accountLocked = true;
                    cw.hideReviewLabel = true;
                }else if(System.today().daysBetween(eligibilityRecords[0].MSD_CORE_Next_Review_Date__c) <= 31){
                    Integer dayDiff = System.today().daysBetween(eligibilityRecords[0].MSD_CORE_Next_Review_Date__c);
                    cw.reviewStatus = 'Review due in ' + dayDiff + (dayDiff > 1 ? ' days':' day');
                    cw.showRed = true;
                    cw.hideReviewLabel = false;
                }else{
                    Integer monthDiff = System.today().monthsBetween(eligibilityRecords[0].MSD_CORE_Next_Review_Date__c);
                    cw.reviewStatus = 'Review due in ' + monthDiff + (monthDiff > 1 ? ' months' : ' month');
                    cw.showRed = false;
                    cw.hideReviewLabel = false;
                }
            }
            return cw;
        }else{
            Eligibilitywrapper cw = new Eligibilitywrapper();
            Id contactid = [SELECT Id, ContactID FROM User WHERE Id =: userId].ContactId;
            List<Contact> conrecords = [Select Id,FirstName,LastName,Salutation,MSD_CORE_Title__c
            From Contact WHERE MSD_CORE_Health_Care_Decision_Maker__c = TRUE AND Id=: contactid ];
            System.debug(conrecords);
            System.debug('cw'+conrecords);
            cw.Id = conrecords[0].Id;
            cw.firstName = conrecords[0].FirstName;
            cw.lastName =conrecords[0].LastName;
            cw.salutation = conrecords[0].Salutation;
            cw.title = conrecords[0].MSD_CORE_Title__c;
            system.debug('wrapper'+cw);
            return cw;              
        }
    }

    public class Eligibilitywrapper{
        /**
         * @description id
         * @return id
         */
        @AuraEnabled public id id { get; set; }
        
        /**
         * @description name
         * @return name
         */
        @AuraEnabled public String name { get; set; }
          /**
         * @description firstName
         * @return firstName
         */
        @AuraEnabled public String firstName { get; set; }
          /**
         * @description lastName
         * @return lastName
         */
        @AuraEnabled
        public String lastName { get; set; }
          /**
         * @description salutation
         * @return salutation
         */
        @AuraEnabled
        public String salutation { get; set; }
          /**
         * @description work
         * @return work
         */
        @AuraEnabled
        public String work { get; set; }
          /**
         * @description workstreet
         * @return workstreet
         */
        @AuraEnabled
        public String workstreet { get; set; }
          /**
         * @description city
         * @return city
         */
        @AuraEnabled
        public String city { get; set; }
          /**
         * @description zip
         * @return zip
         */
        @AuraEnabled
        public String zip { get; set; }
          /**
         * @description state
         * @return state
         */
        @AuraEnabled
        public String state { get; set; }
          /**
         * @description ptprocess
         * @return ptprocess
         */
        @AuraEnabled
        public Boolean ptprocess { get; set; }
          /**
         * @description specialty
         * @return specialty
         */
        @AuraEnabled
        public String specialty { get; set; }
          /**
         * @description conrecords
         * @return conrecords
         */
        @AuraEnabled
        public Contact conrecords {get;set;}
          /**
         * @description healthdecisionmaker
         * @return healthdecisionmaker
         */
        @AuraEnabled
        public Boolean healthdecisionmaker {get;set;} 
          /**
         * @description orgname
         * @return orgname
         */
        @AuraEnabled
        public String orgname   {get;set;}
          /**
         * @description organizationName
         * @return organizationName
         */
        @AuraEnabled
        public String organizationName {get;set;}
          /**
         * @description organizationType
         * @return organizationType
         */
        @AuraEnabled
        public String organizationType {get;set;}
          /**
         * @description role
         * @return role
         */
        @AuraEnabled
        public String role {get;set;}
          /**
         * @description phone
         * @return phone
         */
        @AuraEnabled
        public String phone {get;set;}
          /**
         * @description extension
         * @return extension
         */
        @AuraEnabled
        public String extension {get;set;}
          /**
         * @description title
         * @return title
         */
        @AuraEnabled
        public String title {get;set;}
          /**
         * @description statecode
         * @return statecode
         */
        @AuraEnabled
        public String statecode {get;set;}
          /**
         * @description otherrole
         * @return otherrole
         */
        @AuraEnabled
        public String otherrole {get;set;}
          /**
         * @description suffix
         * @return suffix
         */
        @AuraEnabled
        public String suffix {get;set;}
          /**
         * @description designation
         * @return designation
         */
        @AuraEnabled
        public String designation {get;set;}
          /**
         * @description relatedLicense
         * @return relatedLicense
         */
        @AuraEnabled
        public List<LicenseWrapper> relatedLicense {get;set;}
          /**
         * @description relatedOrganizations
         * @return relatedOrganizations
         */
        @AuraEnabled
        public List<MSD_CORE_Related_Organizations__c> relatedOrganizations {get;set;}
          /**
         * @description reviewStatus
         * @return reviewStatus
         */
        @AuraEnabled
        public string reviewStatus {get;set;}
          /**
         * @description nextReviewDueDate
         * @return nextReviewDueDate
         */
        @AuraEnabled
        public Date nextReviewDueDate {get;set;}
          /**
         * @description eligibilityStatus
         * @return eligibilityStatus
         */
        @AuraEnabled
        public String eligibilityStatus{get;set;}
          /**
         * @description showRed
         * @return showRed
         */
        @AuraEnabled
        public Boolean showRed{get;set;}
          /**
         * @description hideReviewLabel
         * @return hideReviewLabel
         */
        @AuraEnabled
        public Boolean hideReviewLabel{get;set;}
          /**
         * @description eligibilityExpired
         * @return eligibilityExpired
         */
        @AuraEnabled
        public Boolean eligibilityExpired{get;set;}
          /**
         * @description accountLocked
         * @return accountLocked
         */
        @AuraEnabled
        public Boolean accountLocked{get;set;}
          /**
         * @description disableEligibilityUpdate
         * @return disableEligibilityUpdate
         */
        @AuraEnabled
        public Boolean disableEligibilityUpdate{get;set;}
    }
    
    public class LicenseWrapper{
         /**
         * @description serialNum
         * @return serialNum
         */       
        @AuraEnabled
        public Integer serialNum {get;set;}
        /**
         * @description license
         * @return license
         */
        @AuraEnabled
        public License__c license {get;set;}

        public LicenseWrapper(Integer serialNum,License__c license ){
            this.serialNum = serialNum;
            this.license = license;
        }
    }

     /**
     * @description getEligibilityDetails
     * @return eli
     * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Eligibility__c getEligibilityDetails(String userId){
        MSD_CORE_Eligibility__c eli = new MSD_CORE_Eligibility__c();

        List<MSD_CORE_Eligibility__c> eliList = [SELECT Id, MSD_CORE_Organization_Type__c, MSD_CORE_Healthcare_Professional__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c, MSD_CORE_Organization_Street_1__c, MSD_CORE_Organization_Street_2__c, MSD_CORE_Organization_City__c, MSD_CORE_Organization_ZIP__c, MSD_CORE_Organization_Phone__c, MSD_CORE_Organization_Extension__c, MS_CORE_Organization_State_Code__c, MSD_CORE_P_T_Process__c, MSD_CORE_Other_Role__c,MSD_CORE_Organization__c,MSD_CORE_Organization__r.Name, 
                                                (Select Id, MSD_CORE_Email__c, MSD_CORE_Is_Active__c, MSD_CORE_Organization_Type__c, MSD_CORE_Organization__c, MSD_CORE_Organization__r.Name FROM Related_Organizations__r WHERE MSD_CORE_Is_Active__c = True LIMIT 200) 
                                                FROM MSD_CORE_Eligibility__c WHERE  MSD_CORE_Payor__c =: userId LIMIT 1];
        if( eliList.size() > 0){
            eli = eliList[0];
        }
        return  eli;
    }
    
     /**
     * @description submitEligibility
     * @return returnValue
     * @param userId
     * @param wrapData
    */

    @AuraEnabled
    public static String submitEligibility(String userId, String wrapData){
        System.debug('entered inside');
        String returnValue = '';
        
        try{
            Map<String,object> mainmap = new Map<String, Object>();
            List<object> relatedOrgList = new List<object>();
            map<String, List<object>> orgNameMap = new Map<String, List<object>>();
            Map<String,object> mapdata = new Map<String, Object>();
            mainmap = (Map<String, Object>)JSON.deserializeUntyped(wrapData);
            relatedOrgList = (List<Object>)JSON.deserializeUntyped(JSON.serialize(mainmap.get('relatedOrg')));
            
            MSD_CORE_Eligibility__c eli = [SELECT ID, MSD_CORE_Account__c,MSD_CORE_Role__c,MSD_CORE_Approver__c, MSD_CORE_Account__r.PersonEmail, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c  FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId];
            
            System.debug('entered insiderole'+ eli );
            System.debug('entered insiderole'+ eli.MSD_CORE_Role__c);
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
            
            eli.MSD_CORE_Organization_Type__c =String.valueof(mainmap.get('orgtype'));
            eli.MSD_CORE_Role__c =String.valueof(mainmap.get('role'));
            System.debug('oldrole1'+ eli.MSD_CORE_Role__c);
            eli.MSD_CORE_Status__c = 'Pending';
            eli.MSD_CORE_Stage__c  = 'Eligibility';
            eli.MSD_CORE_Organization_Street_1__c  = String.valueof(mainmap.get('workstreetAddrVal'));
            eli.MSD_CORE_Organization_Street_2__c  = String.valueof(mainmap.get('unitsuitVal'));
            eli.MSD_CORE_Organization_City__c  = String.valueof(mainmap.get('cityVal'));
            eli.MSD_CORE_Organization_ZIP__c  = String.valueof(mainmap.get('zipVal'));
            eli.MSD_CORE_Organization_Phone__c  = String.valueof(mainmap.get('workPhoneVal'));
            eli.MSD_CORE_Organization_Extension__c  = String.valueof(mainmap.get('extVal'));
            eli.MS_CORE_Organization_State_Code__c = String.valueof(mainmap.get('state'));
            eli.MSD_CORE_P_T_Process__c = Boolean.valueof(mainmap.get('pt'));
            eli.MSD_CORE_Other_Role__c = String.valueof(mainmap.get('otherRole'));
            eli.MSD_CORE_Healthcare_Professional__c   = Boolean.valueof(mainmap.get('healthdecisionmaker'));
            System.debug(mainmap.get('role')+ 'role type1');
            System.debug(eli.MSD_CORE_Role__c+ 'role typecons');
            Set<String> orgNameSet = new Set<String>();
            if(relatedOrgList.size()>0 ){
                System.debug(mainmap.get('role')+ 'role type2');
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
                    
                    if(Boolean.valueOf(relatedOrgMapValues.get('isactive'))){
                        relatedOrgObj.MSD_CORE_Is_Active__c = Boolean.valueOf(relatedOrgMapValues.get('isactive'));
                    }else{
                        relatedOrgObj.MSD_CORE_Is_Active__c = Boolean.valueOf(relatedOrgMapValues.get('isactive'));
                    }
                    System.debug(mainmap.get('role')+ 'role type');
                    if((String.valueof(mainmap.get('role'))) != 'Consultant') {
                        System.debug(mainmap.get('role')+ 'role type4');
                    relatedOrgObj.MSD_CORE_Is_Active__c = FALSE;
                    //eli.MSD_CORE_Role__c =String.valueof(mainmap.get('role'));
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
            List<MSD_CORE_Organization__c> existingOrgList = [Select Id, Name from MSD_CORE_Organization__c where Name IN: orgNameMap.keyset() ];
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
                Insert orgList;
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
                        if(Boolean.valueOf(relatedOrgMapValues.get('isactive'))){
                            relatedOrgObj.MSD_CORE_Is_Active__c = Boolean.valueOf(relatedOrgMapValues.get('isactive'));
                        }else{
                            relatedOrgObj.MSD_CORE_Is_Active__c = Boolean.valueOf(relatedOrgMapValues.get('isactive'));
                        }
                        if((String.valueof(mainmap.get('role'))) != 'Consultant') {
                            relatedOrgObj.MSD_CORE_Is_Active__c = FALSE;
                            //eli.MSD_CORE_Role__c =String.valueof(mainmap.get('role'));
                        }
                            relatedOrgObj.MSD_CORE_Organization_Type__c = String.valueOf(relatedOrgMapValues.get('orgtype'));
                            relatedOrganizationList.add(relatedOrgObj);
                        }
                    }
                }
            }
            //eli.MSD_CORE_Role__c =String.valueof(mainmap.get('role'));
            update eli;
            if(relatedOrgList.size()>0 ){
                System.debug('updated');
                Upsert  relatedOrganizationList;
            }

            returnValue = 'Success';
        }catch (exception e){
            returnValue = e.getMessage() +'----'+e.getLineNumber();
        }
        return returnValue;
    }

    /**
     * Method Name  :   submitPersonalPage
     * @param       :   wrapData - Wrapper Data
     * @param       :   licensedata - Object Field API Name
     * @description :   Use to store record in backend
     * @return      :   String
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   07 Aug 2023
     */
    @AuraEnabled
    public static String submitPersonalPage(String wrapData, String licensedata){
        
        String returnval = '';
        try {
            Map<String,object> mainmap = new Map<String, Object>();
            Map<String,object> mapdata = new Map<String, Object>();
            mainmap = (Map<String, Object>)JSON.deserializeUntyped(licensedata);

            MSD_CORE_Eligibility__c eli = [SELECT ID, MSD_CORE_Account__c,MSD_CORE_Approver__c, MSD_CORE_Account__r.Primary_Executive__pc, MSD_CORE_Salutation__c, Name, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Payor__c, MSD_CORE_Status__c, MSD_CORE_Stage__c  FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: UserInfo.getUserId()];

            eligibilityWrap elewrap = (eligibilityWrap)JSON.deserialize(wrapData,eligibilityWrap.class);

            eli.MSD_CORE_Salutation__c = elewrap.salutation;
            eli.MSD_CORE_First_Name__c = elewrap.firstname;
            eli.MSD_CORE_Last_Name__c = elewrap.lastname;
            eli.Name = elewrap.firstname + ' ' + elewrap.lastname;
            eli.MSD_CORE_Suffix__c = elewrap.suffix;
            eli.MSD_CORE_Specialty__c = elewrap.speciality;
            eli.MSD_CORE_Designation__c = elewrap.designation;
            eli.MSD_CORE_Stage__c = 'Personal';
            
            update eli;
            
            List<License__c> liclst = new List<License__c>();

            List<License__c> oldlic = [SELECT Id, Name, MSD_CORE_Eligibility__c FROM License__c WHERE MSD_CORE_Eligibility__c =: eli.Id];
            delete oldlic;
            for(String key: mainmap.keySet()){
                Object obj = mainmap.get(key);
                mapdata = (Map<String, Object>)obj;
                License__c lic = new License__c();
                // if (!String.isEmpty(String.ValueOf(mapdata.get('recordval')))) {
                //     lic = [SELECT Id, Name, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, MSD_CORE_Type_of_license__c, MSD_CORE_Eligibility__c FROM License__c WHERE Id =: String.ValueOf(mapdata.get('recordval')) LIMIT 1];
                // } else {
                //     lic = new License__c();
                // }
                
                lic.Name = String.ValueOf(mapdata.get('nameval'));
                lic.MSD_CORE_License_Number__c = String.ValueOf(mapdata.get('numberval'));
                lic.MSD_CORE_License_State__c = String.ValueOf(mapdata.get('stateval'));
                lic.MSD_CORE_Type_of_license__c = String.ValueOf(mapdata.get('typeval'));
                lic.MSD_CORE_Eligibility__c = eli.Id;

                liclst.add(lic);
            }

            upsert liclst;
            returnval = 'Success';
            return returnval;
        } catch (Exception e) {
            return e.getMessage() +'----'+e.getLineNumber();
        }
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
         * @description speciality
         * @return speciality
         */ 
        @AuraEnabled
        public String speciality{get;set;}
    }


    //Notification Page Logic
    @AuraEnabled
    public static User getPayorNotificationsData(){
        return [SELECT Id, Daily_Digest_Summary__c, MSD_Core_Request_Confirmation_Messages__c, 
                MSD_Core_Appointment_Notifications__c, MSD_Core_Closed_Request__c, MSD_Core_Expiring_Resources__c, 
                Prior_Days_to_Expire__c
                FROM User WHERE Id =: UserInfo.getUserId()];
    }

    @AuraEnabled
    public static List<PicklistOption> getPriorDaysExpireList(){
        List<PicklistOption> pickListValuesList= new List<PicklistOption>();

        for( Schema.PicklistEntry pickListVal : User.Prior_Days_to_Expire__c.getDescribe().getPicklistValues()){
            String label = pickListVal.getLabel();
            String value = pickListVal.getValue();
            
            if (value == '10') {
                label += ' days (default)';
            } else {
                label += ' days';
            }
            
            pickListValuesList.add(new PicklistOption(label, value));
        }     
        return pickListValuesList;
    }

    //Update notification settings 
    @AuraEnabled
    public static void updateNotificationSetting(String fieldApiName, Object value){
        User user = new User(Id = UserInfo.getUserId());

        user.put(fieldApiName, value);
        
        try {
            update user;

            user = [SELECT Id, Daily_Digest_Summary__c, Last_Digest_Email_Sent__c FROM User WHERE Id =: UserInfo.getUserId()];
            Long minutes = 40;
            
            if(user.Last_Digest_Email_Sent__c != null) {
                minutes = ((Datetime.now().getTime() - user.Last_Digest_Email_Sent__c.getTime()) / 60000);
            }
            

            if(fieldApiName == 'Daily_Digest_Summary__c' && minutes > 30 && user.Daily_Digest_Summary__c) {
                MSD_CORE_Daily_Digest__c dailyDigest = new MSD_CORE_Daily_Digest__c(MSD_CORE_Payor__c = UserInfo.getUserId(),
                                                                                    MSD_CORE_Type__c = 'Confirmation');
                
                insert dailyDigest;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}