public inherited sharing class VeevaSNAffiliation {

    @AuraEnabled public String id { get; set; }
    @AuraEnabled public Map<String, Object> fields { get; set; }
    @AuraEnabled public VeevaSNAccount toAccount { get; set; }
    @AuraEnabled public Integer toAccountAffiliationCount { get; set; }
  
    public VeevaSNAffiliation() {}
}