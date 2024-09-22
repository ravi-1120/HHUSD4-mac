public with sharing class VeevaSNOOHAccountRequest {

    @AuraEnabled public String originAccountId { get; set; }
    @AuraEnabled public List<String> accountIds { get; set; }
    @AuraEnabled public List<String> accountFields { get; set; }
}