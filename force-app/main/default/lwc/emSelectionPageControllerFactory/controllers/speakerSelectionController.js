/* eslint-disable no-param-reassign */
/* eslint-disable class-methods-use-this */
import querySpeakersLex from '@salesforce/apex/EmSpeakerSelection.querySpeakersLex';
import searchSpeakersLex from '@salesforce/apex/EmSpeakerSelection.searchSpeakersLex';
import getSpeakerFilters from '@salesforce/apex/EmSpeakerSelection.getSpeakerFilters';
import getSpeakerFields from '@salesforce/apex/EmSpeakerSelection.getSpeakerFields';
import getRelatedRecords from "@salesforce/apex/VeevaRelatedObjectController.getRelatedRecords"
import EM_SPEAKER from '@salesforce/schema/EM_Speaker_vod__c';
import EM_EVENT_SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c';
import ID from '@salesforce/schema/EM_Event_Speaker_vod__c.Id';
import SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_vod__c';
import EVENT from '@salesforce/schema/EM_Event_Speaker_vod__c.Event_vod__c';
import EVENT_CONFIG from '@salesforce/schema/EM_Event_vod__c.Event_Configuration_vod__c';
import COUNTRY from '@salesforce/schema/EM_Event_vod__c.Country_vod__c';
import TOPIC from '@salesforce/schema/EM_Event_vod__c.Topic_vod__c'
import NAME from '@salesforce/schema/EM_Speaker_vod__c.Name';
import STATUS from '@salesforce/schema/EM_Speaker_vod__c.Status_vod__c';
import NEXT_YEAR_RESET_DATE from '@salesforce/schema/EM_Speaker_vod__c.Next_Year_Reset_Date_vod__c';
import NEXT_YEAR_STATUS from '@salesforce/schema/EM_Speaker_vod__c.Next_Year_Status_vod__c';
import SPEAKER_IDENTIFIER from '@salesforce/schema/EM_Speaker_vod__c.Speaker_Identifier_vod__c';
import START_TIME from '@salesforce/schema/EM_Event_vod__c.Start_Time_vod__c';
import { BusRuleConstant } from 'c/emBusRuleUtils';
import EmBusRuleWarningsModal from 'c/emBusRuleWarningsModal';

const MANDATORY_VOD ='Mandatory_vod';
const OPTIONAL_ON_VOD = 'Optional_On_vod';
const ELIGIBLE_VOD = 'Eligible_vod';
const SPEAKER_FIELD_KEYWORDS = ['CV','RecentEvents', 'Training', 'Services'];
const STATUS_ALIAS = 'statusLabel';
const NEXT_YEAR_STATUS_ALIAS = 'nextYearStatusLabel';
const NEXT_YEAR_RESET_ALIAS = 'nextYearResetLabel';
const ICON = 'custom:custom84';

export default class SpeakerSelectionController {

    constructor(record, relatedList, service, uiApi, veevaMessageService) {
        this.record = record;
        this.relatedList = relatedList;
        this.service = service;
        this.uiApi = uiApi;
        this.veevaMessageService = veevaMessageService;
    }

    get eventId() {
        return this.record?.fields[ID.fieldApiName]?.value;
    }

    get statusAlias() {
        return STATUS_ALIAS;
    }

    get pageTitleMessage() {
        return {key: 'SELECT_SPEAKER', category: 'EVENT_MANAGEMENT', defaultMessage: 'Select Speaker'};
    }

    get icon() {
        return ICON;
    }

    get eventStartTime() {
        return this.record?.fields?.[START_TIME.fieldApiName]?.value;
    }

    getPills(selectedRows) {
        const pills = Object.values(selectedRows) ?? [];
        return pills.map(row => this.createPill(row))
    }

    createPill(row) {
        return {
            id: row.Id,
            icon: ICON,
            label: row[NAME.fieldApiName],
            shape: 'circle',
        };
    }

    async getObjectInfo() {
        if (!this.objectInfo) {
            this.objectInfo = await this.uiApi.objectInfo(EM_SPEAKER.objectApiName);
        }
        return this.objectInfo;
    }

    async getMessage(msg) {
        return this.veevaMessageService.getMessageWithDefault(msg.key, msg.category, msg.defaultMessage);
    }

    async getFilterOptions() {
        if (!this.filterOptions) {
            this.filterOptions = await getSpeakerFilters({
                eventId: this.eventId
            });
        }
        return this.filterOptions;
    }

    async getPreselectedFilters() {
        await this.getFilterOptions();
        let defaultOnFilters = [];
        this.filterOptions.forEach(filterGroup => {
            defaultOnFilters = defaultOnFilters.concat(filterGroup.options
                .filter(filter => filter.filterType === MANDATORY_VOD || filter.filterType === OPTIONAL_ON_VOD)
                .map(filter => ({
                        label: filter.label,
                        value: filter.value,
                        removeable: filter.filterType !== MANDATORY_VOD
                    }))
                );
        });
        return defaultOnFilters;
    }

    async getColumns() {
        try {
            this.speakerFields = await getSpeakerFields({
                eventConfigId: this.record.fields[EVENT_CONFIG.fieldApiName].value, 
                countryId: this.record.fields[COUNTRY.fieldApiName].value
            });
        } catch(error) {
            this.speakerFields = [];
        }
        const defaultQueryFields = [NAME.fieldApiName, SPEAKER_IDENTIFIER.fieldApiName];
        this.queryFields = defaultQueryFields.concat(this.speakerFields?.filter(field => !field.isKeyword && !defaultQueryFields.includes(field.apiName)).map(field => field.apiName));
        this.columns = [
            {
                label: '',
                fieldName: 'checked'
            },
            {
                label: this.objectInfo.fields[NAME.fieldApiName].label,
                fieldName: NAME.fieldApiName
            }]
            .concat(
                this.speakerFields
                .filter(field => !SPEAKER_FIELD_KEYWORDS.includes(field.apiName) && NAME.fieldApiName !== field.apiName)
                .map(field => ({
                        label: field.label,
                        fieldName: this.getFieldName(field.apiName),
                    }))
            );
        return this.columns;
    }

    getFieldName(fieldApiName) {
        let fieldName = fieldApiName;
        if (fieldName === STATUS.fieldApiName) {
            fieldName = this.statusAlias
        } else if (fieldName === NEXT_YEAR_STATUS.fieldApiName) {
            fieldName = NEXT_YEAR_STATUS_ALIAS;
        } else if (fieldName === NEXT_YEAR_RESET_DATE.fieldApiName) {
            fieldName = NEXT_YEAR_RESET_ALIAS;
        }
        return fieldName;
    }

    async search(term, filters, orderBy, orderDirection, limit, offset) {
        const startTime = this.record.fields[START_TIME.fieldApiName].value;
        const filterRules = filters?.map(f => f.value);
        let data = [];
        try {
            // Make sure Next Year Status and Next Year Reset Date are not duplicated
            const defaultFields = [NEXT_YEAR_STATUS.fieldApiName, NEXT_YEAR_RESET_DATE.fieldApiName];
            const fieldsToQuery = [...new Set(defaultFields.concat(this.queryFields))];
            const args = {
                fields: fieldsToQuery,
                filterRules,
                startTime,
                topicId: this.record.fields[TOPIC.fieldApiName]?.value,
                orderBy,
                orderDirection,
                qLimit: limit,
                offset
            };
            if (!term) {
                data = await querySpeakersLex(args);
            } else {
                args.termString = term;
                data = await searchSpeakersLex(args);
            }
        } catch (ex) {
            data = [];
        }
        return data;
    }

    async getExistingRecords() {
        this.initialSpeakersOnEvent = await getRelatedRecords({
            fields: [ID.fieldApiName, SPEAKER.fieldApiName].concat(this.queryFields.map(field => `Speaker_vod__r.${field}`)).join(','),
            objectApiName: EM_EVENT_SPEAKER.objectApiName, 
            relationField: EVENT.fieldApiName, 
            id: this.eventId
        });
        const tmp = {};
        this.initialSpeakersOnEvent?.forEach(record => {
            tmp[record[SPEAKER.fieldApiName]] = record.Speaker_vod__r;
        });
        return tmp;
    }

    processRecord(record) {
        this.updateStatusForSpeakersPastNextYearResetDate(new Date(this.eventStartTime), record);
        if (record.Status_vod__c !== ELIGIBLE_VOD) {
            record.disabled = true;
        }
        return record;
    }

    updateStatusForSpeakersPastNextYearResetDate(eventStartDate, record) {
        if (record[NEXT_YEAR_RESET_DATE.fieldApiName] && record[NEXT_YEAR_STATUS.fieldApiName] && isValidDate(eventStartDate)) {
            const nextYearResetDateStr = record[NEXT_YEAR_RESET_DATE.fieldApiName];
            const nextYearResetDate = new Date(nextYearResetDateStr);
            if (eventStartDate >= nextYearResetDate) {
                record.Status_vod__c = record[NEXT_YEAR_STATUS.fieldApiName];
                record[this.statusAlias] = record[NEXT_YEAR_STATUS_ALIAS];
            }
        }

        function isValidDate(date) {
            return !isNaN(date.getTime());
        }        
    }

    async checkSpeakerRuleWarnings(speakersToAdd) {
        const speakerIds = speakersToAdd.map(speaker => speaker.Speaker_vod__c);
        let remainingSpeakers = speakersToAdd;
        let warnings;
        let modalLabel;
        try {
            [warnings, modalLabel] = await Promise.all([
                this.service.getSpeakerRuleWarnings(speakerIds, this.eventId),
                this.getMessage({key: 'EM_RULE_POTENTIAL_SPEAKER_WARNING_SUBTITLE', category: 'EVENT_MANAGEMENT', defaultMessage: 'The Following Speaker(s) have Potential Rule Violations'}),
            ]);
        } catch (e) {
            const errorMessage = await this.getMessage({
                key: 'ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION',
                category: 'EVENT_MANAGEMENT',
                defaultMessage: 'The requested action cannot be completed. Please try again or contact your administrator.'
            });
            const abortSave = new Error(errorMessage);
            abortSave.name = 'AbortSaveError';
            throw abortSave;
        }
        if (warnings?.length > 0) {
            // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
            const result = await EmBusRuleWarningsModal.open({
                warnings,
                type: BusRuleConstant.RULE_TYPE.PER_SPEAKER,
                label: modalLabel,
                size: 'medium',
            });
            if (result?.recordsToRemove) {
                remainingSpeakers = remainingSpeakers.filter(speaker => !result.recordsToRemove.includes(speaker.Speaker_vod__c));
            } else {
                const abortSave = new Error();
                abortSave.name = 'AbortSaveError';
                throw abortSave;
            }
        }
        return remainingSpeakers;
    }

    async save(selectedSpeakers, recordType) {
        const selectedSpeakerIds = Object.keys(selectedSpeakers);
        let speakersToAdd = selectedSpeakerIds.filter(speakerId => !this.initialSpeakersOnEvent.find(speaker => speaker[SPEAKER.fieldApiName] === speakerId))
            .map(speakerId => ({
                    Speaker_vod__c: speakerId, 
                    Event_vod__c: this.eventId,
                    RecordTypeId: recordType
                })
            ); 

        if (speakersToAdd.length > 0) {
            speakersToAdd = await this.checkSpeakerRuleWarnings(speakersToAdd);
        }

        const speakersToRemove = this.initialSpeakersOnEvent.filter(speaker => !selectedSpeakerIds.includes(speaker[SPEAKER.fieldApiName])).map(speaker => speaker[ID.fieldApiName]);

        const promises = [ this.uiApi.objectInfo(EM_EVENT_SPEAKER.objectApiName) ];
        
        if (speakersToAdd.length > 0) {
            promises.push(this.service.createSpeakers(speakersToAdd)
                .then(response => this.assignNamesToSpeakers(response, selectedSpeakers)));
        }
        if (speakersToRemove.length > 0) {
            promises.push(this.service.deleteSpeakers(speakersToRemove));
        }

        let speakerSaveResults = null;
        if (promises.length > 1) {
            const results = await Promise.all(promises);
            const [ emEventSpeakerObjInfo, ...saveResults ] = results;
            speakerSaveResults = {
                icon: ICON,
                objectLabel: emEventSpeakerObjInfo.label,
                objectLabelPlural: emEventSpeakerObjInfo.labelPlural
            };
            saveResults.forEach(result => {
                Object.assign(speakerSaveResults, result);
            });
        }
        return speakerSaveResults;
    }

    assignNamesToSpeakers(response, selectedSpeakers) {
        if (response?.failedInsertRecords?.length > 0) {
            response.failedInsertRecords.forEach(record => {
                record.name = selectedSpeakers[record.id][NAME.fieldApiName];
            });
        }
        return response;
    }
}