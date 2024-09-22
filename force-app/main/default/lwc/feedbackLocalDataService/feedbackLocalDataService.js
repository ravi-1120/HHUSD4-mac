import AccountsTableDetailsRecord from 'c/accountsTableDetailsRecord';
import TerritoryModelDetails from './models/territoryModelDetails';

export default class FeedbackLocalDataService {
  _territoryModelDetails;
  _territoryModelDetailsStoreId;

  constructor(accountsTableDetails) {
    this._territoryModelDetails = accountsTableDetails instanceof AccountsTableDetailsRecord ? new TerritoryModelDetails(accountsTableDetails) : null;
    this._territoryModelDetailsStoreId = null;
  }

  get territoryModelDetails() {
    return this._territoryModelDetails;
  }

  get territoryModelDetailsStoreId() {
    return this._territoryModelDetailsStoreId;
  }

  set territoryModelDetailsStoreId(storeId) {
    this._territoryModelDetailsStoreId = storeId;
  }
}