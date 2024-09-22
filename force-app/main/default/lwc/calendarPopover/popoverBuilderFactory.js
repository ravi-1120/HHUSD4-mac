import CallPopoverBuilder from "./popoverBuilders/callPopoverBuilder";
import TotPopoverBuilder from "./popoverBuilders/totPopoverBuilder";
import MedicalEventPopoverBuilder from "./popoverBuilders/medicalEventPopoverBuilder";
import CalendarEntryPopoverBuilder from "./popoverBuilders/calendarEntryPopoverBuilder";
import UnavailableTimePopoverBuilder from "./popoverBuilders/unavailableTimePopoverBuilder";
import UpPopoverBuilder from "./popoverBuilders/upPopoverBuilder";
import MeetingRequestPopoverBuilder from "./popoverBuilders/meetingRequestPopoverBuilder";
import ExternalEventPopoverBuilder from "./popoverBuilders/externalEventPopoverBuilder";

export default class PopoverBuilderFactory {
    static getPopover(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode, createCallService) {
        switch (popoverInfo.objectType) {
            case 'Call2_vod__c':
                return new CallPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);
            case 'Time_Off_Territory_vod__c':
                return new TotPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);
            case 'Medical_Event_vod__c': case 'EM_Event_vod__c':
                return new MedicalEventPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);
            case 'Event':
                return new CalendarEntryPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);
            case 'Unavailable_Time_vod__c':
                return new UnavailableTimePopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);
            case 'Multichannel_Activity_vod__c': 
                return new UpPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);
            case 'Meeting_Request_vod__c':
                return new MeetingRequestPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode, createCallService);
            case 'External_Calendar_Event_vod__c':
                return new ExternalEventPopoverBuilder(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode);   
            default:
                return null;
        }
    }
}