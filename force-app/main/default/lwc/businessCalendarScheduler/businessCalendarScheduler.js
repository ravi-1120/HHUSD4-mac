import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import businessCalendarEventStyling from '@salesforce/resourceUrl/businessCalendarEventStyling';
import BusinessCalendarEventMapper from './model/events/businessCalendarEventMapper';
import BusinessCalendarResourceMapper from './model/resources/businessCalendarResourceMapper';
import BusinessCalendarTimeSpanMapper from './model/timespans/businessCalendarTimeSpanMapper';

const RESOURCE_COLUMN_TEXT_CLASS = 'resource-column-text';
const VIEW_PRESETS = {
  QUARTERS: 'year',
  MONTHS: 'monthAndYear',
  WEEKS: 'weekAndMonth',
  DAYS: 'weekAndDayLetter',
};

export default class BusinessCalendarScheduler extends LightningElement {
  @api messages = {};

  shouldDisableEventCreation = true;
  timeSpans = [];
  resources = [];
  resourceFields = [...BusinessCalendarResourceMapper.RESOURCE_FIELDS];
  columns = [
    {
      field: 'name',
      renderer: ({ record: { name } }) => ({
        tag: 'div',
        class: RESOURCE_COLUMN_TEXT_CLASS,
        text: name,
        title: name,
      }),
    },
  ];
  viewPreset = VIEW_PRESETS.MONTHS;
  // Statically sets the default column width so that roughly the first 40 characters of each cell are displayed.
  subGridWidthOverride = '40ch';

  _events = [];

  @api
  get events() {
    return this._events;
  }

  set events(newEventSObjects) {
    const newEvents = [...newEventSObjects];
    const resources = newEvents.map(event => BusinessCalendarResourceMapper.mapResource(event, this.messages));
    this._events = newEvents.map((event, index) => BusinessCalendarEventMapper.mapEvent(event, this.messages, resources[index].id));
    this.timeSpans = newEvents.map(event => BusinessCalendarTimeSpanMapper.mapTimeSpan(event)).filter(timeSpan => timeSpan != null);

    const uniqueResourceIds = new Map();
    this.resources = resources.filter(resource => {
      const existingResource = uniqueResourceIds.get(resource.id);
      if (!existingResource) {
        uniqueResourceIds.set(resource.id, true);
      }

      return !existingResource;
    });
  }

  get scheduler() {
    return this.template.querySelector('c-veeva-bryntum-scheduler-pro');
  }

  get schedulerFeatures() {
    return {
      eventDragCreate: false,
      eventResize: false,
      eventEdit: false,
      taskEdit: false,
      eventMenu: false,
      eventDrag: false,
      dependencies: false,
      filter: true,
      sort: false,
      cellEdit: false,
      timeAxisHeaderMenu: false,
      scheduleMenu: false,
      // Adds vertical marker along the current date
      timeRanges: {
        showCurrentTimeLine: {
          name: this.messages.today,
        },
      },
      eventTooltip: {
        allowOver: true,
        template: this.tooltipRenderer,
      },
      group: {
        field: 'type',
        renderer: ({ groupRowFor: resourceType, isFirstColumn }) => this.rowGroupHeaderRenderer(resourceType, isFirstColumn),
        groupSortFn: ({ originalData: resource1 }, { originalData: resource2 }) => resource1.compareTo(resource2),
      },
      headerMenu: {
        items: {
          // Hides unwanted options from the column header's right-click menu
          groupRemove: false,
          groupAsc: false,
          groupDesc: false,
          columnPicker: false,
          hideColumn: false,
        },
      },
    };
  }

  get tbar() {
    return [
      '->', // Any items after this arrow string will be right-aligned
      {
        type: 'button',
        text: this.messages.today,
        onAction: () => {
          this.centerViewOnToday();
        },
      },
      {
        type: 'combo',
        cls: 'view-selector',
        editable: false,
        autoExpand: true,
        items: [
          [VIEW_PRESETS.QUARTERS, this.messages.quarters],
          [VIEW_PRESETS.MONTHS, this.messages.months],
          [VIEW_PRESETS.WEEKS, this.messages.weeks],
          [VIEW_PRESETS.DAYS, this.messages.days],
        ],
        value: VIEW_PRESETS.MONTHS,
        onChange: ({ value }) => {
          this.viewPreset = value;
        },
      },
    ];
  }

  connectedCallback() {
    loadStyle(this, businessCalendarEventStyling);
  }

  @api
  handleFirstRender() {
    this.centerViewOnToday();
    this.dispatchFirstRenderEvent();
  }

  centerViewOnToday() {
    // call zoomTo twice to avoid issue with header dates disappearing
    this.scheduler.zoomTo({
      preset: this.viewPreset,
    });
    // Maintains the current view preset (i.e. zoom level and time span) but "shifts" the view
    // so that the current date is in the middle with equal time span on both sides
    this.scheduler.zoomTo({
      preset: this.viewPreset,
      centerDate: new Date()
    });
  }

  tooltipRenderer({ eventRecord: { originalData: businessCalendarEvent } }) {
    return businessCalendarEvent.tooltipDomConfig;
  }

  eventRenderer({ eventRecord }) {
    return {
      tag: 'div',
      class: 'event',
      children: [
        {
          tag: 'div',
          text: eventRecord.name,
          class: 'name',
        },
        {
          tag: 'div',
          text: eventRecord.description,
          class: 'description',
        },
      ],
    };
  }

  dispatchFirstRenderEvent() {
    this.dispatchEvent(new CustomEvent('firstrender'));
  }

  rowGroupHeaderRenderer(resourceType, isFirstColumn) {
    const cellText = isFirstColumn ? BusinessCalendarResourceMapper.getGroupName(resourceType, this.messages) : '';
    return {
      tag: 'div',
      class: RESOURCE_COLUMN_TEXT_CLASS,
      text: cellText,
      title: cellText,
    };
  }
}