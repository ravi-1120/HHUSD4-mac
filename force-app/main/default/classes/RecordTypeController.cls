public class RecordTypeController {
/*@AuraEnabled
    public static List<Case> getRequestRecordType(Id recordId) {
       List<Case> recordTypeId = [select recordtypeid from case where id =:recordId];
       return recordTypeId;
        
    }*/
    
    @AuraEnabled
    public static List<Case> getCaseRecord(Id recordId) {
       List<Case> caseRecord = [select Origin,Customer_Type_MVN__c,MSD_CORE_Do_Not_Survey__c,MSD_CORE_Source__c,MSD_CORE_Legal_Alert_Present__c,
                                MSD_CORE_AE_Present__c,MSD_CORE_Campaign__c,MSD_CORE_Preferred_Language__c,
                                MSD_CORE_CR_Present__c,MSD_CORE_Notes__c,
                                case_AddressLine1_MVN__c,case_AddressLine2_MVN__c,case_City_MVN__c,case_State_MVN__c,case_Postal_Code_MVN__c,
                                case_Country_MVN__c,case_Account_Email_MVN__c,case_Account_Phone_MVN__c,case_Account_Fax_MVN__c,MSD_CORE_Customer_Email__c,
                                MSD_CORE_Customer_Contact_Email__c,MSD_CORE_Referred_By_Email__c,Referred_By_MVN__c,MSD_CORE_Business__c,
                                Address_MVN__c,isEmailRequest_MVN__c,ClosedDate,
                                MSD_CORE_AE_Description__c,MSD_CORE_Source_Code__c from case where id =:recordId];
       return caseRecord;
        
    }
    
    @AuraEnabled
    public static void updateCaseDesc(String caseId, String descVal){
        
        Case caseRec = [SELECT ID, Status, RecordType.DeveloperName, 
                        Interaction_Notes_MVN__c, MSD_CORE_Request_Description__c, 
                        MSD_CORE_AE_Description__c, Details_MVN__c 
                        from Case 
                        where Id =: caseId];
        
        if(caseRec.Status == 'Open')
        {
            String recType = caseRec.RecordType.DeveloperName;
            System.debug('recType'+recType);
            if(recType == 'Interaction_MVN'){
                caseRec.Interaction_Notes_MVN__c  = descVal;
            }
            if(recType == 'Request_MVN'){
                //caseRec.MSD_CORE_Request_Description__c = descVal;
                caseRec.Details_MVN__c = descVal;
            }
            if(recType == 'Combo_Case_MVN' || recType == 'Adverse_Event_MVN'|| recType == 'Product_Complaint_MVN'|| recType == 'Combo_Case_Preview'){
                caseRec.MSD_CORE_AE_Description__c = descVal;
            }
            if(recType == 'MSD_CORE_Temperature_Excursion' || recType == 'MSD_CORE_Compensation_Request' ){
                caseRec.Details_MVN__c = descVal;
            }
            
            update caseRec;     
        }
    }
    
   @AuraEnabled
   public static Boolean readOnlyCheck(){
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            return true;
        }
        else{
            return false;
        }
    }
    
	@AuraEnabled
  	public static DescWrapper getDescInfo(){
       DescWrapper wrap = new DescWrapper();
        wrap.hideDSCheckbox = false;
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            wrap.isReadOnly = true;
            wrap.hideDSCheckbox = true;
        }
        else{
            wrap.isSearchDisabled = false;
        }
        if(profileName.contains('MVCC Agent')){
            wrap.hideDSCheckbox = true;
        }
        List<MSD_CORE_CC_ArticleSearchSetting__mdt> articleSettings = [SELECT MSD_CORE_CC_Enable_Auto_Search__c, MSD_CORE_CC_Delay_in_Millis__c, MSD_CORE_CC_Limit_Flag__c, MSD_CORE_CC_Limit_Words__c FROM MSD_CORE_CC_ArticleSearchSetting__mdt LIMIT 1];
        if(articleSettings[0].MSD_CORE_CC_Enable_Auto_Search__c)
        {
            wrap.isSearchDisabled = false;
        }
        else{
            wrap.isSearchDisabled = true;
        }        
        return wrap;
    }    
	
    public class DescWrapper{
        @AuraEnabled
        public boolean isReadOnly;
        @AuraEnabled
        public boolean isSearchDisabled;
        @AuraEnabled
        public boolean hideDSCheckbox;
    }
}