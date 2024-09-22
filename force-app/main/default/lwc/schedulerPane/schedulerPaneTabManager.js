import SchedulerAccountsManager from "c/schedulerAccountsManager";
import SchedulerCallCyclesManager from "c/schedulerCallCyclesManager";

export default class SchedulerPaneTabManager {

    CALL_CYCLE_TAB_FLS_VALIDATION = ['Week_vod__c', 'Day_of_Week_vod__c', 'Account_vod__c', 'Start_Time_vod__c', 'Duration_vod__c'];

    async getSchedulerTabs(translatedLabels, calendarObjectInfos, settings, weekendDays, weekStartDay, currentDate){
        const tabs = [];
        const accountsTabLabel = calendarObjectInfos.Account.labelPlural;
        const callCyclesTabLabel = translatedLabels.callCyclesLabel;
        const accountsTabManager = new SchedulerAccountsManager(translatedLabels, calendarObjectInfos, settings);
        const callCycleTabManager = new SchedulerCallCyclesManager(translatedLabels, calendarObjectInfos, settings, weekendDays, weekStartDay, currentDate);
        const accountTabItems = await accountsTabManager.getTabPanel();
        const callCycleTabItems = await callCycleTabManager.getTabPanel();
        tabs.push({ label: accountsTabLabel, tabManager : accountsTabManager, tabItems : accountTabItems });
        if (this.hasCallCyclesTabFLS(calendarObjectInfos?.Call_Cycle_Entry_vod__c)){
            tabs.push({ label : callCyclesTabLabel, tabManager : callCycleTabManager, tabItems : callCycleTabItems });
        }
        return tabs;
    }

    hasCallCyclesTabFLS(objectInfo){
        return this.CALL_CYCLE_TAB_FLS_VALIDATION.every(fieldName =>
            objectInfo?.fields?.[fieldName] && objectInfo?.fields?.[fieldName]?.createable && objectInfo?.fields?.[fieldName]?.updateable
        )
    }
}