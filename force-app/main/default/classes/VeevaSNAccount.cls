public inherited sharing class VeevaSNAccount {

    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String parentId { get; set; }
    @AuraEnabled public List<String> territories { get; set; }
    @AuraEnabled public Boolean isInTerritory { get; set; }
    @AuraEnabled public Object recordType { get; set; }
    @AuraEnabled public Map<String, Map<String, Object>> fields { get; set; }
  
    public VeevaSNAccount() {}
}