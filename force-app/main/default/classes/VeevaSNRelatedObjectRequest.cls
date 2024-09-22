public with sharing class VeevaSNRelatedObjectRequest {

    @AuraEnabled public String accountId { get; set; }
    @AuraEnabled public Map<String, List<String>> relatedObjectFields { get; set; }
  
    public VeevaSNRelatedObjectRequest() {}
}