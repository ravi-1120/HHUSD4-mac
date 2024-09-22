import { VeevaMessageRequest } from 'c/veevaMessageService';

export default class VeevaBryntumLocaleBuilder {
  userLocale = 'en-US';
  firstDayOfWeek = 0;
  defaultLocaleConfig = {};
  labels = {};
  localeConfigName = 'en-US';
  nonWorkingDays = { 0: true, 6: true };

  withUserLocale(userLocale) {
    this.userLocale = userLocale;
    return this;
  }

  withFirstDayOfWeek(firstDayOfWeek) {
    this.firstDayOfWeek = firstDayOfWeek;
    return this;
  }

  withDefaultLocaleConfig(defaultLocaleConfig) {
    this.defaultLocaleConfig = defaultLocaleConfig;
    return this;
  }

  // Can be used with `defaultMessageRequest` below. Alternatively, components can "override" messages by re-using one
  // of the message keys with a different value.
  withLabels(labels) {
    this.labels = labels;
    return this;
  }

  withLocaleConfigName(localeConfigName) {
    this.localeConfigName = localeConfigName;
    return this;
  }

  withNonWorkingDays(nonWorkingDays) {
    this.nonWorkingDays = nonWorkingDays;
    return this;
  }

  build() {
    return this.localeConfig;
  }

  // Parent components can use this message request with `veevaMessageService.getMessageMap` and then pass the results
  // into `withLabels` to use default messages.
  // eslint-disable-next-line class-methods-use-this
  get defaultMessageRequest() {
    const messageRequest = new VeevaMessageRequest();
    messageRequest.addRequest('AFTER', 'Common', 'After', 'after');
    messageRequest.addRequest('BEFORE', 'Common', 'Before', 'before');
    messageRequest.addRequest('EQUALS', 'Common', 'Equals', 'equals');
    messageRequest.addRequest('LESS_THAN', 'Common', 'Less than', 'lessThan');
    messageRequest.addRequest('MORE_THAN', 'Common', 'More than', 'moreThan');
    messageRequest.addRequest('EDIT_FILTER', 'Common', 'Edit filter', 'editFilter');
    messageRequest.addRequest('REMOVE_FILTER', 'Common', 'Remove filter', 'removeFilter');
    messageRequest.addRequest('SORT_ASCENDING', 'Common', 'Sort ascending', 'sortAscending');
    messageRequest.addRequest('SORT_DESCENDING', 'Common', 'Sort descending', 'sortDescending');
    messageRequest.addRequest('ON_PREPOSITION', 'Common', 'On', 'on');
    messageRequest.addRequest('FILTER', 'Common', 'Filter', 'filter');
    messageRequest.addRequest('NO_RECORDS', 'Common', 'No records to display', 'noRecords');
    messageRequest.addRequest('AGENDA', 'Common', 'Agenda', 'agendaLabel');
    messageRequest.addRequest('DAY', 'TABLET', 'Day', 'dayLabel');
    messageRequest.addRequest('MONTH', 'TABLET', 'Month', 'monthLabel');
    messageRequest.addRequest('WEEK', 'TABLET', 'Week', 'weekLabel');
    messageRequest.addRequest('YEAR', 'TABLET', 'Year', 'yearLabel');
    messageRequest.addRequest('Today', 'Common', 'Today', 'todayLabel');
    messageRequest.addRequest('ALL_DAY', 'TABLET', 'All Day', 'allDayLabel');
    messageRequest.addRequest('MORE', 'Common', 'More', 'moreLabel');
    messageRequest.addRequest('END', 'CALENDAR', 'End', 'endLabel');
    messageRequest.addRequest('NEXT_WEEK', 'Common', 'Next Week', 'nextWeekLabel');
    messageRequest.addRequest('NEXT_MONTH', 'CALENDAR', 'Next Month', 'nextMonthLabel');
    messageRequest.addRequest('NEXT_YEAR', 'COMMON', 'Next Year', 'nextYearLabel');
    messageRequest.addRequest('PREV_MONTH', 'CALENDAR', 'Previous Month', 'previousMonthLabel');
    messageRequest.addRequest('PREVIOUS_YEAR', 'COMMON', 'Previous Year', 'previousYearLabel');
    messageRequest.addRequest('Edit', 'Common', 'Edit', 'editLabel');
    messageRequest.addRequest('DELETE', 'Common', 'Delete', 'deleteLabel');
    messageRequest.addRequest('FILTER', 'TABLET', 'Filter', 'filterLabel');
    messageRequest.addRequest('NEXT', 'View', 'Next', 'nextLabel');
    messageRequest.addRequest('LAST_WEEK', 'Common', 'Last Week', 'lastWeekLabel');
    messageRequest.addRequest('PREVIOUS', 'View', 'Previous', 'previousLabel');

    return messageRequest;
  }

  // Developers can add to this getter and/or extend it to add new translations to their Bryntum component
  get localeConfig() {
    return {
      ...this.defaultLocaleConfig,
      localeDesc: `Custom locale object for ${this.localeConfigName}`,
      localeName: this.localeConfigName,
      DateHelper: {
        ...this.defaultLocaleConfig.DateHelper,
        locale: this.userLocale,
        weekStartDay: this.firstDayOfWeek,
        nonWorkingDays: this.nonWorkingDays,
        unitNames: this.localeUnitNames,
        weekends: this.nonWorkingDays,
        parsers: {
          ...this.defaultLocaleConfig.DateHelper?.parsers,
          L: 'YYYY-MM-DDTHH:mm:ss.SSSSZ',
          LT: 'YYYY-MM-DDTHH:mm:ss.SSSSZ',
        },
      },
      Sort: {
        ...this.defaultLocaleConfig.Sort,
        sortAscending: this.labels.sortAscending,
        sortDescending: this.labels.sortDescending,
      },
      Filter: {
        ...this.defaultLocaleConfig.Filter,
        after: this.labels.after,
        before: this.labels.before,
        equals: this.labels.equals,
        lessThan: this.labels.lessThan,
        moreThan: this.labels.moreThan,
        on: this.labels.on,
        editFilter: this.labels.editFilter,
        removeFilter: this.labels.removeFilter,
        filter: this.labels.filter,
        applyFilter: this.labels.filterLabel,
      },
      GridBase: {
        ...this.defaultLocaleConfig.GridBase,
        noRows: this.labels.noRecords,
      },
      NumberFormat: {
        ...this.defaultLocaleConfig.NumberFormat,
        locale: this.userLocale,
      },
      AgendaView: { ...this.defaultLocaleConfig.AgendaView, Agenda: this.labels.agendaLabel },
      DayView: { ...this.defaultLocaleConfig.DayView, Day: this.labels.dayLabel, dayUnit: this.labels.dayLabel?.toLowerCase() },
      MonthView: {
        ...this.defaultLocaleConfig.MonthView,
        Month: this.labels.monthLabel,
        monthUnit: this.labels.monthLabel?.toLowerCase(),
      },
      WeekView: { ...this.defaultLocaleConfig.WeekView, Week: this.labels.weekLabel, weekUnit: this.labels.weekLabel?.toLowerCase() },
      YearView: { ...this.defaultLocaleConfig.YearView, Year: this.labels.yearLabel, yearUnit: this.labels.yearLabel?.toLowerCase() },
      Calendar: {
        ...this.defaultLocaleConfig.Calendar,
        Today: this.labels.todayLabel,
        allDay: this.labels.allDayLabel,
        weekOfYear: '',
        plusMore: n => `+${n} ${this.labels.moreLabel}`,
        endsOn: x => `${this.labels.endLabel}: ${x}`,
        next: this.getPaginationMethodForLocale(true),
        previous: this.getPaginationMethodForLocale(false),
      },
      DatePicker: {
        ...this.defaultLocaleConfig.DatePicker,
        gotoNextMonth: this.labels.nextMonthLabel,
        gotoNextYear: this.labels.nextYearLabel,
        gotoPrevMonth: this.labels.previousMonthLabel,
        gotoPrevYear: this.labels.previousYearLabel,
      },
      EventEdit: {
        ...this.defaultLocaleConfig.EventEdit,
        'All day': this.labels.allDayLabel,
        'Edit event': this.labels.editLabel,
        Delete: this.labels.deleteLabel,
        day: this.labels.dayLabel,
        week: this.labels.weekLabel,
        month: this.labels.monthLabel,
        year: this.labels.yearLabel,
        decade: e => {
          e.element.style.display = 'none';
        },
      },
      SchedulerBase: {
        ...this.defaultLocaleConfig.SchedulerBase,
        'Delete event': this.labels.deleteLabel,
      },
      Sidebar: {
        ...this.defaultLocaleConfig.Sidebar,
        'Filter events': this.labels.filterLabel,
      },
    };
  }

  get localeUnitNames() {
    return this.defaultLocaleConfig.DateHelper?.unitNames?.map(unitObj => {
      let unit = unitObj.single;
      if (unitObj.single === 'day') {
        unit = this.labels.dayLabel?.toLowerCase();
      } else if (unitObj.single === 'week') {
        unit = this.labels.weekLabel?.toLowerCase();
      } else if (unitObj.single === 'month') {
        unit = this.labels.monthLabel?.toLowerCase();
      } else if (unitObj.single === 'year') {
        unit = this.labels.yearLabel?.toLowerCase();
      }
      return { ...unitObj, single: unit };
    });
  }

  getPaginationMethodForLocale(forNext) {
    return n => {
      if (n.toLowerCase() === this.labels.weekLabel?.toLowerCase()) {
        return forNext ? this.labels.nextWeekLabel : this.labels.lastWeekLabel;
      }
      if (n.toLowerCase() === this.labels.monthLabel?.toLowerCase()) {
        return forNext ? this.labels.nextMonthLabel : this.labels.previousMonthLabel;
      }
      return forNext ? this.labels.nextLabel : this.labels.previousLabel;
    };
  }
}