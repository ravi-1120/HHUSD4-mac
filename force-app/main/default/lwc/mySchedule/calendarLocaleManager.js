import LOCALE from '@salesforce/i18n/locale';
import LANGUAGE from '@salesforce/i18n/lang';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import VeevaBryntumLocaleBuilder from 'c/veevaBryntumLocaleBuilder';
import { VeevaLocaleHelper, VeevaDateHelper } from 'c/veevaLocalizationHelper';

export default class CalendarLocaleManager {
    AM_DATETIME = new Date(2000, 0, 1, 1);

    userLocale;
    weekendDays;
    sfOrgLocale;
    language;
    orgTimeZone;
    currentLocaleLabels = {};

    constructor(weekendDays = [6, 0]) {
        this.userLocale = VeevaLocaleHelper.getUserLanguageLocale();
        this.weekendDays = weekendDays;
        this.sfOrgLocale = LOCALE;
        this.language = LANGUAGE;
        this.orgTimeZone = TIME_ZONE;
    }

    static async getWeekendDays() {
        return VeevaDateHelper.getWeekendDays();
    }

    getMeridiemForUsersLanguage(beforeNoon = true) {
        return VeevaDateHelper.getMeridiem(beforeNoon);
    }

    getMeridiemPlaceHolderForDateFormatString() {
        return VeevaDateHelper.getMeridiemPlaceHolderForDateFormatString();
    }

    getLocaleTimeFormatString() {
        const localeTimeFormatParts = Intl.DateTimeFormat(this.sfOrgLocale, {timeStyle: 'short' }).formatToParts(this.AM_DATETIME);
        const is12Hour = localeTimeFormatParts.filter(part=> part.type === 'dayPeriod').length > 0;

        let timeFormatStr = ''; // build a format string based on the locale piece by piece specifically for use by bryntum
        for(const part of localeTimeFormatParts) {
            if(part.type === 'dayPeriod') {
                timeFormatStr += this.getMeridiemPlaceHolderForDateFormatString();
            } else if (part.type !== 'literal') {
                const partFormat = part.type[0].repeat(part.value.length);
                timeFormatStr += !is12Hour && part.type === 'hour' ? partFormat.toUpperCase() : partFormat.toLowerCase();
            } else {
                timeFormatStr += part.value;
            }
        }
        return timeFormatStr;
    }

    getLocaleDateString() {
        const dateParts = Intl.DateTimeFormat(this.sfOrgLocale, {weekday: 'long', month: 'long', day: 'numeric'}).formatToParts();
        let dateFormatStr = '';
        let previousPart;
        const alphanumericRegex = /^[A-Za-z]+$/i;
        
        for (const part of dateParts) {
            if (part.type === 'weekday') {
                dateFormatStr += 'dddd';
                previousPart = bryntum.calendar.DateHelper.format(new Date(), 'dddd'); // eslint-disable-line no-undef
            } else if (part.type === 'month') {
                dateFormatStr += 'MMMM';
                previousPart = bryntum.calendar.DateHelper.format(new Date(), 'MMMM'); // eslint-disable-line no-undef
            } else if (part.type === 'day') {
                dateFormatStr += 'DD';
                previousPart = bryntum.calendar.DateHelper.format(new Date(), 'DD'); // eslint-disable-line no-undef
            } else if (previousPart.trim().endsWith(part.value.trim())) {
                dateFormatStr += part.value === part.value.trim() ? '' : ' '
            } else if (part.type === 'literal' && alphanumericRegex.test(part.value.trim())) { // include locale specific words
                dateFormatStr += `{${part.value}}`;
            } else {
                dateFormatStr += part.value;
            }
        }
        
        return dateFormatStr;
    }

    dateIsOnWeekend(givenDate) {
        return this.weekendDays.includes(givenDate.getDay());
    }

    static getFormattedTime(dateTime) {
        return VeevaDateHelper.formatTime(dateTime);
    }

    static getFormattedDate(dateTime) {
        return VeevaDateHelper.formatMonthDay(dateTime);
    }

    static getFormattedDateRange(date1, date2) {
        return VeevaDateHelper.formatDateRange(date1, date2);
    }

    /* 
    *  Bryntum allows us to "add" locales to their calendar by supplying a locale object.
    *  This is supplied with custom labels for every location of text that is written by bryntum with our calendar implementation.
    *  Some labels, such as the month name and days of the week, are translated by Bryntum using Intl via the DateHelper.locale value - there is no way to provide translations for these.
    *  This is the only way we can translate the calendar dynamically in its current state; see https://www.bryntum.com/docs/calendar/guide/Calendar/customization/localization.
    */
    _getCalendarLocale(labelTranslations, calendar) {
        const defaultLocaleConfig = calendar.localeManager.locales.En;
        const localeName = labelTranslations.dayLabel.trim() ? this.userLocale : 'temporary-locale'; // specify distinct locale for blank labels
        return new VeevaBryntumLocaleBuilder()
            .withUserLocale(this.userLocale)
            .withFirstDayOfWeek(calendar.weekStartDay)
            .withNonWorkingDays(calendar.nonWorkingDays)
            .withLabels({ ...labelTranslations, noRecords: labelTranslations.noneLabel })
            .withLocaleConfigName(localeName)
            .withDefaultLocaleConfig(defaultLocaleConfig)
            .build();
    }

    translateCalendar(labelTranslations, calendar) {
        this.currentLocaleLabels = this._getCalendarLocale(labelTranslations, calendar);
        calendar.localeManager.applyLocale(this.currentLocaleLabels);
    }

    static async loadTranslatedLabels(messageService) {
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest('OK', 'Common', 'OK', 'okLabel');
        msgRequest.addRequest('Warning', 'Common', 'Warning', 'warningLabel');
        msgRequest.addRequest('Error', 'Common', 'Error', 'errorLabel');
        msgRequest.addRequest('CANCEL', 'Common', 'Cancel', 'cancelLabel');
        msgRequest.addRequest('DATE', 'CALENDAR', 'Date', 'dateLabel');
        msgRequest.addRequest('Address', 'Callplan', 'Address', 'addressLabel');
        msgRequest.addRequest('SIGNED', 'TABLET', 'Signed', 'signedMessage');
        msgRequest.addRequest('SAMPLE_CARD', 'TABLET', 'Sample Card', 'sampleCardMessage');
        msgRequest.addRequest('OWNER', 'Common', 'Owner', 'ownerLabel');
        msgRequest.addRequest('DAY', 'TABLET', 'Day', 'dayLabel');
        msgRequest.addRequest('WEEK', 'TABLET', 'Week', 'weekLabel');
        msgRequest.addRequest('MONTH', 'TABLET', 'Month', 'monthLabel');
        msgRequest.addRequest('AGENDA', 'Common', 'Agenda', 'agendaLabel');
        msgRequest.addRequest('CALL_SCHEDULE_CONFLICT', 'Common', 'Call Schedule Conflict', 'callConflictLabel');
        msgRequest.addRequest('VIEW_ACCOUNT', 'Common', 'View Account', 'viewAccountLabel');
        msgRequest.addRequest('SHOW_WEEKEND', 'Common', 'Show Weekend', 'weekendLabel'); 
        msgRequest.addRequest('Today', 'Common', 'Today', 'todayLabel');
        msgRequest.addRequest('ALL_DAY', 'TABLET', 'All Day', 'allDayLabel');
        msgRequest.addRequest('MORE', 'Common', 'More', 'moreLabel');
        msgRequest.addRequest('FILTER', 'TABLET', 'Filter', 'filterLabel');
        msgRequest.addRequest('END', 'CALENDAR', 'End', 'endLabel');
        msgRequest.addRequest('YEAR', 'TABLET', 'Year', 'yearLabel');
        msgRequest.addRequest('EVENTS', 'TABLET', 'Events', 'eventsLabel');
        msgRequest.addRequest('NONE', 'Common', '--None--', 'noneLabel');
        msgRequest.addRequest('Edit', 'Common', 'Edit', 'editLabel');
        msgRequest.addRequest('DELETE', 'Common', 'Delete', 'deleteLabel');
        msgRequest.addRequest('STATUS', 'Common', 'Status', 'statusLabel');
        msgRequest.addRequest('NEXT', 'View', 'Next', 'nextLabel');
        msgRequest.addRequest('PREVIOUS', 'View', 'Previous', 'previousLabel');
        msgRequest.addRequest('PREV_MONTH', 'CALENDAR', 'Previous Month', 'previousMonthLabel');
        msgRequest.addRequest('NEXT_MONTH', 'CALENDAR', 'Next Month', 'nextMonthLabel');
        msgRequest.addRequest('PREVIOUS_YEAR', 'COMMON', 'Previous Year', 'previousYearLabel');
        msgRequest.addRequest('NEXT_YEAR', 'COMMON', 'Next Year', 'nextYearLabel');
        msgRequest.addRequest('LAST_WEEK', 'Common', 'Last Week', 'lastWeekLabel');
        msgRequest.addRequest('NEXT_WEEK', 'Common', 'Next Week', 'nextWeekLabel');
        msgRequest.addRequest('UNASSIGNED_PRESENTATION', 'CLM', 'Unassigned Presentation', 'unassignedPresentationLabel');
        msgRequest.addRequest('UNAVAILABLE', 'Scheduler', 'Unavailable', 'unavailableTimeLabel');
        msgRequest.addRequest('REMOTE_MEETING_SCHEDULE_WARNING', 'RemoteMeeting', 'Remote Meeting is not fully scheduled.', 'remoteNotScheduledLabel');
        msgRequest.addRequest('INVITATIONS_SENT_PARTIAL', 'RemoteMeeting', '{0} of {1} account attendees have not been invited', 'attendeesNotInvitedLabel');
        msgRequest.addRequest('MORE_DETAILS', 'Common', 'More Details', 'moreDetailsLabel');
        msgRequest.addRequest('VIEWED_SLIDES', 'Scheduler', 'Viewed Slides', 'viewedSlidesLabel');
        msgRequest.addRequest('PAST_REQUEST', 'Scheduler', 'Past Request', 'pastRequestLabel');
        msgRequest.addRequest('MEETING_TYPE_REQUEST', 'Scheduler', 'Meeting Type Request', 'meetingTypeRequestLabel');
        msgRequest.addRequest('ADD_ITEM', 'Common', 'Add {0}', 'addObjectTypeLabel');
        msgRequest.addRequest('INVITEE', 'Scheduler', 'Invitee', 'inviteeLabel');
        msgRequest.addRequest('SLIDE_NO_DESCRIPTION', 'CLM', 'No description', 'noDescriptionLabel');
        msgRequest.addRequest('SLIDE_INFO_NOT_AVAILABLE', 'CLM', 'Slide information not available.', 'slideInfoNotAvailableLabel');
        msgRequest.addRequest('NO_SUBJECT', 'ApprovedEmail', '(No Subject)', 'noSubjectLabel');
        msgRequest.addRequest('CALENDAR', 'TABLET', 'Calendar', 'calendarLabel');
        msgRequest.addRequest('ADD_CALENDAR', 'Scheduler', 'Add calendar', 'addCalendarLabel');
        msgRequest.addRequest('MICROSOFT_AUTH_SUCCESS_CLOSE_WINDOW', 'Common', 'Successfully authenticated to Microsoft. Please close window.', 'addCalendarSuccessMsg');
        msgRequest.addRequest('MICROSOFT_AUTH_FAILURE_CLOSE_WINDOW', 'Common', 'Unable to authenticate. Please close this window and try again.', 'addCalendarFailureMsg');
        msgRequest.addRequest('REFRESH_TO_VIEW_EXTERNAL_CALENDAR', 'Scheduler', 'Retrieving {0} Calendars. Please refresh in a few minutes.', 'loadingCalendarsMsg');
        msgRequest.addRequest('CALL_BACKDATE_WARNING', 'CallReport', 'You may not save a call more than {0} days in the past.', 'backdateMsg');        
        msgRequest.addRequest('ACCOUNT_VIEW', 'Common', 'Account View', 'accountViewLabel');
        msgRequest.addRequest('LISTS', 'Common', 'Lists', 'listsLabel');
        msgRequest.addRequest('ACCOUNTS_NUM_PAREN', 'Common', 'Accounts ({0})', 'accountsNumParenLabel');
        msgRequest.addRequest('ALL_ACCOUNTS', 'MyAccounts', 'All Accounts', 'allAccountsLabel');
        msgRequest.addRequest('ALL_PERSON_ACCOUNTS', 'iPad', 'All Person Accounts', 'allPersonAccountsLabel');
        msgRequest.addRequest('ALL_BUSINESS_ACCOUNTS', 'iPad', 'All Business Accounts', 'allBusinessAccountsLabel');
        msgRequest.addRequest('DRAG_DROP_CREATE_CALL', 'Scheduler', 'Drag and drop to create call', 'dragAndDropSuggestionLabel');
        msgRequest.addRequest('SCHEDULER', 'TABLET', 'Scheduler', 'schedulerLabel');
        msgRequest.addRequest('NO_ACCOUNTS', 'Account', 'No accounts to display', 'noAccountsMsg');
        msgRequest.addRequest('TRY_AGAIN_ERROR', 'Common', 'Looks like something went wrong. Please try again in a moment.', 'systemErrMsg');
        msgRequest.addRequest('ACCOUNT_RECORD_TYPE_ICON_MAP', 'Common', '', 'recordTypeIconMapString');
        msgRequest.addRequest('CONVERT_TO_CALL', 'CLM', 'Convert to Call', 'convertToCallLabel');
        msgRequest.addRequest('DISCARD', 'Common', 'Discard', 'discardLabel');
        msgRequest.addRequest('DISCARD_CONFIRMATION', 'CLM', 'This will delete the unassigned presentation', 'discardConfirmationMsg');
        msgRequest.addRequest('DISCARD_EVENT', 'CLM', 'Discard Event', 'discardEventMsg');
        msgRequest.addRequest('ADD_CALENDAR_ENTRY', 'Scheduler', 'Add Calendar Entry', 'addCalendarEntryLabel');
        msgRequest.addRequest('VIEW_CHILD_ACCOUNT', 'Common', 'View Child Account', 'childAccountLabel');
        msgRequest.addRequest('CHILD_ACCOUNT_VIEW', 'Common', 'Child Account View', 'childAccountViewLabel');
        msgRequest.addRequest('ALL_CHILD_ACCOUNTS', 'Common', 'All Child Accounts', 'allChildAccountsLabel');
        msgRequest.addRequest('SEND_INVITATIONS_PROMPT', 'RemoteMeeting', 'You have not sent invitations for this remote meeting. Would you like to send invitations now?', 'remoteMeetingInviteLabel');
        msgRequest.addRequest('Yes', 'Common', 'Yes', 'yesLabel');
        msgRequest.addRequest('No', 'Common', 'No', 'noLabel');
        msgRequest.addRequest('ALERT_TO_REMOVE_CALLOBJECTIVE', 'CallReport', 'Selected Call Objectives will be removed from this Call Report.  Would you like to continue?","alert if the date change will remove any selected call objectives', 'callObjectiveWarningLabel');
        msgRequest.addRequest('SCHEDULING_FAILED_MS_TEAMS', 'RemoteMeeting', 'Microsoft Teams failed to schedule this meeting.', 'scheduleMSTeamsFailedMsg');
        msgRequest.addRequest('SCHEDULING_FAILED_ENGAGE', 'RemoteMeeting', 'Engage Meeting failed to schedule. Please try again', 'scheduleEngageFailedMsg');
        msgRequest.addRequest('PRIVATE', 'Scheduler', 'Private', 'privateLabel');
        msgRequest.addRequest('CALL_CYCLES', 'Common', 'Call Cycles', 'callCyclesLabel');
        msgRequest.addRequest('APPLY_CALL_CYCLE', 'iPad', 'Apply Call Cycle', 'applyCallCycleLabel');
        msgRequest.addRequest('PREVIEW_MESSAGE', 'Scheduler', 'Select which call cycle to preview on your calendar', 'previewCallCycleMsgLabel');
        msgRequest.addRequest('CYCLE_BY_WEEK', 'Scheduler', 'By Week', 'callCycleByWeekLabel');
        msgRequest.addRequest('CYCLE_BY_DAY', 'Scheduler', 'By Day', 'callCycleByDayLabel');
        msgRequest.addRequest('WEEK_X', 'Scheduler', 'Week {0}', 'weekXLabel');
        msgRequest.addRequest('SELECT_DAY_PREVIEW_BY_WEEK', 'Scheduler', '1. Select call cycle day to preview', 'callCyclePreviewLabel');
        msgRequest.addRequest('SELECT_DAY_PREVIEW_BY_DAY', 'Scheduler', 'Select call cycle day to preview', 'callCyclePreviewByDayLabel');
        msgRequest.addRequest('SELECT_DAY_APPLY_BY_WEEK', 'Scheduler', '2. Select day to apply to', 'callCycleApplyLabel');
        msgRequest.addRequest('CALL_CYCLES_MONTH', 'Scheduler', 'Call cycles cannot be applied through month view', 'disableCallCyclesMonthLabel'); 
        msgRequest.addRequest('ACCOUNT_NOT_VALIDATED', 'CallReport', 'Account Not Validated', 'msgAccountNotValidated');
        msgRequest.addRequest('SCHEDULE_ACCOUNT_RESTRICTION_ERROR', 'Callplan', 'This Account could not be scheduled due to configured restrictions by the account types.', 'msgAccountRestriction');
        msgRequest.addRequest('CALLS_CANNOT_BE_CREATED', 'Scheduler', '{0} Could Not Be Created', 'callsCannotBeCreatedLabel');
        msgRequest.addRequest('DONE', 'Common', 'Done', 'doneLabel');
        msgRequest.addRequest('MANAGE_CALL_CYCLES', 'Scheduler', 'Manage Call Cycles', 'manageCallCyclesLabel');
        msgRequest.addRequest('WEEK_X', 'Scheduler', 'Week {0}', 'weekXLabel');
        msgRequest.addRequest('X_Y', 'Common', '{0} {1}', 'xOfYLabel');
        msgRequest.addRequest('NO_CALL_CYCLES_ON_DAY', 'Scheduler', 'No call cycles on this day', 'noCallCyclesLabel');
        msgRequest.addRequest('ACCEPT', 'TABLET', 'Accept', 'acceptLabel');
        msgRequest.addRequest('REMOVE', 'Common', 'Remove', 'removeLabel');
        msgRequest.addRequest('DECLINE', 'Common', 'Decline', 'declineLabel');
        msgRequest.addRequest('SKIP', 'Common', 'Skip', 'skipLabel');
        msgRequest.addRequest('REMOVE_REASON', 'Scheduler', 'Remove Reason', 'removeReasonLabel');
        msgRequest.addRequest('TOAST_FOR_REMOVED_MEETING_REQUEST', 'Common', '{0} has been removed and will not display on the calendar.', 'toastRemoveLabel');
        msgRequest.addRequest('TOAST_FOR_ACCEPTED_MEETING_REQUEST', 'Common', 'A {0} has already been created for this {1}.', 'toastAcceptLabel');
        msgRequest.addRequest('MY_CALENDARS', 'Scheduler', 'My Calendars', 'myCalendarsLabel');
        msgRequest.addRequest('OTHER_CALENDARS', 'Scheduler', 'Other Calendars', 'otherCalendarsLabel');
        msgRequest.addRequest('ME_IDENTIFIER', 'Scheduler', 'Me', 'myCalendarMeLabel');
        msgRequest.addRequest('CYCLE_PLANS', 'iPad', 'Cycle Plans', 'cyclePlansLabel');
        msgRequest.addRequest('ABBR_ACTUAL', 'CyclePlan', 'A', 'actualAbbreviationLabel');
        msgRequest.addRequest('ABBR_PLANED', 'CyclePlan', 'P', 'plannedAbbreviationLabel');
        msgRequest.addRequest('ABBR_SCHEDULED', 'CyclePlan', 'S', 'scheduledAbbreviationLabel');
        msgRequest.addRequest('ABBR_REMAINING', 'CyclePlan', 'R', 'remainingAbbreviationLabel');
        msgRequest.addRequest('ABBR_REMAINING_SCHEDULE', 'CyclePlan', 'Rs', 'remainingScheduledAbbreviationLabel'); 
        msgRequest.addRequest('TOTAL_RS', 'CyclePlan', 'Total Rs: {0}', 'totalRsLabel');
        
        const translatedMessages = await messageService.getMessageMap(msgRequest);
        return translatedMessages;
    }

    static getBlankLabels() {
        return {
            dateLabel : ' ',
            addressLabel : ' ',
            signedMessage : ' ',
            sampleCardMessage : ' ',
            ownerLabel : ' ',
            dayLabel : ' ',
            weekLabel : ' ',
            monthLabel : ' ',
            agendaLabel : ' ',
            callConflictLabel : ' ',
            viewAccountLabel : ' ',
            weekendLabel : ' ', 
            todayLabel : ' ',
            allDayLabel : ' ',
            moreLabel : ' ',
            filterLabel : ' ',
            endLabel : ' ',
            yearLabel : ' ',
            eventsLabel : ' ',
            noneLabel : ' ',
            editLabel : ' ',
            deleteLabel : ' ',
            statusLabel : ' ',
            nextLabel : ' ',
            previousLabel : ' ',
            previousMonthLabel : ' ',
            nextMonthLabel : ' ',
            previousYearLabel : ' ',
            nextYearLabel : ' ',
            lastWeekLabel : ' ',
            nextWeekLabel : ' ',
            unassignedPresentationLabel : ' ',
            unavailableTimeLabel : ' ',
            remoteNotScheduledLabel : ' ',
            attendeesNotInvitedLabel : ' ',
            moreDetailsLabel : ' ',
            viewedSlidesLabel : ' ',
            pastRequestLabel : ' ',
            meetingTypeRequestLabel : ' ',
            addObjectTypeLabel : ' ',
            inviteeLabel : ' ',
            noDescriptionLabel : ' ',
            slideInfoNotAvailableLabel : ' '
        }
    }
}