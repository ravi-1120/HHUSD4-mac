public with sharing class EmailActivityTriggerHandler extends VeevaTriggerHandler{
    private List<Email_Activity_vod__c> newRecords = new List<Email_Activity_vod__c>();
    private List<Email_Activity_vod__c> oldRecords = new List<Email_Activity_vod__c>();
    private Map<Id, Email_Activity_vod__c> newRecordsMap = new Map<Id, Email_Activity_vod__c>();
    private Map<Id, Email_Activity_vod__c> oldRecordsMap = new Map<Id, Email_Activity_vod__c>();
   
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newRecords = (List<Email_Activity_vod__c>) triggerNew;
        this.oldRecords = (List<Email_Activity_vod__c>) triggerOld;
        this.newRecordsMap = (Map<Id, Email_Activity_vod__c>) triggerNewMap;
        this.oldRecordsMap = (Map<Id, Email_Activity_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'Email_Activity_vod__c';
    }
    
    protected override void afterInsert() {
        handleInsert();
    }
    
    private void handleInsert(){
        RecordType[] recordTypes = [Select Id, DeveloperName from RecordType where SobjectType = 'Multichannel_Consent_vod__c' and DeveloperName='Approved_Email_vod'];
    	if(recordTypes.size() == 0){
        	return;
    	}
    	Id AERecordTypeID = recordTypes[0].Id;
    	Set<Id> sentEmailIds = new Set<Id>();
    	for(Email_Activity_vod__c activity: newRecords){
        	sentEmailIds.add(activity.Sent_Email_vod__c);
    	}
        
    	Map<Id,Sent_Email_vod__c> sentEmailMap = new Map<Id,Sent_Email_vod__c>([SELECT Id, Account_email_vod__c, Account_vod__c, Last_Activity_Date_vod__c, Status_vod__c, Email_Sent_Date_vod__c, Detail_Group_vod__c, Product_vod__c, Content_Type_vod__c, Content_Type_vod__r.Name, Content_Type_vod__r.External_Id_vod__c, CreatedDate, Email_Source_vod__c, Email_Config_Values_vod__c FROM Sent_Email_vod__c WHERE Id In :sentEmailIds ]);
    	List<Multichannel_Consent_vod__c> newConsents = new List<Multichannel_Consent_vod__c>();
        List<Email_Activity_vod__c> emailActivitiesBouncedOrDropped = new List<Email_Activity_vod__c>();
        List<Id> accountIdsBouncedOrDropped = new List<Id>();
        List<String> emailAddressesBouncedOrDropped = new List<String>();
        String recordTypeId = Id.valueOf(Schema.SObjectType.Channel_Metrics_vod__c.getRecordTypeInfosByDeveloperName().get('Email_vod').getRecordTypeId());
        for(Email_Activity_vod__c activity: newRecords){
        	Sent_Email_vod__c email = sentEmailMap.get(activity.Sent_Email_vod__c);
        	// only update last activity date in SE if this EA's activity datetime is later than the email's last activity date
        	if(email.Last_Activity_Date_vod__c == null || activity.Activity_DateTime_vod__c > email.Last_Activity_Date_vod__c) {
            	email.Last_Activity_Date_vod__c = activity.Activity_DateTime_vod__c;
        	}
        	String status = activity.Event_type_vod__c;
        	// determine the consent level (if available)
        	String consentLevel = '';
        	String actDetail = activity.Event_Msg_vod__c;
        	           
            if(actDetail != null) {
            	String[] actDetailVal = actDetail.split('::');
            	if(actDetailVal.size() == 2 && actDetailVal[0] == 'Consent_Level') {
                	consentLevel = actDetailVal[1];
            	}
        	}
            
            configureSentEmailFields(status, email, activity);
        	handleIfPreferencesModified(status, email, activity, consentLevel);
                       
            if(status == 'Bounced_vod' || status == 'Dropped_vod'){
                emailActivitiesBouncedOrDropped.add(activity);
                accountIdsBouncedOrDropped.add(email.Account_vod__c);
                emailAddressesBouncedOrDropped.add(email.Account_Email_vod__c);
            }
   
        	handleUnsubscribedStatus(status, email, activity, newConsents, consentLevel, AERecordTypeID);
    	}
    	update sentEmailMap.values();
    	insert newConsents;
        
        handleUpsertChannelMetrics(emailActivitiesBouncedOrDropped, sentEmailMap, accountIdsBouncedOrDropped, emailAddressesBouncedOrDropped);
    }
    
    private void configureSentEmailFields(String status, Sent_Email_vod__c email, Email_Activity_vod__c activity){
        // Sets the Sent Email Status and Sent Email Sent date 
        if(status == 'Unsubscribed_All_vod'){
            email.Status_vod__c = 'Unsubscribed_vod';
        }
        else if(status != 'Clicked_vod' && status != 'Opened_vod' && status != 'Viewed_vod' && status != 'Downloaded_vod' && status != 'Preferences_Modified_vod'){
            email.Status_vod__c = status ;
        }
        //if sent date is null, populate with appropriate date time
        if(email.Email_Sent_Date_vod__c == null){
            if(status == 'Delivered_vod') {
                email.Email_Sent_Date_vod__c = activity.Activity_DateTime_vod__c;
            }
            else if(status == 'Bounced_vod' || status == 'Dropped_vod') {
                email.Email_Sent_Date_vod__c = email.CreatedDate;
            }
        }
    }
    
    private void handleIfPreferencesModified(String status, Sent_Email_vod__c email, Email_Activity_vod__c activity, String consentLevel){
        if(status == 'Preferences_Modified_vod'){
            String modPrefs = activity.Preference_Modification_vod__c;
            if(consentLevel == 'Content_Type_vod') {
                // content type level consent
                String emailCtName = email.Content_Type_vod__r.Name;
                String emailCtExtId = email.Content_Type_vod__r.External_Id_vod__c;
                if(modPrefs != null) {
                    String[] optChanges = modPrefs.split(';;');
                    for(String optChange : optChanges) {
                        String[] vals = optChange.split('::');
                        if(vals.size() == 3) {
                            String name = vals[0];
                            String extId = vals[1];
                            String optType = vals[2];
                            if(name == emailCtName && extId == emailCtExtId && optType == 'OptOut') {
                                email.Status_vod__c = 'Unsubscribed_vod';
                            }
                        }
                    }
                }
            }
            else{
                // null or product level consent, execute existing behavior
                String emailGroupId = email.Detail_Group_vod__c;
                String emailProductId = email.Product_vod__c ;
                String emailCompoundKey = emailGroupId  == null ? emailProductId : emailProductId  +'|'+ emailGroupId ;
                if(modPrefs != null){
                    String[] optChanges = modPrefs.split(';;');
                    for(String optChange : optChanges){
                        String[] vals = optChange.split('::');
                        if(vals.size() == 3){
                            String compoundKey = vals[1];
                            String optType = vals[2];
                            if(compoundKey == emailCompoundKey && optType == 'OptOut'){
                                email.Status_vod__c = 'Unsubscribed_vod';	
                            }
                        }
                    }
                }
            }
        }
    }
    
    private void handleUnsubscribedStatus(String status,Sent_Email_vod__c email,Email_Activity_vod__c activity, List<Multichannel_Consent_vod__c> newConsents, 
                                         String consentLevel, Id AERecordTypeID){
        // Creates MC Consent Record if the Email Activity Status is Unsubcribed                                     
        if(status == 'Unsubscribed_vod' || status == 'Unsubscribed_All_vod'){
            Multichannel_Consent_vod__c newConsent = new Multichannel_Consent_vod__c();
            newConsent.Account_vod__c = email.Account_vod__c;
            newConsent.Capture_Datetime_vod__c = activity.Activity_DateTime_vod__c;
            newConsent.Channel_Value_vod__c = email.Account_email_vod__c;
            if(status == 'Unsubscribed_All_vod'){
                newConsent.Optout_Event_Type_vod__c= 'Unsubscribed_vod';
            }
            else{
                newConsent.Optout_Event_Type_vod__c= status;
            }
            newConsent.Opt_Type_vod__c= 'Opt_Out_vod';
            if(status == 'Unsubscribed_vod'){
                if(consentLevel == 'Content_Type_vod') {
                    	newConsent.Content_Type_vod__c = email.Content_Type_vod__c;
                }
                else {
                    newConsent.Product_vod__c= email.Product_vod__c;
                    newConsent.Detail_Group_vod__c= email.Detail_Group_vod__c;
                }
            }
            newConsent.RecordTypeId = AERecordTypeID;    
            newConsents.add(newConsent);
        }
    }
    
    @TestVisible
    private static boolean isTestMode(Sent_Email_vod__c email){
        if(email.Email_Config_Values_vod__c != null){
            if(email.Email_Config_Values_vod__c.contains('"test_mode":"true"')){
                return true;
            }
            else if(email.Email_Source_vod__c != null){
                if(email.Email_Source_vod__c.equals('Approved_Email_Settings_vod__c.APPROVED_EMAIL_TEST_ADDRESS_vod__c') || email.Email_Source_vod__c.equals('User.Email')){
                    return true;
                }
            }
        }
        return false;        
    }
    
    private void handleUpsertChannelMetrics(List<Email_Activity_vod__c> emailActivitiesBouncedOrDropped, Map<Id,Sent_Email_vod__c> sentEmailMap, List<Id> accountIdsBouncedOrDropped,List<String> emailAddressesBouncedOrDropped ){
          
        // Creates a Channel Metrics record if the Email Activity status is Bounced or Dropped
        List<Channel_Metrics_vod__c> allChannelMetrics = [Select Account_vod__c, RecordTypeId, Channel_Value_vod__c From Channel_Metrics_vod__c Where Account_vod__c in :accountIdsBouncedOrDropped And Channel_Value_vod__c in :emailAddressesBouncedOrDropped];
        List<Channel_Metrics_vod__c> toBeUpserted = new List<Channel_Metrics_vod__c>();
        Set<Id> toUpdate = new Set<Id>();
        for(Email_Activity_vod__c activity: emailActivitiesBouncedOrDropped){
            Sent_Email_vod__c email = sentEmailMap.get(activity.Sent_Email_vod__c);
            if(isTestMode(email)){
                break;
            }
            for(Channel_Metrics_vod__c channelMetricsObject: allChannelMetrics){
                if(channelMetricsObject.Channel_Value_vod__c.equals(email.Account_Email_vod__c) && channelMetricsObject.Account_vod__c.equals(email.Account_vod__c)){
                    channelMetricsObject.Last_Email_Error_Date_vod__c = activity.Activity_DateTime_vod__c;
                    channelMetricsObject.Email_Delivery_Error_vod__c = 'Bounced_vod';
                    channelMetricsObject.Email_Activity_vod__c = activity.Id;
                    channelMetricsObject.Channel_Source_vod__c = email.Email_Source_vod__c;
                    toBeUpserted.add(channelMetricsObject);
                    toUpdate.add(activity.Id);
                    break;
                } 
            }
        }
        for(Email_Activity_vod__c activity: emailActivitiesBouncedOrDropped){
            Sent_Email_vod__c email = sentEmailMap.get(activity.Sent_Email_vod__c);
             if(isTestMode(email)){
                break;
            }
            if(!toUpdate.contains(activity.Id)){
                Channel_Metrics_vod__c toBeInserted = new Channel_Metrics_vod__c(Account_vod__c = email.Account_vod__c, Channel_Value_vod__c = email.Account_Email_vod__c,
                                                                                 Email_Delivery_Error_vod__c = 'Bounced_vod', Email_Activity_vod__c = activity.Id, 
                                                                                 Last_Email_Error_Date_vod__c = activity.Activity_DateTime_vod__c, Channel_Source_vod__c = email.Email_Source_vod__c );
            	toBeUpserted.add(toBeInserted);
            }
        }
        upsert toBeUpserted;
    }
}