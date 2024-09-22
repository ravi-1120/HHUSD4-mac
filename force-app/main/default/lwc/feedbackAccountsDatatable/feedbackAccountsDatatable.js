import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import { loadStyle } from 'lightning/platformResourceLoader';
import feedbackAccountsDatatableStyleOverride from '@salesforce/resourceUrl/feedbackAccountsDatatableStyleOverride';
import buildAccountRecordFieldTranslator from 'c/accountRecordFieldTranslator';
import TerritoryFeedbackConstants, { CHALLENGE_STATUSES } from 'c/territoryFeedbackConstants';
import BaseColumnArray, { COLUMN_IDS } from './columns/baseColumnArray';
import GoalColumnArray from './columns/goalColumnArray';
import AccountDetailsColumnArray from './columns/accountDetailsColumnArray';
import ProductMetricColumnArray from './columns/productMetricColumnArray';
import SegmentColumnArray from './columns/segmentColumnArray';

const OPERATOR = {
  CONTAINS: '*',
  GREATER_THAN: '>',
};
const FILTER_NAME_TO_FILTER_ARGS = new Map([
  [TerritoryFeedbackConstants.TARGETS, [COLUMN_IDS.TARGET, true, OPERATOR.CONTAINS]],
  [TerritoryFeedbackConstants.ALL_CHALLENGES, [COLUMN_IDS.HAS_CHALLENGE, true, OPERATOR.CONTAINS]],
  [TerritoryFeedbackConstants.PENDING_CHALLENGES, [COLUMN_IDS.CHALLENGE_STATUS, CHALLENGE_STATUSES.CHALLENGED, OPERATOR.CONTAINS]],
  [TerritoryFeedbackConstants.BUSINESS_ACCOUNTS, [COLUMN_IDS.PERSON, false, OPERATOR.CONTAINS]],
  [TerritoryFeedbackConstants.PERSON_ACCOUNTS, [COLUMN_IDS.PERSON, true, OPERATOR.CONTAINS]],
]);
const ACCT_NAME_FIELD = 'name';
const TARGET_FIELD = 'target';
const LOCATION_FIELD = 'location.name';

// Changing any of the files in `./columns` without also touching this file could result in build failure.

export default class FeedbackAccountsDatatable extends LightningElement {
  @api accountsTableDetailsRecord;
  @api selectedAccountsFilter;

  @api
  get selectedAccounts() {
    return this.gridElement?.selectedRecords.map(record => record.originalData) ?? this._selectedRecords;
  }

  set selectedAccounts(selectedAccountIds) {
    if (this.gridElement) {
      this.gridElement.selectedRecords = selectedAccountIds;
    } else {
      this._selectedRecords = selectedAccountIds;
    }
  }

  @api
  applyChangeset(changes) {
    this.storeScrollState();
    this.gridElement?.applyChangeset(changes);
    this.restoreScrollState();
  }

  @api
  resetFiltersAndSort() {
    this.clearFilters();
    this.applyDefaultSort();
  }

  @api
  filter(columnId, filterValue, filterOperator) {
    this.gridElement?.filter(columnId, filterValue, filterOperator);
  }

  @api
  clearFilters() {
    this.gridElement?.clearFilters();
  }

  messageSvc;
  messages;
  columns = [];
  useRawData = true;
  hideCheckboxColumn;
  accountRecordFieldTranslator;
  // Only used upon instantiation of VeevaBryntumGrid to ensure that selected rows are passed from parent to VeevaBryntumGrid
  _selectedRecords = [];
  scrollState = { x: 0, y: 0 };

  get gridElement() {
    return this.template.querySelector('c-veeva-bryntum-grid');
  }

  async connectedCallback() {
    this.messageSvc = getService('messageSvc');
    await this.loadMessages();
    await this.loadResources();
    await this.instantiateFieldTranslator();
    await this.instantiateColumns();
    await this.renderGrid();
    this.applyDefaultFilter();
    this.applyDefaultSort();
  }

  async loadMessages() {
    this.messages = await this.messageSvc
      .createMessageRequest()
      .addRequest('ACCOUNT_ASSIGNMENTS', 'Feedback', 'Account Assignments', 'accountAssignments')
      .addRequest('DROPS', 'Feedback', 'Drops', 'drops')
      .sendRequest();
  }

  async loadResources() {
    // See file `feedbackAccountsDatatableStyleOverride.resource` to update styling for datatable cell contents
    await loadStyle(this, feedbackAccountsDatatableStyleOverride);
  }

  async instantiateFieldTranslator() {
    this.accountRecordFieldTranslator = await buildAccountRecordFieldTranslator(this.gridElement?.userLangLocale);
  }

  async instantiateColumns() {
    const nestedColumnArray = [];

    nestedColumnArray.push(BaseColumnArray.createColumns(this.accountRecordFieldTranslator, this.accountsTableDetailsRecord));

    if (this.accountsTableDetailsRecord.cyclePresent) {
      nestedColumnArray.push(GoalColumnArray.createColumns(this.accountRecordFieldTranslator, this.accountsTableDetailsRecord));
    }

    if (this.accountsTableDetailsRecord.accountDetailMetadata.length > 0) {
      nestedColumnArray.push(AccountDetailsColumnArray.createColumns(this.accountRecordFieldTranslator, this.accountsTableDetailsRecord));
    }

    if (this.accountsTableDetailsRecord.productMetricMetadata.length > 0) {
      nestedColumnArray.push(ProductMetricColumnArray.createColumns(this.accountRecordFieldTranslator, this.accountsTableDetailsRecord));
    }

    if (this.accountsTableDetailsRecord.cyclePresent) {
      nestedColumnArray.push(SegmentColumnArray.createColumns(this.accountRecordFieldTranslator, this.accountsTableDetailsRecord));
    }

    const resolvedNestedColumnArray = await Promise.all(nestedColumnArray);
    this.columns = resolvedNestedColumnArray.flat();
  }

  async renderGrid() {
    this.features = this.getFeatures();

    // Checkbox column should only be enabled when user has ability to approve/reject challenges 
    this.hideCheckboxColumn = !this.accountsTableDetailsRecord.canReview;

    // Spread operator dramatically improves rendering time for larger arrays
    await this.gridElement?.renderGrid([...this.accountsTableDetailsRecord.accounts], this.columns);

    this.gridElement?.disableFilterTooltips();
  }

  getFeatures() {
    return {
      group: {
        field: 'originalData.isAssignedToTerritory',
        renderer: ({ groupRowFor, isFirstColumn }) => this.rowGroupHeaderRenderer(groupRowFor, isFirstColumn),
        groupSortFn: this.rowGroupSorter,
      },
      filter: {
        prioritizeColumns: true,
      },
      sort: {
        // Disables multisort controls on columns
        multiSort: false,
        // Respects sortable definitions on column definitions when sorting programmatically
        prioritizeColumns: true,
      },
      cellEdit: false,
      headerMenu: {
        items: {
          // Hide 'Stop grouping'
          groupRemove: false,
        },
      },
      cellMenu: {
        disabled: true,
      },
    };
  }

  rowGroupHeaderRenderer(isAssignedToTerritory, isFirstColumn) {
    if (!isFirstColumn) {
      return '';
    }

    return isAssignedToTerritory ? this.messages.accountAssignments : this.messages.drops;
  }

  // eslint-disable-next-line class-methods-use-this
  rowGroupSorter(record1, record2) {
    // Within groups we want to sort by the selected column sort. Returning `null` tells Bryntum to sort by column instead of row group. 
    if (record1.originalData.isAssignedToTerritory === record2.originalData.isAssignedToTerritory) {
      return null;
    }

    // Otherwise, we want to sort AccountRecords into 2 row groups. In this case, we want to display the `isAssignedToTerritory === true` group first.
    return record1.originalData.isAssignedToTerritory ? -1 : 1;
  }

  // Sets an initial filter value based on user's entry point from FieldForceModelsPage
  applyDefaultFilter() {
    if (this.selectedAccountsFilter) {
      // If the selected filter is not a named filter, it is a channel or product ID
      const filterArgs = FILTER_NAME_TO_FILTER_ARGS.get(this.selectedAccountsFilter) ?? [this.selectedAccountsFilter, 0, OPERATOR.GREATER_THAN];
      this.gridElement.filter(...filterArgs);
    }
  }

  // Applies a default multisort with a primary sort on Target, secondary sort on Account 
  // Name, and tertiary sort on Location Name (if location-based targeting is enabled)
  applyDefaultSort() {
    const sortConfig = [];

    if (this.accountsTableDetailsRecord.cyclePresent) {
      sortConfig.push(
        { field: TARGET_FIELD, ascending: true }
      );
    }

    sortConfig.push(
      { field: ACCT_NAME_FIELD, ascending: true }
    );

    if (this.accountsTableDetailsRecord.locationBasedTargeting) {
      sortConfig.push(
        { field: LOCATION_FIELD, ascending: true }
      );
    }

    this.gridElement.sort(sortConfig);
  }

  // Applies a programmatic multi-feature sort on the Accounts grid
  // if the user interacts with the column-based sorting controls.
  handleBeforeSort(event) {
    const { sorters } = event.detail;

    if (sorters?.length > 0 && sorters[0].columnOwned) {
      const primarySorter = sorters[0];
      const sortConfig = [];
      if (primarySorter.field === TARGET_FIELD) {
        // Primary sort on Target, secondary sort on Account Name
        sortConfig.push(
          { field: TARGET_FIELD, ascending: primarySorter.ascending }, 
          { field: ACCT_NAME_FIELD, ascending: true}
        );
        // Tertiary sort on Location Name if LBT is enabled
        if (this.accountsTableDetailsRecord.locationBasedTargeting) {
          sortConfig.push(
            { field: LOCATION_FIELD, ascending: true }
          );
        }
      } else if (primarySorter.field === ACCT_NAME_FIELD && this.accountsTableDetailsRecord.locationBasedTargeting) {
        // Primary sort on Account Name, secondary sort on Location Name if LBT is enabled
        sortConfig.push(
          { field: ACCT_NAME_FIELD, ascending: primarySorter.ascending },
          { field: LOCATION_FIELD, ascending: true }
        );
      }          

      // Apply the sorting configuration to the grid if populated
      if (sortConfig.length > 0) {
        this.gridElement.sort(sortConfig, null, null, false);
      }
    }
  }
  
  // Bubbles events from Bryntum Grid up to parent LWC
  handleRowAction(event) {
    if (this.accountsTableDetailsRecord.canReview || this.accountsTableDetailsRecord.canChallenge) {
      this.dispatchEvent(
        new CustomEvent('rowaction', {
          detail: {
            row: event.detail.row,
            action: {
              name: event.detail.action.name,
            },
          },
        })
      );
    }
  }

  handleSelectionChange(event) {
    if (this.accountsTableDetailsRecord.canReview || this.accountsTableDetailsRecord.canChallenge) {
      this.dispatchEvent(
        new CustomEvent('selectionchange', {
          detail: {
            numSelected: event.detail.selection.length,
          },
        })
      );
    }
  }

  handleFilter(event) {
    this.dispatchEvent(
      new CustomEvent('filter', {
        detail: {
          numFilters: event.detail.filters.totalCount,
        },
      })
    );
  }

  handleRenderRows() {
    this.dispatchEvent(new CustomEvent('renderrows'));
  }

  storeScrollState() {
    this.scrollState = { x: this.gridElement?.scrollX, y: this.gridElement?.scrollY };
  }

  restoreScrollState() {
    ({ x: this.gridElement.scrollX, y: this.gridElement.scrollY } = this.scrollState);
  }
}

export { COLUMN_IDS, OPERATOR };