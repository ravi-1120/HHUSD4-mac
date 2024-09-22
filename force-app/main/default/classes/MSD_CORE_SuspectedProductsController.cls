public with sharing class MSD_CORE_SuspectedProductsController extends MSD_CORE_NewChildrecordTypeAutoSelect{
    public MSD_CORE_SuspectedProductsController(ApexPages.StandardController ignored) {
        super(Case.SObjectType, MSD_CORE_AE_Product__c.SObjectType);
    }
}