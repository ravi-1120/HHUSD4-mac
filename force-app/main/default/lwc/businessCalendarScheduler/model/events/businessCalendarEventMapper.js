import { VeevaDateHelper, VeevaNumberHelper } from 'c/veevaLocalizationHelper';
import BusinessCalendarEvent from './businessCalendarEvent';
import BusinessCalendarEventTooltip from './businessCalendarEventTooltip';

const DEFAULT_CALENDAR_EVENT_COLOR = '#73C6F7';
const HOLIDAY_CALENDAR_EVENT_COLOR = '#63C8B8';

export default class BusinessCalendarEventMapper {
  static mapEvent(eventData, messages, resourceId) {
    switch (eventData.type) {
      case 'Calendar_Event_vod__c':
        return new BusinessCalendarEvent(
          eventData.Name,
          eventData.Calendar_vod__r.RecordType?.Name ?? messages.calendarEvent,
          combineDateAndTime(eventData.Start_Date_vod__c, eventData.Start_Time_Local_vod__c),
          combineDateAndTime(eventData.End_Date_vod__c, eventData.End_Time_Local_vod__c),
          eventData.Calendar_vod__r.RecordType?.DeveloperName === 'Holiday_vod' ? HOLIDAY_CALENDAR_EVENT_COLOR : DEFAULT_CALENDAR_EVENT_COLOR,
          resourceId,
          new BusinessCalendarEventTooltip(
            eventData.Calendar_vod__r.RecordType?.Name ?? messages.calendarEvent,
            getBodyLabelsToValuesForCalendarEvent(eventData),
            messages.moreDetails,
            eventData.detailPageUrl
          )
        );
      case 'MC_Cycle_vod__c':
        return new BusinessCalendarEvent(
          eventData.Name,
          eventData.Status_vod__c,
          eventData.Start_Date_vod__c,
          eventData.End_Date_vod__c,
          '#D85D1F',
          resourceId,
          new BusinessCalendarEventTooltip(
            eventData.RecordType?.Name ?? messages.cycle,
            getBodyLabelsToValuesForMCCycle(eventData),
            messages.moreDetails,
            eventData.detailPageUrl
          )
        );
      case 'Campaign_vod__c':
        return new BusinessCalendarEvent(
          eventData.Name,
          getDescriptionForCampaign(eventData),
          eventData.Start_Date_vod__c,
          eventData.End_Date_vod__c,
          eventData.Product_vod__r?.Brand_Color_Code_vod__c ?? '#F3A235',
          resourceId,
          new BusinessCalendarEventTooltip(
            eventData.RecordType?.Name ?? messages.campaign,
            getBodyLabelsToValuesForCampaign(eventData),
            messages.moreDetails,
            eventData.detailPageUrl
          )
        );
      case 'Account_Plan_vod__c':
        return new BusinessCalendarEvent(
          eventData.Name,
          eventData.Account_vod__r?.Formatted_Name_vod__c,
          eventData.Start_Date_vod__c,
          eventData.End_Date_vod__c,
          '#CA9AB0',
          resourceId,
          new BusinessCalendarEventTooltip(
            eventData.RecordType?.Name ?? messages.accountPlan,
            getBodyLabelsToValuesForAccountPlan(eventData),
            messages.moreDetails,
            eventData.detailPageUrl
          )
        );
      default:
        return null;
    }
  }
}

function getBodyLabelsToValuesForCalendarEvent(eventData) {
  return {
    [eventData.fieldNamesToLabels.Name]: eventData.Name,
    [eventData.fieldNamesToLabels.Start_Time_Local_vod__c]: formatDateTime(
      combineDateAndTime(eventData.Start_Date_vod__c, eventData.Start_Time_Local_vod__c)
    ),
    [eventData.fieldNamesToLabels.End_Time_Local_vod__c]: formatDateTime(
      combineDateAndTime(eventData.End_Date_vod__c, eventData.End_Time_Local_vod__c)
    ),
    [eventData.fieldNamesToLabels.Time_Zone_vod__c]: eventData.Time_Zone_vod__c,
    [eventData.fieldNamesToLabels.Description_vod__c]: eventData.Description_vod__c,
  };
}

function getBodyLabelsToValuesForMCCycle(eventData) {
  return {
    [eventData.fieldNamesToLabels.Name]: eventData.Name,
    [eventData.fieldNamesToLabels.Start_Date_vod__c]: formatDate(eventData.Start_Date_vod__c),
    [eventData.fieldNamesToLabels.End_Date_vod__c]: formatDate(eventData.End_Date_vod__c),
    [eventData.fieldNamesToLabels.Status_vod__c]: eventData.Status_vod__c,
  };
}

function getBodyLabelsToValuesForCampaign(eventData) {
  return {
    [eventData.fieldNamesToLabels.Name]: eventData.Name,
    [eventData.fieldNamesToLabels.Product_vod__c]: eventData.Product_vod__r?.Name,
    [eventData.fieldNamesToLabels.Detail_Group_vod__c]: eventData.Detail_Group_vod__r?.Name,
    [eventData.fieldNamesToLabels.Start_Date_vod__c]: formatDate(eventData.Start_Date_vod__c),
    [eventData.fieldNamesToLabels.End_Date_vod__c]: formatDate(eventData.End_Date_vod__c),
    [eventData.fieldNamesToLabels.Status_vod__c]: eventData.Status_vod__c,
  };
}

function getBodyLabelsToValuesForAccountPlan(eventData) {
  return {
    [eventData.fieldNamesToLabels.Name]: eventData.Name,
    [eventData.fieldNamesToLabels.Account_vod__c]: eventData.Account_vod__r?.Formatted_Name_vod__c,
    [eventData.fieldNamesToLabels.Start_Date_vod__c]: formatDate(eventData.Start_Date_vod__c),
    [eventData.fieldNamesToLabels.End_Date_vod__c]: formatDate(eventData.End_Date_vod__c),
    [eventData.fieldNamesToLabels.Progress_vod__c]: eventData.Progress_vod__c != null ? formatPercent(eventData.Progress_vod__c) : '',
  };
}

function formatDate(date) {
  // Pass in 'UTC' timezone to localize the date strings as-is without adjusting for timezone
  return VeevaDateHelper.formatDate(new Date(date), 'UTC');
}

function formatDateTime(date) {
  // Pass in 'UTC' timezone to localize the date strings as-is without adjusting for timezone
  return VeevaDateHelper.formatDateTime(new Date(date), 'UTC');
}

function formatPercent(number) {
  return VeevaNumberHelper.formatPercent(number);
}

// Combines a SF date string (e.g. `'2023-04-01'` for April 1) with a SF time in milliseconds (e.g. `55800000` for 3:30 PM).
function combineDateAndTime(dateString, timeInMillis) {
  const dateInMillis = new Date(dateString).getTime();
  return new Date(dateInMillis + timeInMillis);
}

function getDescriptionForCampaign(campaign) {
  if (campaign.Product_vod__r?.Name && campaign.Detail_Group_vod__r?.Name) {
    return `${campaign.Product_vod__r.Name}, ${campaign.Detail_Group_vod__r.Name}`;
  }

  return campaign.Product_vod__r?.Name ?? '';
}