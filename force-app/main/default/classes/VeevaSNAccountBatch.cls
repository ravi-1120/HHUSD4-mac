public inherited sharing class VeevaSNAccountBatch {

    @AuraEnabled public String batchId { get; set; }
    @AuraEnabled public List<VeevaSNAccount> accounts { get; set; }
    @AuraEnabled public List<SObject> affiliations { get; set; }
    @AuraEnabled public Boolean limitTriggered { get; set; }
  
    public VeevaSNAccountBatch() {}
}