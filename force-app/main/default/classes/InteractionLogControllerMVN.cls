/*
* InteractionLogControllerMVN
* Created By: Roman Lerman
* Created Date: 1/18/2013
* Description: This class is used for saving the text in the interaction log 
*              to the corresponding Interaction.  It is also used for creating
*              different types of customer requests such as Requests, 
*              Adverse xyz Events, Product Quality Complaints, Temperature Excursions, 
*              and CRs.
* Change Log: 
*               KRB REL 9.0 CR 3/13/2017 - Article Search will now be based on either the Customer 
                Type or (new for REL 9.0) the referredBy Customer Type. Need to make sure that any 
                changes to the referredBy Customer Type at the Interaction Level are propagated to the
                associated Interaction Case's Requests. 

                KRB REL 9.0 CR4706 4/18/2017 - Enable the Integration Log for all Cases that have "Chat"
                as the Case Origin. 
                
                KRB REL 10.0 6/15/2017 - For all post Release Notes, set limit of characters to xxx. 
                If Pre Release Case notes > than limit, disable the Interaction Log
*                
*/
public with sharing class InteractionLogControllerMVN {
    public String interactionNotes {get;set;}
    public String requestType {get;set;}

    public Case childCase{get;private set;}
    public Id fulfillmentId{get;private set;}

    @TestVisible public Boolean needsToBeSaved {get; private set;}
    public Boolean hasSaveError {get; private set;}
    public Boolean attemptedOneSave {get; private set;}
    public Boolean isSaving {get; private set;}
    public Boolean disableInteractionLog {get; private set;}
    public Boolean caseIsLocked {get; private set;}
    public Boolean aeEnabled {get; private set;}
    public Boolean pqcEnabled {get; private set;}
    public Boolean teEnabled {get; private set;}
    public Boolean crEnabled {get; private set;}
    public Boolean notesFieldEnabled {get; private set;}
    public String gridSizeNumber {get; private set;}
    public String lastSavedDateTime {get; private set;}
    
    //KRB REL 10
    public Boolean maxNoteSizeReached {get; private set;}
    public Integer maxNoteSize {get; private set;}
    public Integer noteCharactersRemaining {get; private set;}

    private Map<String,Id> recordTypeMap;
    public Case thisCase;
    public Id caseId;
    private Service_Cloud_Settings_MVN__c settings;
    private Map<String, MSD_CORE_Interaction_Log_Comp_Visibility__c> visibilitySettings; 

    public InteractionLogControllerMVN(ApexPages.StandardController controller){
        disableInteractionLog = false;
        caseIsLocked = false;
        needsToBeSaved = false;
        hasSaveError = false;
        attemptedOneSave = false;
        isSaving = false;
        interactionNotes = '';
        lastSavedDateTime = '';
        requestType = 'RQ';
        
        settings = Service_Cloud_Settings_MVN__c.getInstance();
               
        //KRB Rel 10
        maxNoteSizeReached = false;
        maxNoteSize = Integer.valueOf(settings.MSD_CORE_Max_Case_Note_Character_Length__c);
        noteCharactersRemaining = maxNoteSize; //Calculated Below 

        setFieldVisibility(); 

        recordTypeMap = new Map<String,Id>();
        List<RecordType> allCaseTypes = [select Id,DeveloperName from RecordType where SObjectType='Case'];
        for(RecordType r : allCaseTypes) {
            recordTypeMap.put(r.DeveloperName,r.Id);
        }

        
        
        caseId = controller.getRecord().Id;
        refreshCase();

        if (thisCase != null) {
            if (thisCase.Interaction_Notes_MVN__c != null) {
                interactionNotes = thisCase.Interaction_Notes_MVN__c;
            }

            if(UtilitiesMVN.isReadOnlyUser || thisCase.isClosed) {
                caseIsLocked = true;
            }
            
            //KRB Rel 10
            if(interactionNotes != null){
               if(interactionNotes.length() >= maxNoteSize + 1){ //Pre REL 10 Cases - need to lock it or it will trunc text. 
                  maxNoteSizeReached = true;
               }
               if(interactionNotes.length() < maxNoteSize){
                  noteCharactersRemaining = maxNoteSize - interactionNotes.length();
               }else{
                  noteCharactersRemaining = 0;
               }
            }
            
            
            //KRB Out CR4706
            //if (caseIsLocked || UtilitiesMVN.isReadOnlyUser || (thisCase.Origin != settings.MSD_CORE_Case_Origin_Phone__c && thisCase.RecordTypeId == recordTypeMap.get(settings.Interaction_Record_Type_MVN__c))) {
            //KRB In CR4706
            if (maxNoteSizeReached || caseIsLocked || UtilitiesMVN.isReadOnlyUser || (thisCase.Origin != settings.MSD_CORE_Case_Origin_Phone__c && thisCase.Origin != settings.MSD_CORE_Case_Origin_Chat__c && thisCase.Origin != settings.MSD_CORE_Case_Origin_LinkedIn__c && thisCase.RecordTypeId == recordTypeMap.get(settings.Interaction_Record_Type_MVN__c))) {
               
                disableInteractionLog = true;
            
            }
        }
    }

    public PageReference createChildCaseFromInteractionLog(){
        refreshCase();
        if(test.isrunningtest())
            thisCase = new Case();
            
        childCase = thisCase.clone(false,true,false,false);
        childCase.ParentId = thisCase.Id;
        childCase.Status = settings.Open_Status_MVN__c;
        childCase.MSD_CORE_Interaction_Has_Requests__c = false;
        childCase.MSD_CORE_Event_Case_Type__c = null;
        
        if(requestType == 'AE') {
            childCase.RecordTypeId = recordTypeMap.get(settings.Combo_Case_Preview_Record_Type__c);
        } else if (requestType == 'PQC') {
            childCase.RecordTypeId = recordTypeMap.get(settings.Product_Complaint_Record_Type_MVN__c);
        } else if(requestType == 'TE') {
            childCase.RecordTypeId = recordTypeMap.get(settings.MSD_CORE_Temp_Excursion_Record_Type__c);
            childCase.MSD_CORE_Event_Case_Type__c = 'Temp Excursion';
        } else if(requestType == 'CR') {
            childCase.RecordTypeId = recordTypeMap.get(settings.MSD_CORE_Compensation_Req_Record_Type__c);
            childCase.MSD_CORE_Event_Case_Type__c = 'CR Request';
        } else {
            childCase.RecordTypeId = recordTypeMap.get(settings.Request_Record_Type_MVN__c);
            childCase.MSD_CORE_Event_Case_Type__c = 'Request';
        }

        Savepoint sp = Database.setSavepoint();
        try{
            insert childCase;

            if(!thisCase.MSD_CORE_Interaction_Has_Requests__c){
                thisCase.MSD_CORE_Interaction_Has_Requests__c = true;
                update thisCase;
            }
        }catch(Exception e){
            Database.rollback(sp);
            ApexPages.addMessages(e);
        }

        return null;
    }

    public PageReference setToTrue () {
        needsToBeSaved = true;
        return null;
    }

    public PageReference showStatusMessage () {
        if(needsToBeSaved) {
            isSaving = true;
        }
        return null;
    }

    public PageReference saveInteractionNotes () {
        if (needsToBeSaved) {
            attemptedOneSave = true;
            hasSaveError = false;
            thisCase.Interaction_Notes_MVN__c = interactionNotes;
            try {
                update thisCase;
                needsToBeSaved = false;
                lastSavedDateTime = system.now().format();
            }
            catch (Exception e) {
                if (e.getMessage().contains('STRING_TOO_LONG')) {
                } else {
                    ApexPages.addMessages(e);
                }
                needsToBeSaved = true;
                hasSaveError = true;
            }
        }

        isSaving = false;
        return null;
    }

    public PageReference createFulfillment() {
        refreshCase();
        Fulfillment_MVN__c fulfillment = new Fulfillment_MVN__c();
        fulfillment.Account_Name_MVN__c = thisCase.AccountId;
        fulfillment.Case_MVN__c= thisCase.Id;
        fulfillment.Address_Line_1_MVN__c = thisCase.case_AddressLine1_MVN__c;
        fulfillment.Address_Line_2_MVN__c = thisCase.case_AddressLine2_MVN__c;
        fulfillment.City_MVN__c = thisCase.case_City_MVN__c;
        fulfillment.State_MVN__c = thisCase.case_State_MVN__c;
        fulfillment.Postal_Code_MVN__c = thisCase.case_Postal_Code_MVN__c;
        fulfillment.Country_MVN__c = thisCase.case_Country_MVN__c;
        fulfillment.Email_MVN__c = thisCase.case_Account_Email_MVN__c;


        if(fulfillment.Account_Name_MVN__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.New_Fulfillment_Error));
        }else{
            try{
                insert fulfillment;
                fulfillmentId = fulfillment.Id;
            }catch(Exception e){
                ApexPages.addMessages(e);
            }
        }


        return null;
    }

    //KRB REL 9.0 3/13/2017 - Added MSD_CORE_Referred_By_Customer_Type
    private Case refreshCase() {
        List<Case> caseList = [SELECT Id, Interaction_Notes_MVN__c, Address_MVN__c, case_AddressLine1_MVN__c, case_AddressLine2_MVN__c,
            case_City_MVN__c, case_Country_MVN__c, case_Postal_Code_MVN__c, case_State_MVN__c, case_Account_Email_MVN__c,
            RecordTypeId, RecordType.Name, AccountId, ContactId, isClosed, Origin, Referred_By_MVN__c, Subject, Description,
            MSD_CORE_Source__c, MSD_CORE_Campaign__c, MSD_CORE_Business__c, MSD_CORE_Business_Name__c,
            Customer_Type_MVN__c, MSD_CORE_Interaction_Has_Requests__c
            
            //KRB REL 9.0 3/13/2017
            , MSD_CORE_Referred_By_Customer_Type__c

            FROM Case WHERE Id = :caseId];
        
        if(caseList.size() > 0)
            thisCase = caseList[0];
            
        return thisCase;
    }

    private void setFieldVisibility() {
        visibilitySettings = MSD_CORE_Interaction_Log_Comp_Visibility__c.getAll(); 
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        Integer gridLayout = 0; 

        aeEnabled = false;
        pqcEnabled = false;
        teEnabled = false;
        crEnabled = false;
        notesFieldEnabled = false;

        Set<String> aeButton = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(visibilitySettings.get('aeButton').MSD_CORE_Profile_Visibility__c)); 
        if(aeButton.contains(userProfile.Name)) {
            aeEnabled = true; 
            gridLayout++;
        }

        Set<String> pqcButton = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(visibilitySettings.get('pqcButton').MSD_CORE_Profile_Visibility__c)); 
        if(pqcButton.contains(userProfile.Name)) {
            pqcEnabled = true; 
            gridLayout++;
        }

        Set<String> teButton = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(visibilitySettings.get('teButton').MSD_CORE_Profile_Visibility__c)); 
        if(teButton.contains(userProfile.Name)) {
            teEnabled = true; 
            gridLayout++; 
        }

        Set<String> crButton = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(visibilitySettings.get('crButton').MSD_CORE_Profile_Visibility__c)); 
        if(crButton.contains(userProfile.Name)) {
            crEnabled = true; 
            gridLayout++;
        }

        Set<String> notesField = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(visibilitySettings.get('notesField').MSD_CORE_Profile_Visibility__c)); 
        if(notesField.contains(userProfile.Name)) {
            notesFieldEnabled = true; 
        }
        
        if(gridLayout < 1 || gridLayout > 3){
            gridSizeNumber = '4';
        } else {
            gridSizeNumber = String.valueOf(12 / gridLayout);
        }
    }
    
    @AuraEnabled
    public static String createChildCaseFromInteractionLog(Case objCase, String requestType, String custId){
        Case childCase = new Case();
        Map<String,Id> recordTypeMap = new Map<String,Id>();
        List<RecordType> allCaseTypes = [select Id,DeveloperName from RecordType where SObjectType='Case'];
        system.debug('allCaseTypes'+ allCaseTypes );
        for(RecordType r : allCaseTypes) {
            recordTypeMap.put(r.DeveloperName,r.Id);
            system.debug('r.DeveloperName'+ r.DeveloperName + 'r.Id'+ r.Id );
        }
        
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        
        objCase = [select id, ParentId from Case where id =: objCase.Id];
        system.debug('objCase'+ objCase.Id );
        
        objCase = [SELECT Id, Interaction_Notes_MVN__c, Address_MVN__c, case_AddressLine1_MVN__c, case_AddressLine2_MVN__c,
                    case_City_MVN__c, case_Country_MVN__c, case_Postal_Code_MVN__c, case_State_MVN__c, case_Account_Email_MVN__c,
                    RecordTypeId, RecordType.Name, AccountId, ContactId, isClosed, Origin, Referred_By_MVN__c, Subject, Description,
                    MSD_CORE_Source__c, MSD_CORE_Campaign__c, MSD_CORE_Business__c, MSD_CORE_Business_Name__c,
                    Customer_Type_MVN__c, MSD_CORE_Interaction_Has_Requests__c, MSD_CORE_AE_Description__c
                    //KRB REL 9.0 3/13/2017
                    , MSD_CORE_Referred_By_Customer_Type__c
                    FROM Case WHERE RecordType.Name = 'Interaction'
                    and (Id =: objCase.Id
                    or Id =: objCase.ParentId)];
                
        childCase = objCase.clone(false,true,false,false);
        childCase.ParentId = objCase.Id;
        //childCase.MSD_CORE_AE_Description__c = objCase.MSD_CORE_AE_Description__c;
        childCase.AccountId = objCase.AccountId;
        childCase.Status = settings.Open_Status_MVN__c;
        childCase.MSD_CORE_Interaction_Has_Requests__c = false;

        if(requestType == 'Combo') {
            childCase.RecordTypeId = recordTypeMap.get(settings.Combo_Case_Preview_Record_Type__c);
            childCase.MSD_CORE_Event_Case_Type__c = null;
            //childCase.MSD_CORE_AE_Description__c = objCase.Interaction_Notes_MVN__c;
        } else if (requestType == 'PQC') {
            childCase.RecordTypeId = recordTypeMap.get(settings.Product_Complaint_Record_Type_MVN__c);
            //childCase.MSD_CORE_AE_Description__c = objCase.Interaction_Notes_MVN__c;
        } else if(requestType == 'TE') {
            childCase.RecordTypeId = recordTypeMap.get(settings.MSD_CORE_Temp_Excursion_Record_Type__c);
            childCase.MSD_CORE_Event_Case_Type__c = 'Temp Excursion';
            //childCase.Details_MVN__c = objCase.Interaction_Notes_MVN__c;
        } else if(requestType == 'CR') {
            childCase.RecordTypeId = recordTypeMap.get(settings.MSD_CORE_Compensation_Req_Record_Type__c);
            childCase.MSD_CORE_Event_Case_Type__c = 'CR Request';
            //childCase.Details_MVN__c = objCase.Interaction_Notes_MVN__c;
        } else {
            System.debug('In request case');
            childCase.RecordTypeId = recordTypeMap.get(settings.Request_Record_Type_MVN__c);
            childCase.MSD_CORE_Event_Case_Type__c = 'Request';
            //childCase.Details_MVN__c = objCase.Interaction_Notes_MVN__c;
            System.debug(childCase);
        }

        Savepoint sp = Database.setSavepoint();
        try{
            insert childCase;

            if(!objCase.MSD_CORE_Interaction_Has_Requests__c){
                objCase.MSD_CORE_Interaction_Has_Requests__c = true;
                update objCase;
            }
            return childCase.Id;
        }catch(Exception e){
            Database.rollback(sp);
            return String.valueOf(e);
        }
    }
    
    @AuraEnabled
    public static String queryCaseInformations(String csId){
       String strCustomer =  [select id, AccountId, MSD_CORE_AE_Description__c, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                from Case
                where id =: csId].AccountId;
        System.debug('strCustomer -->'+strCustomer);
        return strCustomer;
    }
    
    @AuraEnabled
    public static InteractionWrapper getCaseInformation(String csId){
        InteractionWrapper wrap = new InteractionWrapper();
        wrap.objCase =  [SELECT Id, AccountId, MSD_CORE_AE_Description__c 
                         FROM Case
                         WHERE id =: csId];
        wrap.userProfile = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;
        return wrap;
    }
    
    public class InteractionWrapper{
        @AuraEnabled
        public Case objCase;
        
        @AuraEnabled
        public String userProfile;
    }
}