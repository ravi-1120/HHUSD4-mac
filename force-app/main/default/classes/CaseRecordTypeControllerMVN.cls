/*
 * CaseRecordTypeControllerMVN
 * Created By:      Roman Lerman
 * Created Date:    2/14/2012
 * Description:     This class returns the translated record type name of the class
 *                  to be displayed on the Case Record Type page.  It also determines
 *                  if the Request is an Adverse Event/PQC or Temperature Excursion in
 *                  order to display the appropriate disclaimer in the Case Record Type
 *                  page.  
 * Updated Date: 05/12/2021
 * Updated By: Vamshi Bashyakarla
 * Description: For CEF2F-8446 added a logic to ignore the IRRE Details Field Set
 * 				in the queryAERequiredFields method.
 */
public with sharing class CaseRecordTypeControllerMVN {
    public String caseId {get;set;}
    public String caseRecordTypeName {get;set;}
    public String recordTypeName{get; set;}
    public String recordTypeDeveloperName{get; set;}
    public Boolean isCOMBO{get; private set;}
    public Boolean isTempExcursion{get; private set;}
    public MSD_CORE_Service_Cloud_Tab_Settings__c scTabSettings{get; set;}
    
    public Case cs {get;set;}
    
    public CaseRecordTypeControllerMVN (ApexPages.StandardController controller){  
        cs = [select toLabel(RecordType.Name), RecordTypeId, Type, RecordType.DeveloperName from Case where Id = :controller.getRecord().Id];
        caseId = controller.getRecord().Id;
        recordTypeName = cs.RecordType.Name;
        recordTypeDeveloperName = cs.RecordType.DeveloperName;
        scTabSettings = MSD_CORE_Service_Cloud_Tab_Settings__c.getValues(cs.RecordType.DeveloperName);

        isCOMBO = false;
        isTempExcursion = false; 
        setDisclaimer(cs); 
        
        if(cs.RecordType.Name.contains('Product Complaint')) cs.Type = null;
    }
	//@testvisible 
	@testvisible 
    private void setDisclaimer(Case cs) { 
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        Set<String> aePQCRecordTypes = new Set<String>(); 
        Set<String> tempExcursionRecordTypes = new Set<String>();

        // Determine if the request is an Adverse Event or Product Quality Complaint
        // in order to show the AE/PQC Disclaimer
        //new line added here for combo
        aePQCRecordTypes.add(settings.Combo_Case_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Combo_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Combo_Submitted__c);
        aePQCRecordTypes.add(settings.Combo_Case_Preview_Record_Type__c);
        aePQCRecordTypes.add(settings.Adverse_Event_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.Product_Complaint_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Product_Comp_Submitted_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Adverse_Event_Submitted_RT__c);

        // Determine if the request is a Temperature Excursion in order to
        // show the Temperature Excursion Disclaimer
        tempExcursionRecordTypes.add(settings.MSD_CORE_Temp_Excursion_Record_Type__c);
        tempExcursionRecordTypes.add(settings.MSD_CORE_Temp_Exc_Closed_Record_Type__c);

        if(aePQCRecordTypes.contains(cs.RecordType.DeveloperName)) {
            isCOMBO = true; 
        } else if(tempExcursionRecordTypes.contains(cs.RecordType.DeveloperName)) {
            isTempExcursion = true; 
        } else {
            isCOMBO = false;
            isTempExcursion = false;
        }
    }
    
    /* Req # : USVEEV-R-0074
     * updateRecordType
     * Created By:      Prasanjeet sharma
     * Description:     This method will check and update the Case Record type and Event Case Type field based 
                        on the selection of AE Type picklist or Product complaint checkbox
     */
    public void updateRecordType()
    {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Id RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseRecordTypeName).getRecordTypeId();
        
        List<Case> caseList = [select id, RecordType.Name from Case where id =: caseId limit 1];
        
        if(caseList.size() > 0 && (caseList[0].RecordType.Name == 'Adverse Event' || caseList[0].RecordType.Name == 'Product Complaint')){
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Combo Case').getRecordTypeId();
            caseRecordTypeName = 'Combo Case';
        }
        
        Case newCase = new Case(id = caseId,
                                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseRecordTypeName).getRecordTypeId(),
                                MSD_CORE_Event_Case_Type__c = (caseRecordTypeName == 'Adverse Event' ? 'AE Only' : 
                                                     (caseRecordTypeName == 'Product Complaint' ? 'PQC Only' : 'AE and PQC')));
        
        update newCase;
    }
    
    /* Req # : USVEEV-R-0074
     * saveCase
     * Created By:      Prasanjeet sharma
     * Description:     This method will check and update the Case Record type and Event Case Type field based 
                        on the selection of AE Type picklist.
     */
    public void saveCase()
    {
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Adverse Event').getRecordTypeId();
        cs.MSD_CORE_Event_Case_Type__c = 'AE Only';
        
        List<Case> caseList = [select id, RecordType.Name, Type from Case where id =: caseId limit 1];
        
        if(caseList.size() > 0 && (caseList[0].RecordType.Name == 'Product Complaint' || caseList[0].RecordType.Name == 'Combo Case')){
            cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Combo Case').getRecordTypeId();
            cs.MSD_CORE_Event_Case_Type__c = 'AE and PQC';
        }
        
        update cs;
    }
    
    @AuraEnabled
    public static CaseDataWrapperMVN setDisclaimer(String csId) { 
       
        List<Case> caseList = [select id, RecordTypeId, RecordType.Name, MSD_CORE_Event_Case_Type__c,
                               RecordType.DeveloperName, Type, Status, MSD_CORE_Disclaimer_Read__c,
                               MSD_CORE_AE_Hospitalization_or_Prolonged__c, MSD_CORE_AE_Sig_Disability_or_Incapacity__c,
                               MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c,
                               MSD_CORE_AE_Is_Was_the_AE_Cancer__c,
                               MSD_CORE_AE_Patient_Overdose__c,
                               MSD_CORE_AE_Life_Threatening__c,
                               MSD_CORE_AE_Intervention_Prevent_Serious__c,
                               MSD_CORE_AE_Did_the_Patient_Die__c,
                               MSD_CORE_Is_Cloned__c,
                               MSD_CORE_Org_Case_Cloned__c
                               from Case where id =: csId];
        Case cs;
        
        if(caseList.size() > 0)
            cs = caseList[0];
        
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        Set<String> aePQCRecordTypes = new Set<String>(); 
        Set<String> tempExcursionRecordTypes = new Set<String>();

        // Determine if the request is an Adverse Event or Product Quality Complaint
        // in order to show the AE/PQC Disclaimer
        //new line added here for combo
        /*aePQCRecordTypes.add(settings.Combo_Case_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.Combo_Case_Preview_Record_Type__c);
        aePQCRecordTypes.add(settings.Adverse_Event_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.Product_Complaint_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Product_Comp_Submitted_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Adverse_Event_Submitted_RT__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Combo_Submitted__c);*/
        
        aePQCRecordTypes.add(settings.Combo_Case_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Combo_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Combo_Submitted__c);
        aePQCRecordTypes.add(settings.Combo_Case_Preview_Record_Type__c);
        aePQCRecordTypes.add(settings.Adverse_Event_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.Product_Complaint_Record_Type_MVN__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Product_Comp_Submitted_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c);
        aePQCRecordTypes.add(settings.MSD_CORE_Adverse_Event_Submitted_RT__c);
        

        // Determine if the request is a Temperature Excursion in order to
        // show the Temperature Excursion Disclaimer
        tempExcursionRecordTypes.add(settings.MSD_CORE_Temp_Excursion_Record_Type__c);
        tempExcursionRecordTypes.add(settings.MSD_CORE_Temp_Exc_Closed_Record_Type__c);
        
        boolean isAccess = Schema.getGlobalDescribe().get('Case').getDescribe().isUpdateable();
        
        if(aePQCRecordTypes.contains(cs.RecordType.DeveloperName) || aePQCRecordTypes.contains(cs.RecordType.DeveloperName)) {
            return new CaseDataWrapperMVN(cs, 'COMBO', isAccess); 
        } else if(tempExcursionRecordTypes.contains(cs.RecordType.DeveloperName)) {
            return new CaseDataWrapperMVN(cs, 'TempExcursion', isAccess); 
        } else {
            return new CaseDataWrapperMVN(cs, 'Other', isAccess);
        }
    }
    
    @AuraEnabled
    public static Case getAEFieldsData(String csId) { 
        Schema.DescribeSObjectResult r = Case.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            apiNames.add(apiName);
        }
        
        return database.query('select ' + String.join(apiNames, ',') + ', RecordType.Name from Case where id =: csId'); 
    }
    
    @AuraEnabled
    public static String markDisclaimerRead(String csId) { 
        List<Case> caseList = [select id, MSD_CORE_Disclaimer_Read__c from Case where id =: csId];
        
        if(caseList.size() > 0)
        {
            caseList[0].MSD_CORE_Disclaimer_Read__c = true;
            
            try
            {
                update caseList;
                
                return 'Success';
            }
            catch(Exception ex)
            {
                return 'Error: ' + ex.getMessage();
            }
        }
        
        return 'Success';
    }
    
    
    @AuraEnabled
    public static String saveCase(String csId, String csType) { 
        List<Case> caseList = [select id, Interaction_Notes_MVN__c, Parent.Interaction_Notes_MVN__c, MSD_CORE_AE_Description__c, RecordTypeId, RecordType.Name, MSD_CORE_Event_Case_Type__c,
                               RecordType.DeveloperName, Type, Status, MSD_CORE_Disclaimer_Read__c 
                               from Case where id =: csId];
        Case cs;
        
        if(caseList.size() > 0)
        {
            cs = caseList[0];               
            cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Adverse Event').getRecordTypeId();
            cs.MSD_CORE_Event_Case_Type__c = 'AE Only';            
            cs.Type = csType;
            
            if(caseList[0].RecordType.Name == 'Product Complaint' || caseList[0].RecordType.Name == 'Combo Case'){
                cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Combo Case').getRecordTypeId();
                cs.MSD_CORE_Event_Case_Type__c = 'AE and PQC';
            }
            /*
            if(cs.MSD_CORE_AE_Description__c == null)
                cs.MSD_CORE_AE_Description__c = caseList[0].Parent.Interaction_Notes_MVN__c;
            */
            
            
            try
            {
                System.debug('cs -->'+cs);
                update cs;
                return 'Success';
            }
            catch(Exception ex)
            {
                return 'Error: ' + ex.getMessage();
            }
        }
        
        return 'Success';
    }
    
    @AuraEnabled
    public static String updateRecordType(String csId)
    {
        String caseRecordTypeName = 'Product Complaint';
        
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Id RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseRecordTypeName).getRecordTypeId();
        
        List<Case> caseList = [select id, RecordType.Name, MSD_CORE_AE_Description__c, Parent.Interaction_Notes_MVN__c from Case where id =: csId limit 1];
        
        if(caseList.size() > 0 && (caseList[0].RecordType.Name == 'Adverse Event' || caseList[0].RecordType.Name == 'Product Complaint')){
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Combo Case').getRecordTypeId();
            caseRecordTypeName = 'Combo Case';
        }
        System.debug('caseRecordTypeName -->'+caseRecordTypeName);
        Case newCase = new Case(id = csId, 
                                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseRecordTypeName).getRecordTypeId(),
                                MSD_CORE_Event_Case_Type__c = (caseRecordTypeName == 'Adverse Event' ? 'AE Only' : 
                                                     (caseRecordTypeName == 'Product Complaint' ? 'PQC Only' : 'AE and PQC')));
        /*
        if(newCase.MSD_CORE_AE_Description__c == null)
            newCase.MSD_CORE_AE_Description__c = caseList[0].Parent.Interaction_Notes_MVN__c;
        */
        if(caseList[0].RecordType.Name == 'Adverse Event'){
            newCase.MSD_CORE_AE_Description__c = caseList[0].MSD_CORE_AE_Description__c;
        }
        
        try
        {
            System.debug('newCase -->'+newCase);
            update newCase;
            
            return 'Success';
        }
        catch(Exception ex)
        {
            return 'Error: ' + ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static List<CaseAERequiredFieldWrapper> queryAERequiredFields(String csId)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Case');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Map<String,Schema.FieldSet> fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap();
        
        List<CaseAERequiredFieldWrapper> fieldWrapperList = new List<CaseAERequiredFieldWrapper>();
        
        Schema.DescribeSObjectResult r = Case.sObjectType.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : r.fields.getMap().keySet()){
            System.debug('KRB1: ' + apiName);
            apiNames.add(apiName);
        }
        
        List<Case> caseList = database.query('select ' + String.join(apiNames, ',') + ', RecordType.Name from Case where id =: csId'); 
        
        String typContains = 'MSD_CORE_AE_RF_';
        
        if(caseList[0].RecordType.Name == 'Product Complaint')
            typContains = 'PQC_RF_';
        if(caseList[0].RecordType.Name == 'Combo Case')
            typContains = 'MSD_CORE_COMBO_RF_';
        
        String IRRE_DETAILS = typContains+'IRRE_DETAILS'; //CEF2F-8446
        if(caseList.size() > 0)
        {
            Case cs = caseList[0];
            
            for(String key : fieldSetObj.keyset())
            {
                if(key.toUpperCase().contains(typContains) && !key.toUpperCase().contains(IRRE_DETAILS)) //CEF2F-8446
                {
                    Schema.FieldSet s = fieldSetObj.get(key);
                    
                    List<FieldWrapper> fieldList = new List<FieldWrapper>();
                    
                    for(Schema.FieldSetMember fieldSetMemberObj : s.getFields())
                    {
                        if(checkFieldValueNull(cs, fieldSetMemberObj.getFieldPath()))
                        {
                            fieldList.add(new FieldWrapper(fieldSetMemberObj.getFieldPath(),
                                                           fieldSetMemberObj.getLabel(),
                                                           fieldSetMemberObj.getRequired(),
                                                           fieldSetMemberObj.getDbRequired(),
                                                           fieldSetMemberObj.getType()+''));
                        }
                    }
                    
                    if(fieldList.size() > 0)
                        fieldWrapperList.add(new CaseAERequiredFieldWrapper(key.toUpperCase().replace(typContains, '').replace('_', ' '), fieldList));
                }
            }
        }
        
        return fieldWrapperList;
    }
    
    
    public static List<Schema.FieldSetMember> readFieldSet(Schema.DescribeSObjectResult DescribeSObjectResultObj, String fieldSetName, String ObjectName)
    {
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        return fieldSetObj.getFields(); 
    }  
    
    
    public class CaseAERequiredFieldWrapper
    {
        @AuraEnabled public String sectionName {get;set;}
        @AuraEnabled public List<FieldWrapper> fieldList {get;set;}
        
        public CaseAERequiredFieldWrapper(String sectionName, List<FieldWrapper> fieldList)
        {
            this.sectionName = sectionName;
            this.fieldList = fieldList;
        }
    }
    
    
    public static boolean checkFieldValueNull(sObject o, String fieldName)
    {
        return o.get(fieldName) == null ? true : false;
    }
    
    
    public class FieldWrapper
    {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public boolean isRequired;
        @AuraEnabled public boolean isDBRequired;
        @AuraEnabled public String type;
        
        public FieldWrapper(String fieldName,
                            String fieldLabel,
                            boolean isRequired,
                            boolean isDBRequired,
                            String type)
        {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isRequired = isRequired;
            this.isDBRequired = isDBRequired;
            this.type = type;
        }
    }
    
    
    @AuraEnabled
    public static boolean checkUserAccess()
    {
        return Schema.getGlobalDescribe().get('Case').getDescribe().isUpdateable();

    }
    
    @AuraEnabled
    public static User getUserData()
    {
        return [select id, Name, ProfileId, Profile.Name from User where id =: UserInfo.getUserId()];
    }
    
    @AuraEnabled
    public static InteractionWrapper getCaseInfo(String csId){
        InteractionWrapper wrap = new InteractionWrapper();
        wrap.userProfile = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;
        wrap.caseStatus = [SELECT Status FROM Case WHERE Id = :csId].Status;        
        return wrap;
    }
    
     public class InteractionWrapper{
        @AuraEnabled
        public String userProfile;
         @AuraEnabled
        public String caseStatus;
    }
}