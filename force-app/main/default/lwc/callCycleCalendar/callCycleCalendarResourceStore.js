export default class CallCycleCalendarResourceStore {
    static getResourceStore(weekLabel) {
        // eslint-disable-next-line no-undef
        const resourceStore = new bryntum.calendar.ResourceStore({
            // eslint-disable-next-line no-undef
            modelClass: bryntum.calendar.ResourceModel,
        });
        const resourceArr = Array(12).fill().map((_, index) => ({id: index+1, name: `${weekLabel.replace('{0}', index+1)}`}));
        resourceStore.add(resourceArr);
        resourceStore.addSorter("id", true);
        return resourceStore;
    }
}