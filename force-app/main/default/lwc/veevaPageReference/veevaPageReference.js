/* eslint-disable no-unused-vars */
import getFieldApiName from "@salesforce/apex/VeevaPageReference.getFieldApiName";
import VeevaUtils from 'c/veevaUtils';
import VeevaLayoutService from 'c/veevaLayoutService';

export default class VeevaPageReference {
    static getPageReference = (pageRef) => {
        const result = JSON.parse(JSON.stringify(pageRef));
        let {inContextOfRef} = pageRef.state;
        if (inContextOfRef && typeof inContextOfRef === 'string') {
            // decode parent context
            inContextOfRef = getContextFromString(inContextOfRef);
            result.state.inContextOfRef = inContextOfRef;
        }
        return result;

        function getContextFromString(contextStr) {
            let toParse = contextStr;
            if (!toParse.match(/^\{.*\}$/)) {
                if (toParse.startsWith("1.")) {
                    toParse = toParse.substring(2);
                }
                toParse = window.atob(toParse);
            }
            
            return JSON.parse(toParse);
        }
    }


    // When a user has only one record type assigned, @wire getRecordCreateDefaults does not return correct data
    static getCreateDefaults = async (pageRef, uiAPI) => {
        const recordTypeId = pageRef.state.recordTypeId || null;
        // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
        const apiName = pageRef.attributes.objectApiName;
        const [defaults, buttons] = await Promise.all([uiAPI.getCreateDefaults(apiName, recordTypeId), 
            uiAPI.getDescribeButtons(apiName, recordTypeId)]);
        const layout = JSON.parse(JSON.stringify(defaults.layout));
        layout.buttons = VeevaLayoutService.describeToButtons(buttons);
        const result = { layout: VeevaLayoutService.toVeevaLayout(layout, 'New'), record: JSON.parse(JSON.stringify(defaults.record)) };

        await VeevaPageReference.setParentValueAndDisplayName(defaults, pageRef, result, apiName, uiAPI);

        return result;
    }

    static setParentValueAndDisplayName = async(defaults, pageRef, result, apiName, uiAPI) => {
        // set parent value and displayValue
        // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
        const parentId = pageRef.state.inContextOfRef && pageRef.state.inContextOfRef.attributes.recordId;
        if (pageRef.state.inContextOfRef && parentId) {
            const objInfos = Object.values(defaults.objectInfos);
            const objFlds = Object.values(defaults.objectInfos[apiName].fields);

            const parentFieldName = await VeevaPageReference._getParentFieldName(apiName, objInfos, objFlds, pageRef);
            const parentField = parentFieldName && objFlds.find(fld => fld.apiName === parentFieldName);
            const parentApiName = parentField && parentField.referenceToInfos && 
                parentField.referenceToInfos.length === 1 && parentField.referenceToInfos[0].apiName;
            const parentValueObj = await VeevaPageReference._getParentFieldValueObj(parentId, parentApiName, uiAPI);
            if (parentValueObj) {
                result.record.fields[parentFieldName] = parentValueObj;
            }
        }
    }

    static _getParentFieldName = async (objApiName, objInfos, objFields, pageRef) => {
        let parentFieldName;
        
        const {inContextOfRef} = pageRef.state;
        // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
        const contextAttr = inContextOfRef && inContextOfRef.attributes;
        const parentApiName = contextAttr.objectApiName;     

        if ((inContextOfRef.type === 'standard__recordPage' || inContextOfRef.type === 'standard__recordRelationshipPage') && parentApiName) {
            // look for parent field in inContextOfRef
            let parentFields = objFields.filter(value => value.referenceToInfos && value.referenceToInfos.length && value.referenceToInfos[0].apiName === parentApiName);
            if (parentFields.length > 1){
                parentFields = parentFields.filter(value => value.apiName.includes('_vod__c'))
            }
            if (parentFields.length === 1) {
                parentFieldName = parentFields[0].apiName;
            }
        }
        if (!parentFieldName && pageRef.state.additionalParams) {
            // look for parent field name in additionalParams
            const {additionalParams} = pageRef.state;
            const param = additionalParams.split('&').find(x => x.startsWith('CF'));
            if (param) {
                parentFieldName = await getFieldApiName({ lkid: param.substr(2, 15), objectApiName: objApiName });
            }
        }
        if (!parentFieldName) {
            // look for parent field via child relationship name
            const matchesRelationshipName = (childRelation) => {
                const relationshipName = contextAttr.relationshipApiName;
                return childRelation.relationshipName === relationshipName && childRelation.fieldName.includes('_vod__c');
            }
            const parentObjInfo = objInfos.find((objInfo) => {
                const {childRelationships} = objInfo;
                return childRelationships && childRelationships.some(matchesRelationshipName);
            }); 
            const childRel = parentObjInfo && parentObjInfo.childRelationships.find(matchesRelationshipName);
            parentFieldName = childRel && childRel.fieldName;
        }
        return parentFieldName;
    }

    static _getParentFieldValueObj = async (parentId, parentApiName, uiAPI) => {
        let valueObj;
                
        if (parentId && parentApiName) {
            const [error, data] = await VeevaUtils.to(uiAPI.getRecord(parentId, [`${parentApiName}.Name`], true));
            if (data && data.fields) {
                valueObj = { value: parentId, displayValue: data.fields.Name.value };
            }
        }

        return valueObj;
    }
}