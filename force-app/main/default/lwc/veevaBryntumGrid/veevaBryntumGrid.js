/* global bryntum */ 
import { LightningElement, api } from 'lwc';
import GRID from '@salesforce/resourceUrl/bryntumGrid';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import FIRST_DAY_OF_WEEK from '@salesforce/i18n/firstDayOfWeek';
import VeevaBryntumLocaleBuilder from 'c/veevaBryntumLocaleBuilder';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { loadAllCustomWidgets } from 'c/veevaBryntumWidgets';
import { VeevaLocaleHelper, VeevaDateHelper } from 'c/veevaLocalizationHelper';
import createModelClass from './model/modelClass';

export default class VeevaBryntumGrid extends LightningElement {

  gridDataStore = getService(SERVICES.BYPASS_PROXY_DATA_STORE);

  /**
   * Object defining the grid's features.
   * More info about feature configuration can be found here: https://www.bryntum.com/docs/grid/api/api
   */
  @api features = {};

  /**
   * Setting this to `true` decreases rendering time, but will add some additional fields to
   * each data record supplied in #renderGrid(data, columns)
   */
  @api useRawData = false;

  /**
   * Setting this to `true` will hide the checkbox/row selection column
   */
  @api hideCheckboxColumn = false;

  /**
   * This will control how differences in strings will be handled.
   * Please note that this api property must be set when the component is initially created and will not change afterwards.
   *
   * Please reference "sensitivity" in https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/Collator#options
   */
  @api sensitivity = null;

  /**
   * Returns an array of currently-selected records. If hideCheckboxColumn is true, then this will always
   * return an empty array.
   */
  @api
  get selectedRecords() {
    return this.grid?.selectedRecords ?? this._selectedRecords;
  }
  /**
   * @param {Array} selectedRecordIds - Array of IDs used to mark corresponding rows as selected. Any rows
   * that are not in the array will be unselected. Thus passing in an empty array will unselect all rows.
   * If hideCheckboxColumn is true, then #selectedRecords cannot be set (and will always return an empty array).
   */
  set selectedRecords(selectedRecordIds) {
    if (this.hideCheckboxColumn) {
      return;
    }

    if (this.grid) {
      if (this.grid.selectedRecords.length !== this._selectedRecordIdSet.size) {
        this._selectedRecordIdSet = new Set(this.grid.selectedRecords.map(record => record.id));
      }
      if (
        (selectedRecordIds.length === 0 && this.grid.selectedRecords.length === 0) ||
        (selectedRecordIds?.length > 0 &&
          this.grid.selectedRecords?.length > 0 &&
          selectedRecordIds.every(id => this._selectedRecordIdSet.has(id)))
      ) {
        return;
      }
      this.grid.selectedRecords = selectedRecordIds;
      this._selectedRecordIdSet = new Set(this.grid.selectedRecords.map(record => record.id));
    } else {
      this._selectedRecords = selectedRecordIds;
    }
  }

  /**
   * An object containing the grid's data. Parent component can dynamically add, get, and remove data using
   * the corresponding Store#add(Object record), Store#getById(String id), Store#remove(Object record)
   * functions. Changes to the store should be reflected in the griimmediately without the need
   * for any follow-up function calls.
   *
   * More information can be found here: https://www.bryntum.com/docs/grid/api/Core/data/Store
   */
  @api
  get rowDataStore() {
    if (!this._rowDataStore) {
      this.instantiateRowDataStore([]);
    }

    return this._rowDataStore;
  }

  set rowDataStore(newData) {
    let dataToUse = newData;

    if (newData.dataStoreId) {
      dataToUse = this.gridDataStore.retrieve(newData.dataStoreId);
    }

    const updatedData = Array.isArray(dataToUse) ? dataToUse : [];
    if (this.isBryntumLoaded && this._rowDataStore) {
      this._rowDataStore.data = [...updatedData];
    }
  }

  /**
   * An object containing the grid's columns. Parent component can dynamically add, get, and remove columns using
   * the corresponding ColumnStore#add(Object column), ColumnStore#getById(String id),
   * and ColumnStore#remove(Column column) functions. Changes to the store should be reflected in the grid
   * immediately without the need for any follow-up function calls.
   *
   * More information can be found here: https://www.bryntum.com/docs/grid/api/Grid/data/ColumnStore
   */
  @api
  get columnStore() {
    return this.grid?.columns ?? this._columns;
  }

  set columnStore(columns) {
    this._columns = columns;
    this._decorateColumns(columns);
    this.grid?.columns.removeAll();
    this.grid?.columns.add(columns);
  }

  _decorateColumns(columns) {
    columns.forEach((column) => {
      if(column.type === 'date' && !column.renderer) {
        column.renderer = (renderData) => {
          const {value} = renderData;
          if(!value) {
            return '';
          }
          return VeevaDateHelper.format(bryntum.grid.DateHelper.parse(value), column.sfDisplayType);
        };
      }
    });
  }

  /**
   * The fields that our Bryntum Grid Store will be aware of.
   */
  @api
  get modelFields() {
    return this._modelFields;
  }

  /**
   * Updates the Model class used by our store to be aware of the fields provided.
   *
   * By default the Bryntum Grid reads the first row to determine which fields are available for the Store.
   * By providing model fields this enables the Bryntum Grid's Store to be aware of all of the different fields.
   *
   * Model documentation https://bryntum.com/products/grid/docs/api/Core/data/Model
   */
  set modelFields(value) {
    // We will only update model fields and the store's modelClass if the incoming value is an array
    if (Array.isArray(value)) {
      // When modelFields are objects we will create a copy of the object, if it is a string we will copy the string as it is
      this._modelFields = [...value].map(field => (typeof field === 'string' ? field : { ...field }));
    }

    // We will only update modelClass if bryntum is loaded and grid is available
    if (this.isBryntumLoaded && this.grid?.store) {
      this.grid.store.modelClass = createModelClass(this._modelFields);
    }
  }

  /**
   * Gets/Sets the horizontal scroll position of the grid if horizontal scrolling is enabled.
   */
  @api
  get scrollX() {
    return this.grid?.scrollable?.x;
  }

  set scrollX(x) {
    if (this.grid?.scrollable?.x != null) {
      this.grid.scrollable.x = x;
    }
  }

  /**
   * Gets/Sets the vertical scroll position of the grid if vertical scrolling is enabled.
   */
  @api
  get scrollY() {
    return this.grid?.scrollable?.y;
  }

  set scrollY(y) {
    if (this.grid?.scrollable?.y != null) {
      this.grid.scrollable.y = y;
    }
  }

  /**
   * Applies Veeva Messages to the grid to translate any help text rendered by Bryntum.
   */
  @api localeBuilder = new VeevaBryntumLocaleBuilder()
    .withUserLocale(this.userLangLocale)
    .withLocaleConfigName(this.userLangLocale)
    .withFirstDayOfWeek(FIRST_DAY_OF_WEEK - 1);

  grid;
  isBryntumLoaded = false;
  _columns;
  _rowDataStore;
  _modelFields = [];
  _selectedRecords = [];
  _messageSvc;
  _selectedRecordIdSet = new Set();

  get selectionMode() {
    return this.hideCheckboxColumn
      ? {}
      : {
          row: true,
          checkbox: {
            locked: true,
            id: 'selection-column',
            resizable: false,
            groupable: false,
            draggable: false,
            hideable: false,
          },
          showCheckAll: true,
          rowCheckboxSelection: true,
        };
  }

  /**
   * Defines both standard Bryntum events and custom events to listen for at the top-level grid component.
   */
  get eventListeners() {
    return {
      rowaction: event => this.handleRowAction(event),
      selectionChange: event => this.handleSelectionChange(event),
      renderRows: event => this.handleRenderRows(event),
    };
  }

  /**
   * Defines the standard Bryntum events to listen for at the top-level data store component.
   */
  get storeEventListeners() {
    return {
      beforeSort: event => this.handleBeforeSort(event),
      filter: event => this.handleFilter(event),
      sort: event => this.handleSort(event),
    };
  }

  /**
   * Concatenates the user's language and locale. Language typically defines the translation of names (e.g. days, months, etc.)
   * while locale defines the formatting of dates, times, and numbers.
   */
  @api
  get userLangLocale() {
    if (this._userLangLocale == null) {
      this._userLangLocale = VeevaLocaleHelper.getUserLanguageLocale();
    }

    return this._userLangLocale;
  }

  /**
   * Renders the Bryntum Grid and attaches it to this component's div.grid-container element. Also instantiates
   * #rowDataStore and #columnStore using the corresponding function arguments.
   *
   * @param {Array} data - Array of objects to be used to create the #rowDataStore. After this function is called,
   * any changes to the grid's data should be made using the #rowDataStore field.
   * @param {Array} columns - Array of objects to be used to create the #columnStore. After this function is
   * called, any changes to the grid's columns should be made using the #columnStore field.
   */
  @api
  async renderGrid(data, columns) {
    // We will set the columns coming in here since it's possible for columnStore to be updated
    // before the resources have loaded, so we will only use the columns passed in if columnStore
    // has not been updated by the parent element
    this._columns = columns;
    await this.loadResources();

    this.instantiateRowDataStore(data);

    // protect against empty columns parameter causing Bryntum failure on first load
    if (!this._columns || this._columns.length === 0) {
      this._columns = [{ id: '', field: '', text: '' }];
    } 

    this.grid = new bryntum.grid.Grid({
      appendTo: this.template.querySelector('div.grid-container'),
      selectionMode: this.selectionMode,
      columns: this._columns,
      store: this._rowDataStore,
      features: this.features,
      selectedRecords: this._selectedRecords,
      listeners: this.eventListeners,
    });

    await this.localizeGrid();
  }

  /**
   * Applies a filter to the specified column if the filter feature is enabled.
   *
   * @param {String} columnId - ID associated with the column to filter.
   * @param {Object} value - The value to filter records against.
   * @param {String} operator - The operation to apply to the filter. See
   * https://www.bryntum.com/docs/grid/api/Core/util/CollectionFilter#config-property for more information.
   *
   */
  @api
  filter(columnId, value, operator) {
    if (this.isBryntumLoaded && this.grid) {
      const column = this.columnStore.getById(columnId);
      if (this.features.filter && column) {
        this.grid.features.filter.applyFilter(column, { value, operator });
      }
    }
  }

  /**
   * Applies a sort to the specified properties if the sort feature is enabled.
   *
   * @param {Array} sortConfig - Field to sort by. Can also be an array of sorter config objects, or a sorting function, or a sorter config.
   * @param {Boolean} ascending - (Optional) Sort order, only applicable when sortConfig is a String, or an Object without ascending defined within. Always true for functions.
   * @param {Boolean} add - (Optional) If true, adds a sorter to the sorters collection. Not applicable when field is an array. In this case always replaces active sorters.
   * @param {Boolean} silent - (Optional) Set as true to not fire events. UI will not be informed about the changes.
   * 
   * See https://www.bryntum.com/docs/grid/api/Core/data/mixin/StoreSort#function-sort for more information.
   */
  @api
  sort(sortConfig, ascending, add, silent) {
    if (this.isBryntumLoaded && this.grid?.features.sort && sortConfig) {
      this._rowDataStore.sort(sortConfig, ascending, add, silent);
    }
  }
  
  /**
   * Disables filter tooltips if filter feature is enabled.
   */
  @api
  disableFilterTooltips() {
    const filterTooltip = this.grid?.features?.filter?.filterTip;
    if (filterTooltip) {
      filterTooltip.getHtml = () => '';
    }
  }

  /**
   * Clears all filters if the filter feature is enabled.
   */
  @api
  clearFilters() {
    if (this.isBryntumLoaded && this.features.filter && this.grid?.store) {
      this.grid.store.clearFilters();
    }
  }

  /**
   * Forces a rerender of the grid with the specified records added, updated, and/or removed. Should not be necessary when each column has a
   * 1 to 1 mapping to a record's field.
   *
   * @param {Object} changes - Object containing some combination of the following three keys: 'added', 'updated', and 'removed'.
   * The value associated with each key should be an Array of objects representing the records to be added, updated, and/or removed.
   * For example, the following 'changes' arg would add a new record for Bob Jones, update an existing record's name to 'Sarah Jones', and remove a record:
   * {
   *   added: [
   *     { id: 5, name: 'Bob Jones' }
   *   ],
   *   updated: [
   *     { id: 1, name: 'Sarah Jones' }
   *   ],
   *   removed: [
   *     { id: 4 }
   *   ]
   * }
   * See https://www.bryntum.com/docs/grid/api/Core/data/mixin/StoreChanges#function-applyChangeset for more information.
   */
  @api
  applyChangeset(changes) {
    if (this.isBryntumLoaded) {
      this.grid.store.applyChangeset(changes);
      this.reapplySort();
      this.reapplyFilters();
    }
  }

  /**
   * Removes all rows inside of the grid store.
   */
  @api
  removeAllRows() {
    this.grid?.store.removeAll();
  }

  @api
  getRows(isSorted, shouldApplyFilters) {
    if (!this.isBryntumLoaded) {
      return [];
    }

    if (isSorted) {
      if (shouldApplyFilters) {
        // store.records are the visible records that include filters and sorting applied to the store
        return [...this.grid.store.records];
      }
      // store.allRecords are all of the records with sorting applied to the store
      return [...this.grid.store.allRecords];
    }

    if (shouldApplyFilters) {
      const storeConfig = {
        data: this.grid.store.data,
        filters: this.grid.store.filters,
        useRawData: this.useRawData,
      };
      // If modelFields are already defined then we will go ahead and set the modelClass for our Store copy
      if (this.modelFields.length > 0) {
        storeConfig.modelClass = createModelClass(this.modelFields);
      }
      const storeWithOriginalDataCopy = new bryntum.grid.Store(storeConfig);
      return [...storeWithOriginalDataCopy.records];
    }
    // store.data is the original data passed in this includes the original sorting and no filters
    return [...this.grid.store.data];
  }

  reapplySort() {
    this.sort(this.grid.store.sorters);
  }

  reapplyFilters() {
    if (this.features.filter) {
      this.grid.store.filter();
    }
  }

  instantiateRowDataStore(data) {
    const storeConfiguration = {
      data: [...data],
      useRawData: this.useRawData,
      listeners: this.storeEventListeners,
    };
    if (this.sensitivity) {
      storeConfiguration.useLocaleSort = {
        sensitivity: this.sensitivity,
      };
    }
    this._rowDataStore = new bryntum.grid.Store(storeConfiguration);
    // If modelFields are already defined then we will go ahead and set the modelClass for our Store
    if (this.modelFields.length > 0) {
      this._rowDataStore.modelClass = createModelClass(this.modelFields);
    }
  }

  async connectedCallback() {
    this._messageSvc = getService('messageSvc');
    await this.loadResources();
  }

  async loadResources() {
    if (this.isBryntumLoaded) {
      return;
    }

    try {
      await Promise.all([loadScript(this, `${GRID}/grid.lwc.module.min.js`), loadStyle(this, `${GRID}/grid.stockholm.min.css`)]);
      this.isBryntumLoaded = true;
      loadAllCustomWidgets(bryntum.grid);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(`Error creating veevaBryntumGrid: ${error}`);
    }
  }

  async localizeGrid() {
    const labels = await this._messageSvc.getMessageMap(this.localeBuilder.defaultMessageRequest);
    // The Grid is using an older Bryntum version than the Calendar or SchedulerPro. As a result, we need to wrap the locale config in
    // an additional object with a `locale` property.
    const localeConfig = {
      locale: this.localeBuilder
        .withLabels(labels)
        .withDefaultLocaleConfig(this.grid.localeManager.locales.En)
        .build(),
    };
    this.grid.localeHelper.publishLocale(localeConfig);
    this.grid.localeManager.applyLocale(this.userLangLocale);
  }

  handleRowAction(event) {
    this.dispatchEvent(
      new CustomEvent('rowaction', {
        detail: {
          row: event.row,
          action: {
            name: event.action.name,
          },
        },
      })
    );
  }

  /**
   * Handles selectionChange event, which is fired when user selects or deselects row(s).
   */
  handleSelectionChange(event) {
    this.dispatchEvent(
      new CustomEvent('selectionchange', {
        detail: {
          action: event.action, // Either 'select' or 'deselect'
          deselected: event.deselected, // The records that were deselected (if any)
          selected: event.selected, // The records that were selected (if any)
          selection: event.selection, // All records that are selected after the current selection/deselection action
        },
      })
    );
  }

  /**
   * Handles before-sort event, which is fired when the data store is sorted, whether that's from the application
   * of the default sort conditions on grid load or when a user clicks an individual grid column.
   */
  handleBeforeSort(event) {
    this.dispatchEvent(
      new CustomEvent('beforesort', {
        detail: {
          sorters: event.sorters
        }
      })
    );
  }

  /**
   * Handles filter event, which is fired when the data store is filtered (either programatically or by the user).
   *
   * Note that the `filters` property is a Bryntum Collection object. See https://www.bryntum.com/docs/grid/api/Core/util/Collection for details.
   */
  handleFilter(event) {
    this.dispatchEvent(
      new CustomEvent('filter', {
        detail: {
          filters: event.filters, // Collection of all currently-applied filters after this operation
          removed: event.removed, // The records that were filtered out by this operation
          added: event.added, // The records that were filtered back in by this operation
          records: event.records, // All records that are included after this operation
        },
      })
    );
  }

  /**
   * Handles renderRows event, which is fired when the grid's rows have been rendered.
   */
  handleRenderRows(event) {
    this.dispatchEvent(
      new CustomEvent('renderrows', {
        detail: {
          source: event.source, // The grid element
        },
      })
    );
  }

  /**
   * Handles sort event on the store, which is fired after the sort is executed
   */
  handleSort(event) {
    this.dispatchEvent(
      new CustomEvent('sort', {
        detail: {
          source: event.source,
          sorters: event.sorters,
          records: event.records,
        },
      })
    );
  }
}