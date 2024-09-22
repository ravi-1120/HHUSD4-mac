public with sharing class VeevaSNRelatedObjectResponse {

    /*
    {
        "accountId": "123",
        "relatedObjectFields" : {
            "Address_vod__c" : {
				"Name": {
                    "displayValue": "123 Formatted Street",
                    "value": "123 Main Street"
                }
            }
        }
    }
    */

    @AuraEnabled public String accountId { get; set; }
    @AuraEnabled public Map<String, Map<String, Map<String, Object>>> relatedObjectFields { get; set; }

    public VeevaSNRelatedObjectResponse() {}
  
    public VeevaSNRelatedObjectResponse(String accountId, Map<String, Map<String, Map<String, Object>>> relatedObjectFields) {
        this.accountId = accountId;
        this.relatedObjectFields = relatedObjectFields;
    }
}