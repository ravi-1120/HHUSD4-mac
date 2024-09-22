export default class ResourceStore {
    static getResourceStore(externalCalendarInfos, subordinateInfos, userName, translatedLabels) {
        // eslint-disable-next-line no-undef
        const resourceStore = new bryntum.calendar.ResourceStore({
            // eslint-disable-next-line no-undef
            modelClass: bryntum.calendar.ResourceModel,
        });
        if (subordinateInfos?.length > 0 && externalCalendarInfos?.length > 0) {
            resourceStore.add({
                id: 'veevacalendarresourceid',
                isDefault: true,
                name: `${userName} (${translatedLabels.myCalendarMeLabel})`,
                calendarType: 'My Calendars',
                calendarTypeLabel: translatedLabels.myCalendarsLabel,
                cls: 'veeva-calendar-resource',
                order : 1,
            });
        }
        resourceStore.add(externalCalendarInfos.map(externalCalendar =>
        ({
            id: externalCalendar.Id,
            isDefault: externalCalendar.Is_Default_Calendar_vod__c,
            name: externalCalendar.Title_vod__c,
            calendarType : 'My Calendars',
            calendarTypeLabel: translatedLabels.myCalendarsLabel,
            cls: 'external-cal-resource',
            order : 2
        })));
        resourceStore.add(subordinateInfos?.map(subordinateInfo =>
        ({
            id: subordinateInfo.id,
            name: subordinateInfo.name,
            userIdentifier: subordinateInfo.userIdentifier ?? '',
            territoryObjLabel: subordinateInfo.territoryObjLabel ?? '',
            territories: subordinateInfo.territories ?? '',
            isDefault: false,
            calendarType : 'Other Calendars',
            calendarTypeLabel: translatedLabels.otherCalendarsLabel,
            cls: 'subordinate-cal-resource',
            order : 2
        })));
        resourceStore.addSorter("order", true);
        resourceStore.addSorter("isDefault", false);
        resourceStore.addSorter("name", true);
        resourceStore.reapplySortersOnAdd = true;
        return resourceStore;
    }
}