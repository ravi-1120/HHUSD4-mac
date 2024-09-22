/* global bryntum */
import { LightningElement, api } from 'lwc';
import SCHEDULER_PRO from '@salesforce/resourceUrl/bryntumSchedulerPro';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import VeevaBryntumLocaleBuilder from 'c/veevaBryntumLocaleBuilder';
import { VeevaLocaleHelper } from 'c/veevaLocalizationHelper';
import { getService } from 'c/veevaServiceFactory';
import FIRST_DAY_OF_WEEK from '@salesforce/i18n/firstDayOfWeek';

export default class VeevaBryntumSchedulerPro extends LightningElement {
  schedulerPro;
  isBryntumLoaded = false;

  _events = [];
  _eventStore;
  _resources = [];
  _resourceStore;
  _timeRanges = [];
  _timeRangeStore;
  _columns = [];
  _features = {};
  _viewPreset;
  _resourceModelFields;
  _messageSvc;
  _labels;

  /**
   * Sets the earliest date visible within the rendered scheduler. Can be a String or a Date.
   */
  @api startDate;

  /**
   * Sets the latest date visible within the rendered scheduler. Can be a String or a Date.
   */
  @api endDate;

  // Enables or disables ability for user to double click on time axis headers to zoom in.
  @api zoomOnTimeAxisDoubleClick = false;

  // Enables or disables ability for user to zoom via ctrl-key + mouse wheel.
  @api zoomOnMouseWheel = false;

  /**
   * Configurable toolbar to be rendered at the top of the component. Can be customized with an array of objects containing Widget configuration.
   *
   * More information about the Toolbar config can be found here: https://bryntum.com/products/schedulerpro/docs/api/Core/widget/Toolbar
   * More information about Widgets can be found here: https://bryntum.com/products/schedulerpro/docs/api/Core/widget/Widget
   */
  @api tbar;

  /**
   * Sets the default event styling.
   *
   * More info about eventStyle options can be found here:
   * https://bryntum.com/products/schedulerpro/docs/api/Scheduler/view/mixin/TimelineEventRendering#config-eventStyle
   */
  @api eventStyle = 'colored';

  /**
   * Optional function specifying how events should be rendered. Only necessary if you wish to render more than just the name of the event.
   *
   * More information about this callback function can be found here:
   * https://bryntum.com/products/schedulerpro/docs/api/Scheduler/view/mixin/SchedulerEventRendering#config-eventRenderer
   */
  @api eventRenderer;

  /**
   * Applies Veeva Messages to the scheduler to translate any help text rendered by Bryntum.
   */
  @api localeBuilder = new VeevaBryntumLocaleBuilder()
    .withUserLocale(this.userLangLocale)
    .withLocaleConfigName(this.userLangLocale)
    .withFirstDayOfWeek(FIRST_DAY_OF_WEEK - 1);

  /**
   * Set to `true` in order to disable creation of events via double click.
   */
  @api disableDoubleClickToCreateEvent = false;

  /**
   * Overrides the default subgrid width if populated with a valid CSS unit.
   * Since Bryntum programmatically updates the subgrid width during instantiation, using pure CSS will not work.
   */
  @api subGridWidthOverride;

  /**
   * Defines the granularity of the scheduler view. Can be a String (e.g. 'weekAndDay') or a ViewPresetConfig object.
   *
   * More info about ViewPresets can be found here: https://bryntum.com/products/schedulerpro/docs/api/Scheduler/preset/PresetManager
   */
  @api
  get viewPreset() {
    return this.schedulerPro?.viewPreset ?? this._viewPreset;
  }

  set viewPreset(newPreset) {
    if (this.schedulerPro) {
      this.schedulerPro.viewPreset = newPreset;
    } else {
      this._viewPreset = newPreset;
    }
  }

  /**
   * Object defining the scheduler's features.
   *
   * More info about feature configuration can be found here: https://www.bryntum.com/products/schedulerpro/docs/api/api
   */
  @api
  get features() {
    return this._features;
  }

  set features(newFeatures) {
    this._features = { ...newFeatures };
  }

  /**
   * Represents the list of events to render in the scheduler view. If the Bryntum library has not yet been loaded,
   * then the records will be stored in this._events until a proper instance of EventStore can be created.
   *
   * More info about EventModel objects can be found here: https://www.bryntum.com/products/schedulerpro/docs/api/SchedulerPro/model/EventModel
   */
  @api
  get events() {
    return this.eventStore?.data ?? this._events;
  }

  set events(newEvents) {
    const events = [...newEvents];
    if (this.eventStore) {
      this.eventStore.data = events;
    } else {
      this._events = events;
    }
  }

  /**
   * Represents the list of resources to render as rows in the grid view. Resources represent a logical grouping of events. If the Bryntum library has not
   * yet been loaded, then the records will be stored in this._resources until a proper instance of ResourceStore can be created.
   *
   * More info about ResourceModel objects can be found here: https://www.bryntum.com/products/schedulerpro/docs/api/Scheduler/model/ResourceModel
   */
  @api
  get resources() {
    return this.resourceStore?.data ?? this._resources;
  }

  set resources(newResources) {
    const resources = [...newResources];
    if (this.resourceStore) {
      this.resourceStore.data = resources;
    } else {
      this._resources = resources;
    }
  }

  /**
   * The fields that our resource store will be aware of.
   */
  @api
  get resourceModelFields() {
    return this.resourceStore?.fields ?? this._resourceModelFields;
  }

  /**
   * Updates the Model class used by our resource store to be aware of the fields provided.
   *
   * By default the Scheduler reads the first resource entry to determine which fields are available for the Store.
   * By providing model fields this enables the Scheduler's resource store to be aware of all of the different fields.
   *
   * More info about Model objects can be found here: https://bryntum.com/products/schedulerpro/docs/api/Core/data/Model
   */
  set resourceModelFields(value) {
    // We will only update model fields if the incoming value is an array
    if (Array.isArray(value)) {
      // When resourceModelFields are objects we will create a copy of the object, if it is a string we will copy the string as it is
      this._resourceModelFields = [...value].map(field => (typeof field === 'string' ? field : { ...field }));
    }

    // We will only update model fields if resource store has already been created
    if (this.resourceStore) {
      this.resourceStore.fields = this._resourceModelFields;
    }
  }

  /**
   * Represents the list of time ranges to render in the scheduler. If the Bryntum library has not
   * yet been loaded, then the records will be stored in this._timeRanges until a proper instance of TimeRangeStore can be created.
   *
   * More info about TimeRanges can be found here: https://bryntum.com/products/schedulerpro/docs/api/Scheduler/feature/TimeRanges
   */
  @api
  get timeRanges() {
    return this.timeRangeStore?.data ?? this._timeRanges;
  }

  set timeRanges(newTimeRanges) {
    const timeRanges = [...newTimeRanges];
    if (this.timeRangeStore) {
      this.timeRangeStore.data = timeRanges;
    } else {
      this._timeRanges = timeRanges;
    }
  }

  /**
   * Represents the list of fields to render as columns in the grid view.
   *
   * More info about Column objects can be found here: https://www.bryntum.com/products/schedulerpro/docs/api/Grid/column/Column
   */
  @api
  get columns() {
    return this._columns;
  }

  set columns(newColumns) {
    this._columns = newColumns.map(column => ({ ...column }));
  }

  /**
   * The EventStore wraps Events data with additional information used by Bryntum, such as sorters and filters applied to the Events.
   * Returns null until Bryntum has been loaded.
   *
   * More info about EventStore objects can be found here: https://www.bryntum.com/products/schedulerpro/docs/api/SchedulerPro/data/EventStore
   */
  @api
  get eventStore() {
    if (this.isBryntumLoaded && !this._eventStore) {
      this._eventStore = new bryntum.schedulerpro.EventStore({
        data: this._events,
        syncDataOnLoad: false,
      });
    }

    return this._eventStore;
  }

  /**
   * The ResourceStore wraps Resources data with additional information used by Bryntum, such as sorters and filters applied to the Resources.
   * Returns null until Bryntum has been loaded.
   *
   * More info about ResourceStore objects can be found here: https://www.bryntum.com/products/schedulerpro/docs/api/SchedulerPro/data/ResourceStore
   */
  @api
  get resourceStore() {
    if (this.isBryntumLoaded && !this._resourceStore) {
      this._resourceStore = new bryntum.schedulerpro.ResourceStore({
        data: this._resources,
        syncDataOnLoad: true,
        fields: this._resourceModelFields,
      });
    }

    return this._resourceStore;
  }

  /**
   * The TimeRangeStore wraps TimeRange data with additional information used by Bryntum.
   * Returns null until Bryntum has been loaded.
   *
   * More info about TimeRangeStore objects can be found here: https://bryntum.com/products/schedulerpro/docs/api/Scheduler/model/ProjectModel#property-timeRangeStore
   */
  @api
  get timeRangeStore() {
    if (this.isBryntumLoaded && !this._timeRangeStore) {
      // There is no `TimeRangeStore` class in Bryntum that can be instantiated.
      // Instead we must use a generic `Store` with modelClass set to `TimeSpan`.
      this._timeRangeStore = new bryntum.schedulerpro.Store({
        data: this._timeRanges,
        modelClass: bryntum.schedulerpro.TimeSpan,
      });
    }

    return this._timeRangeStore;
  }

  get userLangLocale() {
    return VeevaLocaleHelper.getUserLanguageLocale();
  }

  async connectedCallback() {
    this._messageSvc = getService('messageSvc');
    await this.loadResources();
    this.renderSchedulerPro();
  }

  /**
   * Zooms to a particular view in the scheduler. See Bryntum's documentation for all possible config properties:
   * https://bryntum.com/products/scheduler/docs/api/Scheduler/view/mixin/TimelineZoomable#function-zoomTo
   *
   * @param {Object|String|Number} config Config object, preset name, or zoom level index
   */
  @api
  zoomTo(config) {
    this.schedulerPro?.zoomTo(config);
  }

  async loadResources() {
    try {
      [this._labels] = await Promise.all([
        this._messageSvc.getMessageMap(this.localeBuilder.defaultMessageRequest),
        loadScript(this, `${SCHEDULER_PRO}/schedulerpro.lwc.module.min.js`),
        loadStyle(this, `${SCHEDULER_PRO}/schedulerpro.stockholm.min.css`),
      ]);
      this.isBryntumLoaded = true;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(`Error creating scheduler pro: ${error}`);
    }
  }

  renderSchedulerPro() {
    this.schedulerPro = new bryntum.schedulerpro.SchedulerPro({
      appendTo: this.template.querySelector('div.scheduler-pro-container'),
      project: {
        eventStore: this.eventStore,
        resourceStore: this.resourceStore,
        timeRangeStore: this.timeRangeStore,
      },
      features: this.features,
      startDate: this.startDate,
      endDate: this.endDate,
      viewPreset: this.viewPreset,
      columns: this.columns,
      zoomOnTimeAxisDoubleClick: this.zoomOnTimeAxisDoubleClick,
      zoomOnMouseWheel: this.zoomOnMouseWheel,
      tbar: this.tbar,
      eventStyle: this.eventStyle,
      eventRenderer: this.eventRenderer,
      createEventOnDblClick: !this.disableDoubleClickToCreateEvent,
    });

    this.localizeSchedulerPro();
    this.overrideLockedSubGridWidth();
    this.dispatchFirstRenderEvent();
  }

  localizeSchedulerPro() {
    const localeConfig = this.localeBuilder
      .withDefaultLocaleConfig(this.schedulerPro.localeManager.locales.En)
      .withLabels(this._labels)
      .build();
    this.schedulerPro.localeManager.applyLocale(localeConfig);
  }

  overrideLockedSubGridWidth() {
    if (this.subGridWidthOverride) {
      this.schedulerPro.subGrids.locked.width = this.subGridWidthOverride;
    }
  }

  dispatchFirstRenderEvent() {
    this.dispatchEvent(new CustomEvent('firstrender'));
  }
}