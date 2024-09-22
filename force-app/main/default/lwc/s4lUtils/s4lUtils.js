import { getPageController } from "c/veevaPageControllerFactory";
import { VeevaMessageRequest } from "c/veevaMessageService";

import ZVOD_UNIQUE_ACTIVITY from "@salesforce/schema/Call2_vod__c.zvod_Unique_Group_Activities_vod__c";
import ZVOD_DETAILING from "@salesforce/schema/Call2_vod__c.zvod_Detailing_vod__c";

export default class S4lUtils {

    static async doesLayoutHasUniqueActivityField(uiApi, selectedRecordTypeId) {
        const layout = await uiApi.getPageLayoutNoButtons(ZVOD_UNIQUE_ACTIVITY.objectApiName, 'View', selectedRecordTypeId);
        return this.isFieldOnLayout(layout, ZVOD_UNIQUE_ACTIVITY.fieldApiName);
    }

    static isFieldOnLayout (layout, fieldName) {
        if(layout && fieldName) {
            for(const section of layout.sections) {
                for(const row of section.layoutRows) {
                    for(const item of row.layoutItems) {
                        const component = item.layoutComponents.find(x => x.componentType === 'Field');
                        if (component && component.apiName === fieldName) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    static async doesLayoutHaveSDSectionSignal(uiApi, selectedRecordTypeId) {
        const layout = await uiApi.getPageLayoutNoButtons(ZVOD_UNIQUE_ACTIVITY.objectApiName, 'View', selectedRecordTypeId);
        return this.isSectionSignalOnLayoutForField(layout, 'sd', ZVOD_DETAILING.fieldApiName);
    }

    static isSectionSignalOnLayoutForField (layout, signal, zvodField) {
        for(const section of layout.sections) {
            if (section.signals.includes(signal)) {
                for(const row of section.layoutRows) {
                    for(const item of row.layoutItems) {
                        const component = item.layoutComponents.find(x => x.componentType === 'Field');
                        if (component && component.apiName === zvodField) {
                            return true;
                        }
                    }
                }  
            }
        }
        return false;
    }

    static constructModalDataForAccountAlert = (labels, accountValidationResult) => {
        const {errorCode} = accountValidationResult;
        if(errorCode === 'PRODUCT_ERROR') {
            return S4lUtils.constructModalData(labels.productRestriction,
                S4lUtils.substituteMessage(labels.restrictedPresentation,
                    [accountValidationResult.accountFormattedName,
                        accountValidationResult.productName,
                        accountValidationResult.clmPresentationName]));
        } if(errorCode === 'SEGMENT_ERROR') {
            return S4lUtils.constructModalData(labels.segmentRestriction,
                S4lUtils.substituteMessage(labels.retrictedSegmentPresentation,
                    [accountValidationResult.accountFormattedName]));
        } if(errorCode === 'ACCOUNT_ERROR'){
            return S4lUtils.constructModalData(labels.cannotRecordCall,
                S4lUtils.substituteMessage(labels.recordingCallNotAllowedForAccount,
                    [accountValidationResult.accountFormattedName]));
        } 
            return S4lUtils.getReconciliationErrorModalData(labels);
        
    }

    static getReconciliationErrorModalData (labels) {
        return S4lUtils.constructModalData(
            labels.convertCallErrorTitle,
            labels.convertCallError
        );
    }

    static getReconciliationSignedCallErrorModalData (labels) {
        return S4lUtils.constructModalData(
            labels.cannotRecordCall,
            labels.cannotRecordCallSigned
        );
    }

    static constructModalData = (title, message) => ({title, message})

    static substituteMessage = (message, params) => {
        let result = message;
        for(let i = 0; i < params.length; i++) {
            result = result.replace(`{${i}}`, params[i]);
        }
        return result;
    }

    static getMessages = async () => {
        const veevaMessageSvc = getPageController('messageSvc');
        const msgRequest = new VeevaMessageRequest();
        for (const [label, msg] of Object.entries(S4lUtils.SHARED_MESSAGES)) {
            msgRequest.addRequest(msg.key, msg.category, msg.defaultMessage, label);
        }
        return veevaMessageSvc.getMessageMap(msgRequest);
    }

    static SHARED_MESSAGES = {
        convertToCallTitle: {
            key: "CREATE_NEW_CALL_TITLE",
            category: "CLM",
            defaultMessage: "Convert To Call: Create New Call"
        },
        selectAnOption: {
            key: "SELECT_AN_OPTION",
            category: "CLM",
            defaultMessage: "Select an Option"
        },
        addAttendees: {
            key: "ADD_ATTENDEES",
            category: "CLM",
            defaultMessage: "Add Attendees"
        },
        cannotAddAttendeeBecause: {
            key: "CANNOT_ADD_ATTENDEES_BECAUSE",
            category: "CLM",
            defaultMessage: "The following accounts cannot be added as attendees because of either account, product, or segmentation restrictions: {0}"
        },
        convertCallError: {
            key: "CONVERT_CALL_ERROR",
            category: "CLM",
            defaultMessage: "There was an error converting to a call. Please try again or contact your admin."
        },
        convertCallErrorTitle: {
            key: "CONVERT_CALL_ERROR_TITLE",
            category: "CLM",
            defaultMessage: "Convert to Call Error"
        },
        attendeeLimitReached: {
            key: "ATTENDEE_LIMIT_REACHED",
            category: "CLM",
            defaultMessage: "Attendee Limit Reached"
        },
        onlyAddNAttendees: {
            key: "ONLY_ADD_N_ATTENDEES",
            category: "CLM",
            defaultMessage: "You can only add {1} attendees, please remove {0} selected attendees."
        },
        onlyAddNAttendees2: {
            key: "ONLY_ADD_N_ATTENDEES2",
            category: "CLM",
            defaultMessage: "You can only add {0} attendees, please remove attendees before adding more."
        },
        attendeeRestriction: {
            key: 'ATTENDEE_RESTRICTION',
            category: 'CLM',
            defaultMessage: "Attendee Restriction"
        },
        searchAccounts: {
            key: "SEARCH_ACCOUNTS",
            category: "CLM",
            defaultMessage: "Search Accounts"
        },
        thisFieldIsRequired: {
            key: "THIS_FIELD_IS_REQUIRED",
            category: "Common",
            defaultMessage: "This Field is Required"
        },
        segmentRestriction: {
            key: "RESTRICTED_SEGMENT_ALERT_TITLE",
            category: "Common",
            defaultMessage: "Segment Restriction"
        },
        retrictedSegmentPresentation: {
            key: "RESTRICTED_SEGMENT_PRESENTATION",
            category: "CLM",
            defaultMessage: "{0} is not in the appropriate segment(s) and therefore cannot view this presentation."
        },
        productRestriction: {
            key: "RESTRICTED_PRODUCT_ALERT_TITLE",
            category: "Common",
            defaultMessage: "Product Restriction"
        },
        restrictedPresentation: {
            key: "RESTRICT_PRESENTATION",
            category: "CallReport",
            defaultMessage: "{0} is unable to be presented the product {1} in presentation {2}"
        },
        recommendedAccounts: {
            key: "RECOMMENDED_ACCOUNTS",
            category: "Common",
            defaultMessage: "Recommended Accounts"
        },
        add: {
            key: "ADD",
            category: "Common",
            defaultMessage: "Add"
        },
        save: {
            key: "SAVE",
            category: "Common",
            defaultMessage: "Save"
        },
        close: {
            key: "CLOSE",
            category: "Common",
            defaultMessage: "Close"
        },
        previous: {
            key: "PREVIOUS",
            category: "Common",
            defaultMessage: "Previous"
        },
        cancel: {
            key: "CANCEL",
            category: "Common",
            defaultMessage: "Cancel"
        },
        continue: {
            key: "CONTINUE",
            category: "Common",
            defaultMessage: "Continue"
        },
        search: {
            key: "SEARCH",
            category: "Common",
            defaultMessage: "Search"
        },
        selectAll: {
            key: "SELECT_ALL",
            category: "MyAccounts",
            defaultMessage: "Select All"
        },
        deselectAll: {
            key: "DESELECT_ALL",
            category: "Common",
            defaultMessage: "Deselect All"
        },
        attendees: {
            key: "ATTENDEES",
            category: "Common",
            defaultMessage: "Attendees"
        },
        cannotRecordCall: {
            key: "CANNOT_RECORD_CALL_TITLE",
            category: "Common",
            defaultMessage: "Cannot Record Call"
        },
        recordingCallNotAllowedForAccount: {
            key: "RECORDING_CALL_NOT_ALLOWED_FOR_ACCOUNT",
            category: "Common",
            defaultMessage: "Recording a call is not allowed for {0}"
        },
        addToExistingCallTitle: {
            key: "ADD_TO_EXISTING_CALL_TITLE",
            category: "CLM",
            defaultMessage: "Convert To Call: Add to Existing Call"
        },
        cannotRecordCallSigned: {
            key: "CANNOT_RECORD_CALL_SIGNED_FOR_DETAILS",
            category: "CallReport",
            defaultMessage: "Call cannot be recorded because there is an existing signature saved. Clear signature to record a call."
        },
        selectACall: {
            key: "SELECT_A_CALL",
            category: "CLM",
            defaultMessage: "Select a Call"
        },
        showAllCalls: {
            key: "SHOW_ALL_CALLS",
            category: "CLM",
            defaultMessage: "Show All Calls"
        },
        whoViewedMedia: {
            key: "WHO_VIEWED_MEDIA",
            category: "CLM",
            defaultMessage: "Who Viewed Media?"
        },
        selectAttendees: {
            key: "SELECT_ATTENDEES",
            category: "CLM",
            defaultMessage: "Select Attendees"
        },
        accountsOnCall: {
            key: "ACCOUNTS_ON_CALL",
            category: "CLM",
            defaultMessage: "Accounts on Call"
        },
        select: {
            key: "SELECT",
            category: "CLM",
            defaultMessage: "Select"
        },
        cannotAddCallToAccount: {
            key: "CANNOT_ADD_CALL_TO_ACCOUNT",
            category: "CLM",
            defaultMessage: "Cannot record this call because of account, product, or segmentation restrictions on the following account: {0}"
        },
        addAtLeastOneAttendee: {
            key: "ADD_AT_LEAST_ONE_ATTENDEE",
            category: "CLM",
            defaultMessage: "Please add at least one attendee"
        }
    }

}