public without sharing class VeevaContractLineBeforeHdl {
    private List<Contract_Line_vod__c> newContractLines;
    private List<Contract_Line_vod__c> oldContractLines;
    private Map<ID, Contract_Line_vod__c> newContractLinesMap;
    private Map<ID, Contract_Line_vod__c> oldContractLinesMap;

    public VeevaContractLineBeforeHdl(List<Contract_Line_vod__c> newLines, List<Contract_Line_vod__c> oldLines,
                                        Map<ID, Contract_Line_vod__c> newLinesMap,Map<ID, Contract_Line_vod__c> oldLinesMap) {
        newContractLines = newLines;
        oldContractLines = oldLines;
        newContractLinesMap = newLinesMap;
        oldContractLinesMap = oldLinesMap;
    }
    
    public void contractLineBeforeInsertUpdateDelete() {

        // This is being called as a result of the Contract After trigger. Skip all logic below.
        if(VEEVA_CONTRACT_HEADER_CLASS.isFromContractAfterTrigger()) {
            return;
        }

        List<Contract_Line_vod__c> modifiedLines = new List<Contract_Line_vod__c>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> contractLineIds = new Set<Id>();
        List<Contract_Line_vod__c> modifiedSeriesContractLines = new List<Contract_Line_vod__c>();

        if (newContractLines != null && !newContractLines.isEmpty()) {
            modifiedLines.addAll(newContractLines);
        } else if (oldContractLines != null && !oldContractLines.isEmpty()) {
            modifiedLines.addAll(oldContractLines);
        }

        String seriesContractRT = '';
        Schema.RecordTypeInfo info = Schema.SObjectType.Contract_Line_vod__c.getRecordTypeInfosByDeveloperName()
                                                                            .get('Series_Contract_vod');
        if (info != null) {
            seriesContractRT = info.getRecordTypeId();
        }

        for(Contract_Line_vod__c line : modifiedLines) {
            contractIds.add(line.Contract_vod__c);
            contractLineIds.add(line.Id);

            if (!''.equals(line.RecordTypeId) && seriesContractRT.equals(line.RecordTypeId)) {
                modifiedSeriesContractLines.add(line);
            }

        }
        stampPropertiesForSeriesContract(modifiedSeriesContractLines);

        boolean isMultiCurrency = UserInfo.isMultiCurrencyOrganization();
        String contractParentQuery = 'Select Id, Lock_vod__c, Override_Lock_vod__c, Template_vod__c, Agreement_vod__c, Status_vod__c ';
        if(isMultiCurrency) {
            contractParentQuery += ' , CurrencyIsoCode ';
        }
        contractParentQuery += ' FROM Contract_vod__c WHERE Id IN :contractIds';
        Map<Id, Contract_vod__c> contractParents = new Map<Id, Contract_vod__c> (
            (List<Contract_vod__c>) Database.query(contractParentQuery)
        );

        // Locked contract check
        for(Contract_Line_vod__c line : modifiedLines) {
            Contract_Line_vod__c newLine = newContractLinesMap != null ? newContractLinesMap.get(line.Id) : null;
            Contract_Line_vod__c oldLine = newContractLinesMap != null ? oldContractLinesMap.get(line.Id) : null;
            Contract_vod__c contract = contractParents.get(line.Contract_vod__c);

            if((contract.Lock_vod__c && !contract.Override_Lock_vod__c &&
                    !((newLine != null && newLine.Override_Lock_vod__c) || (oldLine != null && oldLine.Override_Lock_vod__c))) ||
                    (contract.Status_vod__c == 'Signed_vod' && (line.Mobile_ID_vod__c == null || !Trigger.isInsert))) {
                line.addError('Contract is locked', false);
            } else if(oldLine != null && oldLine.Lock_vod__c && !oldLine.Override_Lock_vod__c &&
                    (newLine == null || (newLine.Lock_vod__c && !newLine.Override_Lock_vod__c))) {
                line.addError('Contract Line is locked', false);
            } else if (newLine != null && newLine.Override_Lock_vod__c) {
                newLine.Override_Lock_vod__c = false;
            }
        }

        if(newContractLines != null) {
            List<Contract_Line_vod__c> existingContractLines = [SELECT Product_vod__c, Contract_vod__c, Start_Date_vod__c, End_Date_vod__c, Service_vod__c, RecordType.DeveloperName
                FROM Contract_Line_vod__c
                WHERE Id NOT IN :modifiedLines AND Contract_vod__c IN :contractIds];
            Map<String, Set<Contract_Line_vod__c>> contractProductToLines = new Map<String, Set<Contract_Line_vod__c>>();
            Map<String, Set<Contract_Line_vod__c>> contractServiceToLines = new Map<String, Set<Contract_Line_vod__c>>();

            for(Contract_Line_vod__c line : existingContractLines) {
                if (line.Service_vod__c == null) {
                    String contractProductCombo = line.Contract_vod__c + '' + line.Product_vod__c;
                    if (!contractProductToLines.containsKey(contractProductCombo)) {
                        contractProductToLines.put(contractProductCombo, new Set<Contract_Line_vod__c>());
                    }
                    Set<Contract_Line_vod__c> lines = contractProductToLines.get(contractProductCombo);
                    lines.add(line);
                }
                if (line.Service_vod__c != null && line.RecordType.DeveloperName == 'EM_Speaker_Contract_vod') {
                    String contractServiceCombo = line.Contract_vod__c + '' + line.Service_vod__c;
                    if (!contractServiceToLines.containsKey(contractServiceCombo)) {
                        contractServiceToLines.put(contractServiceCombo, new Set<Contract_Line_vod__c>());
                    }
                    Set<Contract_Line_vod__c> lines = contractServiceToLines.get(contractServiceCombo);
                    lines.add(line);
                }
            }

            Map<Id, Product_vod__c> productIdentifierMap = new Map<Id, Product_vod__c>();
            for(Contract_Line_vod__c line : newContractLines) {
                Contract_vod__c parentContract = contractParents.get(line.Contract_vod__c);

                //Check that start date <= end date
                if (line.Start_Date_vod__c != null && line.End_Date_vod__c != null &&
                    line.Start_Date_vod__c > line.End_Date_vod__c) {
                    line.addError(VOD_GET_ERROR_MSG.getErrorMsg('START_EQUAL_OR_LESS_THAN_END', 'Common'));
                }

                if (line.Mandatory_Contract_Line_vod__c && !parentContract.Template_vod__c && !parentContract.Agreement_vod__c) {
                    line.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MANDATORY_CONTRACT_LINE_ERROR', 'Contracts', 'Mandatory Contract Lines are only allowed in Contract Templates and Agreements.'));
                }

                if (!parentContract.Template_vod__c && !parentContract.Agreement_vod__c) {
                    // Unique product and service check for upserts
                    Set<Contract_Line_vod__c> targetLines = new Set<Contract_Line_vod__c>();
                    if (line.Service_vod__c == null) {
                        String contractProductCombo = line.Contract_vod__c + '' + line.Product_vod__c;
                        if (!contractProductToLines.containsKey(contractProductCombo)) {
                            contractProductToLines.put(contractProductCombo, new Set<Contract_Line_vod__c>());
                        }
                        targetLines.addAll(contractProductToLines.get(contractProductCombo));
                    }
                    if (line.Service_vod__c != null && line.RecordType.DeveloperName != 'Sales_vod' && line.RecordType.DeveloperName != 'Listing_vod') {
                        String contractServiceCombo = line.Contract_vod__c + '' + line.Service_vod__c;
                        if (!contractServiceToLines.containsKey(contractServiceCombo)) {
                            contractServiceToLines.put(contractServiceCombo, new Set<Contract_Line_vod__c>());
                        }
                        targetLines.addAll(contractServiceToLines.get(contractServiceCombo));
                    }
                    boolean addToTargetLines = true;
                    for (Contract_Line_vod__c targetLine : targetLines) {
                        if ((line.Start_Date_vod__c == null && line.End_Date_vod__c == null) ||
                            (targetLine.Start_Date_vod__c == null && targetLine.End_Date_vod__c == null)) {
                            line.addError(VOD_GET_ERROR_MSG.getErrorMsg('CONTRACT_LINE_DUPLICATE_ERROR', 'CONTRACTS'));
                            addToTargetLines = false;
                        } else if ((line.Start_Date_vod__c == null && targetLine.Start_Date_vod__c == null) ||
                            (line.End_Date_vod__c == null && targetLine.End_Date_vod__c == null) ||
                            (line.Start_Date_vod__c == null && line.End_Date_vod__c >= targetLine.Start_Date_vod__c) ||
                            (line.End_Date_vod__c == null && line.Start_Date_vod__c <= targetLine.End_Date_vod__c) ||
                            (targetLine.Start_Date_vod__c == null && targetLine.End_Date_vod__c >= line.Start_Date_vod__c) ||
                            (targetLine.End_Date_vod__c == null && targetLine.Start_Date_vod__c <= line.End_Date_vod__c) ||
                            (line.Start_Date_vod__c >= targetLine.Start_Date_vod__c && line.Start_Date_vod__c <= targetLine.End_Date_vod__c) ||
                            (line.End_Date_vod__c >= targetLine.Start_Date_vod__c && line.End_Date_vod__c <= targetLine.End_Date_vod__c) ||
                            (line.Start_Date_vod__c <= targetLine.Start_Date_vod__c && line.End_Date_vod__c >= targetLine.End_Date_vod__c)) {
                            line.addError(VOD_GET_ERROR_MSG.getErrorMsg('CONTRACT_LINE_OVERLAPPING_DATES', 'CONTRACTS'));
                            addToTargetLines = false;
                        }
                    }
                    if (addToTargetLines) {
                        targetLines.add(line);
                    }
                }
                if(line.Product_vod__c != null) {
                    productIdentifierMap.put(line.Product_vod__c, null);
                }

                // Currency handling
                if(isMultiCurrency) {
                    Contract_vod__c contract = contractParents.get(line.Contract_vod__c);
                    String CurrencyIsoCode = (String) contract.get('CurrencyIsoCode');
                    line.put('CurrencyIsoCode', CurrencyIsoCode);
                }
            }

            productIdentifierMap = new Map<Id, Product_vod__c>([SELECT Id, Product_Identifier_vod__c FROM Product_vod__c WHERE Id IN :productIdentifierMap.keySet()]);
            for(Contract_Line_vod__c line : newContractLines) {
                if(line.Product_vod__c != null) {
                    line.Product_Identifier_vod__c = productIdentifierMap.get(line.Product_vod__c).Product_Identifier_vod__c;
                }
            }
        }

        for(Contract_Line_vod__c line : modifiedLines) {
            Contract_vod__c contract = contractParents.get(line.Contract_vod__c);
            if (line.Mandatory_Contract_Line_vod__c && (contract.Agreement_vod__c || contract.Template_vod__c)) {
                if (Trigger.isDelete && !VEEVA_CONTRACT_HEADER_CLASS.isFromContractBeforeTrigger()) {
                    line.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DELETE_MANDATORY_CONTRACT_LINE', 'Contracts', 'This Contract Line is mandatory and cannot be removed.'));
                } else if (Trigger.isUpdate) {
                    Contract_Line_vod__c oldLine = oldContractLinesMap.get(line.Id);
                    if (oldLine.Product_vod__c != line.Product_vod__c) {
                        line.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DELETE_MANDATORY_CONTRACT_LINE', 'Contracts', 'This Contract Line is mandatory and cannot be removed.'));
                    }
                }
            }
        }
    }

    @TestVisible private void stampPropertiesForSeriesContract(List<Contract_Line_vod__c> modifiedSeriesContractLines) {
        if ((modifiedSeriesContractLines.size() == 0) || Trigger.isDelete) {
            return;
        }
        Set<Id> emCatalogIdSet = new Set<Id>();

        for(Contract_Line_vod__c seriesContractLine: modifiedSeriesContractLines) {
            emCatalogIdSet.add(seriesContractLine.Service_vod__c);
        }
        Map<Id, EM_Catalog_vod__c> emCatalogById = new Map<Id, EM_Catalog_vod__c>([SELECT Id, Content_Length_vod__c, Event_Format_vod__c,
                                                                                  Location_Type_vod__c, Program_Type_vod__c, Service_Type_vod__c
                                                                                  FROM EM_Catalog_vod__c WHERE Id IN :emCatalogIdSet]);

        for(Contract_Line_vod__c line: modifiedSeriesContractLines) {
            Id serviceId = line.Service_vod__c;
            EM_Catalog_vod__c emCatalog = emCatalogById.get(serviceId);
            line.Content_Length_vod__c = emCatalog.Content_Length_vod__c;
            line.Event_Format_vod__c = emCatalog.Event_Format_vod__c;
            line.Location_Type_vod__c = emCatalog.Location_Type_vod__c;
            line.Program_Type_vod__c = emCatalog.Program_Type_vod__c;
            line.Service_Type_vod__c = emCatalog.Service_Type_vod__c;
        }
    }
    
    public void deleteEmSpeakerQualifications() {
        List<EM_Speaker_Qualification_vod__c> qualifications = [SELECT Id
                                                                    FROM EM_Speaker_Qualification_vod__c
                                                                    WHERE Contract_Line_vod__c IN : oldContractLinesMap.keySet()];
        if (qualifications.size() > 0) {
            delete qualifications;
        }
    }

    public void contractLineBeforeDelete() {
        deleteEmSpeakerQualifications();
        contractLineBeforeInsertUpdateDelete();
    }
}