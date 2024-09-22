public with sharing class VeevaContractLineControllerExtension extends VeevaRecordTypeConstraint {
    public VeevaContractLineControllerExtension(ApexPages.StandardController stdController) {
        super(stdController);
    }

    public override PageReference getRedirect() {
        PageReference pageReference = super.getRedirect();
        Map<String, String> parentParameters = pageReference.getParameters();
        String contractLineId = parentParameters.get('id');
        RecordType recordType;
        Contract_vod__c contract;
        if(contractLineId != null && ''.equals(parentRecordTypeDeveloperName) && ''.equals(parentContractName) && parentContractId == null && parentRecordTypeId == null) {
            Contract_Line_vod__c currentRecord = [SELECT Contract_vod__r.Id, Contract_vod__r.Name, RecordType.DeveloperName, RecordType.Id, Name
                                                  FROM Contract_Line_vod__c WHERE Id = :contractLineId];
            recordType = currentRecord.RecordType;
            contract = currentRecord.Contract_vod__r;
        } else {
            recordType = new RecordType(Id = parentRecordTypeId, DeveloperName=parentRecordTypeDeveloperName);
            contract = new Contract_vod__c(Id = parentContractId, Name = parentContractName);
        }
        if('Series_Contract_vod'.equals(recordType.DeveloperName)) {
            pageReference = createPageReference('/apex/Contract_Line_Series_Contract_Edit_vod', parentParameters, contract, recordType);
        }
        return pageReference;
    }

    private PageReference createPageReference(String url, Map<String, String> parentParameters, Contract_vod__c contract, RecordType recordType) {
        PageReference pageReference = new PageReference(url);
        Map<String, String> parameters = pageReference.getParameters();
        parameters.putAll(parentParameters);
        parameters.putAll(ApexPages.currentPage().getParameters());
        parameters.put('sfdc.override', '1');
        parameters.put('queryParams', 'contractName=' + contract.Name + '&contractId=' + contract.Id + '&RecordType=' + recordType.Id);
        setRetURL(parameters);
        return pageReference;
    }

}