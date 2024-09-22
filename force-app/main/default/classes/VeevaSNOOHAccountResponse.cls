public with sharing class VeevaSNOOHAccountResponse {

    @AuraEnabled public String originAccountId { get; set; }
    @AuraEnabled public List<VeevaSNAccount> accounts { get; set; }
}