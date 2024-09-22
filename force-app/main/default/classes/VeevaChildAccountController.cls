@RestResource(urlMapping='/veeva/child-account')
global with sharing class VeevaChildAccountController {

    private static final VeevaBaseObject CHILD_ACCOUNT_BASE_OBJECT = VeevaBaseObject.create(Child_Account_vod__c.getSObjectType());

    global class VeevaChildAccountResponse extends VeevaBaseResponse {
        @TestVisible
        private final Map<String, Object> data;

        @TestVisible
        private final Map<String, Object> meta;

        private VeevaChildAccountResponse(String savedId) {
            this.data = new Map<String, Object>();
            this.meta = new Map<String, Object>();
            this.data.put('savedId', savedId);
        }
    }

    global class VeevaChildAccountRequest {
        @TestVisible 
        public boolean makePrimary { get; private set; }
        @TestVisible 
        public Map<String, Object> childAccount { get; private set; }
    }

    @HttpPost
    global static VeevaBaseResponse saveChildAccountRequest() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        VeevaChildAccountRequest requestBody;
        try {
            requestBody = getRequestBody(request);
        } catch (Exception ex) {
            response.statusCode = 400;
            return new VeevaBaseResponse('FAILURE', 'Invalid Request');
        }

        if (requestBody.childAccount == null || requestBody.childAccount.isEmpty()) {
            response.statusCode = 400;
            return new VeevaBaseResponse('FAILURE', 'Invalid Request');
        }

        Savepoint savepoint = Database.setSavepoint();
        try {
            Child_Account_vod__c childAccountToSave = createChildAccount(requestBody.childAccount);
            String existingChildAccountId = childAccountToSave.Id;
            if (requestBody.makePrimary) {
                existingChildAccountId = updatePrimaryParentAndReturnAssociatedChildAccountId(childAccountToSave);
            }
            childAccountToSave.put('Id', existingChildAccountId);
            upsert childAccountToSave;
            response.statusCode = 200;
            return new VeevaChildAccountResponse(childAccountToSave.Id);
        } catch (Exception ex) {
            Database.rollback(savepoint);
            response.statusCode = 500;
            return new VeevaBaseResponse('FAILURE', ex.getMessage());
        }
    }

    private static Id updatePrimaryParentAndReturnAssociatedChildAccountId(Child_Account_vod__c childAccount) {
        String childId = childAccount.Child_Account_vod__c;
        String parentId = childAccount.Parent_Account_vod__c;
        Id existingChildAccountId = childAccount.Id;

        if (existingChildAccountId != null) {
            Child_Account_vod__c existingChildAccount = [SELECT Id, Child_Account_vod__c, Parent_Account_vod__c FROM Child_Account_vod__c WHERE Id = :existingChildAccountId];
            childId = existingChildAccount.Child_Account_vod__c;
            parentId = existingChildAccount.Parent_Account_vod__c;
        }

        Account childAccountToUpdate = new Account(Id=childId, Primary_Parent_vod__c=parentId);
        update childAccountToUpdate;

        Id associatedChildAccountId = existingChildAccountId;
        if (associatedChildAccountId == null) {
            List<Child_Account_vod__c> childAccounts = [SELECT Id FROM Child_Account_vod__c WHERE Child_Account_vod__c = :childId AND Parent_Account_vod__c = :parentId];
            associatedChildAccountId = childAccounts.isEmpty() ? null : childAccounts.get(0).Id;
        }
        return associatedChildAccountId;
    }

    private static Child_Account_vod__c createChildAccount(Map<String, Object> fieldMap) {
        Child_Account_vod__c childAccount = new Child_Account_vod__c();
        for (String field : fieldMap.keySet()) {
            Object value = fieldMap.get(field);
            Schema.DescribeFieldResult fieldDescribe = CHILD_ACCOUNT_BASE_OBJECT.getFieldDescribe(field);
            Schema.DisplayType fieldType = fieldDescribe?.getType();
            if (value != null && value instanceof Long
                && (fieldType == Schema.DisplayType.DATE || fieldType == Schema.DisplayType.DATETIME)) {
                Long valueAsLong = (Long) value;
                Datetime valueAsDatetime = Datetime.newInstance(valueAsLong);
                if (fieldType == Schema.DisplayType.DATE) {
                    value = valueAsDatetime.dateGmt();
                } else {
                    value = valueAsDatetime;
                }
            }
            childAccount.put(field, value);
        }
        return childAccount;
    }

    private static VeevaChildAccountRequest getRequestBody(RestRequest request) {
        Map<String, Object> requestBodyMap = (Map<String,Object>) Json.deserializeUntyped(request.requestBody.toString());
        VeevaChildAccountRequest requestBody = new VeevaChildAccountRequest();
        requestBody.makePrimary = Boolean.valueOf(requestBodyMap.get('makePrimary'));
        requestBody.childAccount = (Map<String, Object>) requestBodyMap.get('childAccount');
        return requestBody;
    }
}