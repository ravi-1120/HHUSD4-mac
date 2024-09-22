import FieldController from "c/fieldController";
import VeevaUtils from "c/veevaUtils";
import VeevaLayoutService from "c/veevaLayoutService";

export default class ReferenceController extends FieldController {
    initTemplate() {
        this.veevaFieldReference = true;
        return this;
    }

    // eslint-disable-next-line no-unused-vars
    getInfiniteLoadingParam(response, records) {
        return response.nextPageUrl;
    }

    isInfiniteLoadingEnabled(response) {
        return !!this.getInfiniteLoadingParam(response);
    }

    get selected() {
        const ref = this.data.reference(this.field);
        return ref.apiName ? { ...ref, icon: VeevaUtils.getIconHardcoded(ref.apiName) } : ref;
    }

    // TODO Salesforce fields might have more than one referenceToInfo, i.e. Task.WhoId or Task.WhatId.
    // We might need to support that in the future.
    get targetSObject() {
        return this.field.referenceToInfos[0].apiName;
    }

    get relationshipName() {
        return this.field.relationshipName;
    }

    get nameField() {
        let nameField = 'Name';
        if (this.field.referenceToInfos[0] && this.field.referenceToInfos[0].nameFields.indexOf(nameField) < 0) {
            [nameField] = this.field.referenceToInfos[0].nameFields;
        }
        return nameField;
    }

    async getSearchLabels() {
        let suggestionLabel = '';
        let recentLabel = '';
        const objectInfos = await this.pageCtrl.metaStore.getObjectInfoDirectory();
        const objects = objectInfos && objectInfos.objects;
        if (objects && this.targetSObject && objects[this.targetSObject]) {
            const { labelPlural } = objects[this.targetSObject];
            const search = await this.pageCtrl.getMessageWithDefault('SEARCH', 'Common', 'Search');
            suggestionLabel = `${search} ${labelPlural}...`;
            recentLabel = await this.getRecentLabel(objects[this.targetSObject]);
        }
        return {
            suggestionLabel, 
            recentLabel
        };
    }

    async getRecentLabel(targetObjectInfo) {
        const recentMessage = await this.pageCtrl.getMessageWithDefault('RECENT_LOOKUP_LIST', 'Common', 'Recent {0}');
        return recentMessage.replace('{0}', targetObjectInfo.labelPlural);
    }

    async getColumns() {
        if (!this._columns) {
            const [searchLayoutResponse, objectInfo] = await Promise.all([
                this.pageCtrl.uiApi.searchLayout(this.targetSObject), this.getTargetObjectInfo()
            ]);
            this._columns = VeevaLayoutService.toSearchLayoutColumns(searchLayoutResponse, objectInfo, this.targetSObject);
        }
        return this._columns;
    }

    setColumns(columns) {
        this._columns = columns;
    }

    async getTargetObjectInfo() {
        if (!this.referenceTo) {
            this.referenceTo = await this.pageCtrl.uiApi.objectInfo(this.targetSObject);
        }
        return this.referenceTo;
    }

    async getColumnsAndSearch(searchTerm) {
        const columns = await this.getColumns();
        const response = await this.searchWithColumns(searchTerm);
        return {columns, response};
    }

    async searchWithColumns(term, nextPageUrl) {
        if (term) {
            const response = await this.search(term, nextPageUrl);
            response.records = await this.parseForColumns(response.records);
            return response;
        }
        return {};
    }

    async search(term, nextPageUrl) {
        const response = await this.pageCtrl.uiApi.search(this.objectApiName, this.field.apiName, this.targetSObject, term, this.getDependentValues(), nextPageUrl);
        response.records = response.records.map(record => this.toSearchRecord(record));
        return response;
    }

    saveMissingNameToRecord(name) {
        const ref = this.data.reference(this.field);
        ref.name = name;
        this.data.updateReferenceField(this.field, ref);
    }

    toSearchRecord(record) {
        const result = { id: record.id, apiName: record.apiName, icon: VeevaUtils.getIconHardcoded(record.apiName) };
        Object.entries(record.fields).forEach(([fldName, valueObj]) => {
            result[fldName] = valueObj.displayValue || valueObj.value;
        });
        result.name = result.Name || '';
        return result;
    }

    async parseForColumns(respRecords) {
        const records = respRecords;
        if (records && records.length > 0) {
            const queriedFlds = Object.keys(records[0]);
            const columns = await this.getColumns();
            const missingColFld = columns && columns.some(col=>
                !queriedFlds.includes(col.fieldName));
            if (missingColFld) {
                const respIds = records.map(record=>record.id);
                const colFlds = columns.filter(col=>col.queryFld).map(col=>col.queryFld);
                // fields with relationships
                const relationshipNamesMap = columns.filter(col => col.fieldName).map(col => col.fieldName)
                    .reduce((tempMap, fieldName) => {
                        const fieldNames = fieldName.split('.');
                        if(fieldNames.length > 1){
                            tempMap[fieldNames[0]] = fieldName;
                        }
                        return tempMap;
                    }, {});

                const newRecords = await this.pageCtrl.uiApi.getBatchRecords(respIds, colFlds);
                if (newRecords) {
                    const idToNewFields = newRecords.reduce((tempMap, record)=>{
                        tempMap[record.id] = record.fields;
                        return tempMap;
                    }, {});
                    records.forEach(record => {
                        const fields = idToNewFields[record.id];
                        if (fields) {
                            Object.entries(fields).forEach(([fldName, fldObj])=>{
                                if (!!fldObj.value && !!fldObj.value.fields && (fldName in relationshipNamesMap)) {
                                    record[relationshipNamesMap[fldName]] = !fldObj.displayValue ? fldObj.value.fields.Name.value : fldObj.displayValue;
                                } else {
                                    record[fldName] = (fldName === "RecordType" || !fldObj.displayValue) ? fldObj.value : fldObj.displayValue;
                                }
                            });
                        }
                    });
                }
            }
        }
        return records;
    }

    async searchTerm(term) {
        const messages = await this.pageCtrl.messageSvc.createMessageRequest().addRequest('SHOW_ALL_RESULTS', 'Lightning', 'Show All Results for {0}', 'showAllMsg').sendRequest();
        return messages.showAllMsg.replace('{0}', `"${ term }"`);
    }

    async searchTermInPopup(term) {
        const messages = await this.pageCtrl.messageSvc.createMessageRequest().addRequest('LOOKUP_SEARCH', 'Lightning', '"{0}" in {1}', 'lookupMsg').sendRequest();
        const targetSObjectPluralLabel = await this.pageCtrl.metaStore.getObjectPluralLabel(this.targetSObject);
        return messages.lookupMsg.replace('{0}', `${ term }`).replace('{1}', `${ targetSObjectPluralLabel }`);
    }

    getControllingFields() {
        if (!this._controllingFields) {
            this._controllingFields = [];
            const filter = this.field.filteredLookupInfo;
            if (filter && filter.dependent && !filter.optionalFilter) {
                this._controllingFields = filter.controllingFields;
            }
        }
        return this._controllingFields;
    }

    getDependentValues() {
        const fields = this.getControllingFields();
        if (fields.length) {
            const result = {};
            fields.forEach(x => { result[x] = this.data.rawValue(x) });
            if (this.data.isNew && result.Id) {
                result.Id = null;
            }
            return result;
        }
        return null;
    }

    async getReferencedObjectApiName() {
        let objectApiName;
        if (this.rawValue) {
            const {referenceToInfos} = this.field;
            let matchingReferenceToInfo;
            if (referenceToInfos.length === 1) {
                [matchingReferenceToInfo] = referenceToInfos;
            } else {
                const objectInfos = await this.pageCtrl.metaStore.getObjectInfoDirectory();
                matchingReferenceToInfo = referenceToInfos.find(info => {
                    const objectInfoMeta = objectInfos.objects[info.apiName];
                    return objectInfoMeta && this.rawValue.indexOf(objectInfoMeta.keyPrefix) === 0;
                });
            }
            objectApiName = matchingReferenceToInfo && matchingReferenceToInfo.apiName;
        }
        return objectApiName;
    }

    // Display Salesforce System fields such as CreatedById
    get extra() {
        if (this.meta.layoutComponents && this.meta.layoutComponents.length > 1) {
            const extra = this.meta.layoutComponents.find(x => x.componentType === 'Field' && x.apiName !== this.fieldApiName);
            if (extra) {
                const extraValue = this.data.displayValue(extra.apiName);
                if (extraValue) {
                    return `, ${extraValue}`;
                }
            }
        }
        return null;
    }
}