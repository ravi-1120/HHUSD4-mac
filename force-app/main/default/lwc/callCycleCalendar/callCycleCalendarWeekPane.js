export default class CallCycleCalendarWeekPane {
    resourceFilter;

    constructor({ calendar, resourceStore, translatedLabels, callObjectInfos, selected }) {
        this.calendar = calendar;
        this.resourceStore = resourceStore;
        this.translatedLabels = translatedLabels;
        this.callObjectInfos = callObjectInfos;
        this.selected = selected;
    }

    getCallCycleCalendarWeekPane() {
        // eslint-disable-next-line no-new,no-undef
        this.resourceFilter = new bryntum.calendar.ResourceFilter({
            cls: 'week-pane',
            style: 'padding:0',
            store: this.resourceStore,
            eventStore: this.calendar?.project?.eventStore,
            multiSelect: false,
            scrollable: true,
            selected: [this.selected],
            itemTpl: (resource) => this.renderEntry(resource),
        });

        // eslint-disable-next-line no-new,no-undef
        this.weekPane = new bryntum.calendar.Panel({
            scrollable: true,
            bodyCls: 'call-cycle-week-pane',
            width: '279px',
            items: {
                resourceFilter : this.resourceFilter
            }
        });
        return this.weekPane;
    }

    renderEntry(resource) {
        const count = resource?.events?.filter(e => !e.deleted).length;
        const callLabel = count === 1 ? `${this.callObjectInfos.label}` : `${this.callObjectInfos.labelPlural}`;
        return `<div class='call-cycle-week-pane-entry'>${resource.name}</div>
                <div class='call-cycle-week-pane-entry-count'>${this.translatedLabels.xOfYLabel.replace('{0}', count).replace('{1}', callLabel)}</div>`;
    }
}