import { getService } from 'c/veevaServiceFactory';
import MyAccountsDataService from 'c/myAccountsDataService';
import CHILD_ACCOUNT from '@salesforce/schema/Child_Account_vod__c';
import SpeakerSelectionController from './controllers/speakerSelectionController';
import SpeakerSelectionFilterPopoverController from './controllers/speakerSelectionFilterPopoverController';
import SpeakerSelectionDetailsPopoverController from './controllers/speakerSelectionDetailsPopoverController';
import SpeakerSelectionService from './service/speakerSelectionService';
import AttendeeSelectionController from './controllers/attendeeSelectionController';
import AttendeeSelectionDetailsPopoverController from './controllers/attendeeSelectionDetailsPopoverController';
import AttendeeSelectionService from './service/attendeeSelectionService';
import ChildAccountAttendeeSelectionController from './controllers/childAccountAttendeeSelectionController';
import ChildAccountSelectionDetailsPopoverController from './controllers/childAccountSelectionDetailsPopoverController';
import DuplicateError from './support/duplicateError';

const FILTER = 'filter';
const DETAILS = 'details';
const EVENT_SPEAKER_RELATIONSHIP = 'EM_Event_Speaker_vod__r';
const EM_ATTENDEE_RELATIONSHIP = 'EM_Attendee_Event_vod__r';

const getSelectionPageController = (relationField, parentRecord) => {
    let ctrl = {};
    const veevaDataService = getService('dataSvc');
    const uiApi = getService('userInterfaceSvc');
    const veevaMessageService = getService('messageSvc');
    const pleService = getService('emPageLayoutEngineSvc');
    if (relationField === EVENT_SPEAKER_RELATIONSHIP) {
        const speakerService = new SpeakerSelectionService(veevaDataService);
        ctrl = new SpeakerSelectionController(parentRecord, relationField, speakerService, uiApi, veevaMessageService);
    } else if (relationField === EM_ATTENDEE_RELATIONSHIP) {
        const myAccountsDataService = new MyAccountsDataService(veevaDataService);
        const attendeeService = new AttendeeSelectionService(veevaDataService, pleService, myAccountsDataService);
        ctrl = new AttendeeSelectionController(parentRecord, relationField, attendeeService, uiApi, veevaMessageService);
    } else if (relationField === `${EM_ATTENDEE_RELATIONSHIP}.${CHILD_ACCOUNT.objectApiName}`) {
        const myAccountsDataService = new MyAccountsDataService(veevaDataService);
        const attendeeService = new AttendeeSelectionService(veevaDataService, pleService, myAccountsDataService);
        ctrl = new ChildAccountAttendeeSelectionController(parentRecord, EM_ATTENDEE_RELATIONSHIP, attendeeService, uiApi, veevaMessageService);
    }
    return ctrl;
}

const getPopoverController = (relatedList, pageCtrl, type) => {
    let ctrl = {};
    if (relatedList === EVENT_SPEAKER_RELATIONSHIP) {
        if (type === FILTER) {
            ctrl = new SpeakerSelectionFilterPopoverController(pageCtrl);
        } else if (type === DETAILS) {
            ctrl = new SpeakerSelectionDetailsPopoverController(pageCtrl);
        }
    } else if (relatedList === EM_ATTENDEE_RELATIONSHIP) {
        ctrl = new AttendeeSelectionDetailsPopoverController(pageCtrl);
    } else if (relatedList === `${EM_ATTENDEE_RELATIONSHIP}.${CHILD_ACCOUNT.objectApiName}`) {
        ctrl = new ChildAccountSelectionDetailsPopoverController(pageCtrl);
    }
    return ctrl;
}

export { getSelectionPageController, getPopoverController, DuplicateError };