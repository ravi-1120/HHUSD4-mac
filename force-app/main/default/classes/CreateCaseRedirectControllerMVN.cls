/*
* CreateCaseRedirectControllerMVN
* Created By: Roman Lerman
* Created Date: Jan 1, 2013
* Edited By: Paul Battisson
* Last Edited: May 30, 2014
* Description: This class creates a new Interaction when the "New" button is clicked on the Case list view.
*              This class also creates a new Interaction and opens the Account Search when a call 
*              is received via the CTI integration.
			
			KRB 9/20/2023 23R4.0 - Privacy Consent to be stored in the Interaction Case
*/

public with sharing class CreateCaseRedirectControllerMVN {

    public Case newCase { get; set; }
    public String accountId { get; set; }
    public Boolean closeTab {get; set;}

    private String sourceId;
    private String interactionId;
    private String language;

    //KRB 9/20/2023 23R4.0 - Privacy Consent to be stored in the Interaction Case
    private String privacyconsent;

    public Boolean shouldRenderBusinessSearch { get; set; } { shouldRenderBusinessSearch = false; }

	public CreateCaseRedirectControllerMVN (ApexPages.StandardController controller) {
    	closeTab = false;

        Case c = (Case)controller.getRecord();

        accountId = ApexPages.currentPage().getParameters().get('def_account_id');
        interactionId = ApexPages.currentPage().getParameters().get('interactionId');
        sourceId = ApexPages.currentPage().getParameters().get('sourceId');
        language = ApexPages.currentPage().getParameters().get('language');

        //KRB 9/20/2023 23R4.0 - Privacy Consent to be stored in the Interaction Case
        privacyconsent = ApexPages.currentPage().getParameters().get('privacyconsent');

        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name; 
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<String> profileSet = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Default_to_Business_Search__c));
        
        if(profileSet.contains(profileName)) {
            shouldRenderBusinessSearch = true; 
        }
    }
  
	public void getRedirect () {
        if(interactionId == '0'){
            closeTab = true;
            return;
        }

        newCase = new Case();
        
        if(!String.isBlank(interactionId)){
            List<Case> cases = [select Id, ParentId, AccountId, ContactId from Case where MSD_CORE_External_Id__c =: interactionId limit 1];
            if(cases != null && cases.size() > 0){
                newCase = cases[0];
                return;
            }else{
                newCase.MSD_CORE_External_Id__c = interactionId;
            }
        }

        newCase.RecordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = :Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c].Id;

        if(!String.isBlank(accountId)){
            newCase.AccountId = accountId;
            newCase.ContactId = [select PersonContactId from Account where Id = :accountId].PersonContactId;
        }

        if(!String.isBlank(sourceId)){
            List<MSD_CORE_Source__c> sources = [select Id, MSD_CORE_Campaign__c, MSD_CORE_Campaign__r.IsActive 
                                                from MSD_CORE_Source__c 
                                                where MSD_CORE_External_Id__c = :sourceId
                                                and MSD_CORE_Active__c = true limit 1];
            
            if(sources != null && sources.size() > 0){
                newCase.MSD_CORE_Source__c = sources[0].Id;

                if(!String.isBlank(sources[0].MSD_CORE_Campaign__c) && sources[0].MSD_CORE_Campaign__r.IsActive){
                    newCase.MSD_CORE_Campaign__c = sources[0].MSD_CORE_Campaign__c;
                }
            }
        }

        if(!String.isBlank(language)){
            newCase.MSD_CORE_Preferred_Language__c = language;
        }
        
        //KRB 9/20/2023 23R4.0 - Privacy Consent to be stored in the Interaction Case
        if(!String.isBlank(privacyconsent)){
            System.debug('privacyconsent was populated: ' + privacyconsent);
            newCase.MSD_CORE_PrvcyCsnt__c = privacyconsent;
        }


    	try{
    		insert newCase;
            
            //KRB 9/20/2023 23R4.0 - Privacy Consent to be stored in the Interaction Case
            System.debug('New Case Id:' + newCase.Id);

            newCase = [select Id, ParentId, AccountId, ContactId from Case where Id =: newCase.Id];
    	}catch(Exception e){
    		ApexPages.addMessages(e);
    	}
  	}
}