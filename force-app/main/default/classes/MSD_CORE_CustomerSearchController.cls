/*
* MSD_CORE_CustomerSearchController
* Created By: Kevin Brace
* Created Date: 11/22/2019
* Description: Controller for MSD_CORE_CustomerSearch vf Page.
*/

public with sharing class MSD_CORE_CustomerSearchController {

    public String caseId { get; set; }
    public String phone { get; set; }
    public String customerNumber { get; set; }
    public String employeeNumber { get; set; }
    public String isPersonSearch { get; set; }
    
    public Account affiliationTo { get; set; }
    public Account affiliationFrom { get; set; }
    public Child_Account_vod__c affiliation { get; set; }
    public Id childAccountMerckRecordTypeId { get; set; }
    public Boolean showAffiliationModal { get; set; }
    public Boolean didAffiliationCreateSucceed { get; set; }
    public String affiliationPrompt { get; set; }
    

    public MSD_CORE_CustomerSearchController () {
       caseId = ApexPages.currentPage().getParameters().get('caseId');
       phone = ApexPages.currentPage().getParameters().get('phone'); 
       customerNumber = ApexPages.currentPage().getParameters().get('customerNumber');        
       employeeNumber = ApexPages.currentPage().getParameters().get('employeeNumber');        
       isPersonSearch = ApexPages.currentPage().getParameters().get('isPersonSearch'); 
        
       affiliationFrom = null;
        affiliationTo = null;
        showAffiliationModal = false;
        affiliation = new Child_Account_vod__c();
           
       /*
        System.debug('KRB1:caseId ' + caseId);
        System.debug('KRB1:phone ' + phone);
        System.debug('KRB1:customerNumber ' + customerNumber);
        System.debug('KRB1:employeeNumber ' + employeeNumber);
        System.debug('KRB1:isPersonSearch ' + isPersonSearch);
       */
    }
    
     public PageReference createAffiliation(){
        didAffiliationCreateSucceed = false;
        SavePoint sp = Database.setSavePoint();
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
		childAccountMerckRecordTypeId = [select Id from RecordType where SObjectType='Child_Account_vod__c' and DeveloperName = :serviceCloudSettings.MSD_CORE_Merck_Affiliation_Record_Type__c].Id;
        try{
            List<Case> lstcs = [SELECT MSD_Core_Business__c, AccountId, Account.Name, MSD_Core_Business__r.Name, MSD_Core_Business__r.Merck_ID_MRK__c, Account.Merck_ID_MRK__c FROM Case WHERE Id =:caseId];
          Child_Account_vod__c affiliation = new Child_Account_vod__c(
                    Child_Account_vod__c = lstcs[0].AccountId,
                    Parent_Account_vod__c  = lstcs[0].MSD_Core_Business__c,
                    RecordTypeId = childAccountMerckRecordTypeId);  
            
            
            insert affiliation;
            didAffiliationCreateSucceed = true;
        } catch (Exception e) {
            // Need to clone failed account and address records to clear id field
            affiliation = affiliation.clone();
            System.debug('Exception creating affiliation: ' + e.getMessage());
            ApexPages.addMessages(e);
            Database.rollback(sp);
        }

        return null;
    }
    
    public PageReference setupAffiliateModal(){
        
        List<Case> lstcs = [SELECT MSD_Core_Business__c, AccountId, Account.Name, MSD_Core_Business__r.Name, MSD_Core_Business__r.Merck_ID_MRK__c, Account.Merck_ID_MRK__c FROM Case WHERE Id =:caseId];
        if(!lstcs.isEmpty()){
            Case cs = lstcs[0];
           if(cs.MSD_Core_Business__c != null
            && cs.AccountId != null
            && String.isNotBlank(cs.MSD_Core_Business__r.Merck_ID_MRK__c)
            && String.isNotBlank(cs.Account.Merck_ID_MRK__c)){
            
            List<Child_Account_vod__c> affiliations = [SELECT Id, Parent_Account_vod__c, Child_Account_vod__c FROM Child_Account_vod__c WHERE Parent_Account_vod__c = :cs.MSD_CORE_Business__c AND Child_Account_vod__c = :cs.AccountId];
            
            if(affiliations.size() == 0){
                System.debug('in if');
                affiliationFrom = cs.Account;
                affiliationTo = cs.MSD_Core_Business__r;
                showAffiliationModal = true;
                affiliation = new Child_Account_vod__c(
                    Child_Account_vod__c = affiliationFrom.Id,
                    Parent_Account_vod__c  = affiliationTo.Id,
                    RecordTypeId = childAccountMerckRecordTypeId);    
                    
                //What Role Does {affiliationFrom.Name} Have at {affiliationTo.Name}?
                affiliationPrompt = Label.MSD_CORE_Affiliation_Prompt
                    .replace('{affiliationFrom.Name}', affiliationFrom.Name)
                    .replace('{affiliationTo.Name}', affiliationTo.Name);
            }
        } 
        }
        return null;
    }

}