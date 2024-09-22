import BusinessCalendarTimeSpan from './businessCalendarTimeSpan';

export default class BusinessCalendarResourceMapper {
  static mapTimeSpan(eventData) {
    switch (eventData.type) {
      case 'Calendar_Event_vod__c':
        return eventData.Important_vod__c
          ? new BusinessCalendarTimeSpan(
              eventData.Id,
              eventData.Name,
              combineDateAndTime(eventData.Start_Date_vod__c, eventData.Start_Time_Local_vod__c)
            )
          : null;
      default:
        return null;
    }
  }
}

function combineDateAndTime(dateString, timeInMillis) {
  const dateInMillis = new Date(dateString).getTime();
  return new Date(dateInMillis + timeInMillis);
}