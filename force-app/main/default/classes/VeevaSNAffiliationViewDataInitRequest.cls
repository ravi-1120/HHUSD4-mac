public inherited sharing class VeevaSNAffiliationViewDataInitRequest {

    @AuraEnabled public VeevaSNAccount rootAccountData { get; set; }
    @AuraEnabled public List<String> rootsAffiliationIds { get; set; }
}