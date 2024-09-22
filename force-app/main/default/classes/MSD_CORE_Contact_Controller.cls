public with sharing class MSD_CORE_Contact_Controller extends MSD_CORE_NewChildrecordTypeAutoSelect{
    public MSD_CORE_Contact_Controller(ApexPages.StandardController ignored) {
        super(Case.SObjectType, MSD_CORE_AE_Contact__c.SObjectType);
    }
}