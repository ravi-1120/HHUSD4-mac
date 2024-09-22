import BusinessCalendarResource from './businessCalendarResource';
import BusinessCalendarCampaignResource from './businessCalendarCampaignResource';

export default class BusinessCalendarResourceMapper {
  static RESOURCE_FIELDS = ['id', 'type', 'productName', 'detailGroupName', { name: 'groupSortOrder', type: 'number' }];

  static mapResource(eventData, messages) {
    switch (eventData.type) {
      case 'Calendar_Event_vod__c':
        return new BusinessCalendarResource('Calendar_Event_vod__c', 'Calendar_Event_vod__c', 0);
      case 'MC_Cycle_vod__c':
        return new BusinessCalendarResource('MC_Cycle_vod__c', 'MC_Cycle_vod__c', 1);
      case 'Campaign_vod__c':
        return new BusinessCalendarCampaignResource(eventData, messages);
      case 'Account_Plan_vod__c':
        return new BusinessCalendarResource('Account_Plan_vod__c', 'Account_Plan_vod__c', 3);
      default:
        return null;
    }
  }

  static getGroupName(resourceType, messages) {
    switch (resourceType) {
      case 'Calendar_Event_vod__c':
        return messages.companyCalendar;
      case 'MC_Cycle_vod__c':
        return messages.cycles;
      case 'Campaign_vod__c':
        return messages.campaigns;
      case 'Account_Plan_vod__c':
        return messages.accountPlans;
      default:
        return '';
    }
  }
}