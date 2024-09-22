import { getService} from 'c/veevaServiceFactory';
import ListDefinition from './request/listDefinition';
import ViewDefinition from './request/viewDefinition';
import UniqueFieldName from './model/uniqueFieldName';

export default class MyAccountsDataService {
  static GENERATE_VIEW_ENDPOINT = '/api/v2/accounts/views';
  static GENERATE_LIST_ENDPOINT = '/api/v2/accounts/lists';

  dataSvc;
  totalMatchingRows;

  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  async getViewData(viewDefinition, territories, groupIds, selectedTerritory, defaultTerritory) {
    let viewData;
    switch (viewDefinition.type) {
      case 'VIEW':
        viewData = await this.getDataForView(viewDefinition, territories, groupIds, selectedTerritory, defaultTerritory);
        break;
      case 'ACCOUNT_LIST':
        viewData = await this.getDataForList(viewDefinition, territories, groupIds, selectedTerritory, defaultTerritory);
        break;
      default:
        viewData = [];
        break;
    }
    return viewData;
  }

  async getDataForView(viewDefinition, territories, groupIds, selectedTerritory, defaultTerritory) {
    const viewData = await this.dataSvc.sendRequest(
      'POST',
      MyAccountsDataService.GENERATE_VIEW_ENDPOINT,
      {},
      {
        view: new ViewDefinition(viewDefinition),
        territories: territories.map(territory => ({
          id: territory.id,
          name: territory.name,
        })),
        defaultTerritory,
        selectedTerritory,
        groupIds: groupIds ?? [],
      }
    );
    this.totalMatchingRows = viewData?.data?.totalMatchingRows;
    return viewData?.data?.rows ?? [];
  }

  async getDataForList(listDefinition, territories, groupIds, selectedTerritory, defaultTerritory) {
    const listData = await this.dataSvc.sendRequest(
      'POST',
      MyAccountsDataService.GENERATE_LIST_ENDPOINT,
      {},
      {
        view: new ListDefinition(listDefinition),
        territories: territories.map(territory => ({
          id: territory.id,
          name: territory.name,
        })),
        defaultTerritory,
        selectedTerritory,
        groupIds: groupIds ?? [],
      }
    );
    this.totalMatchingRows = listData?.data?.totalMatchingRows;
    return listData?.data?.rows ?? [];
  }

  async getOrderTypeInfoByAccounts(accountIds) {
    const dataService = getService('dataSvc');
    const queryParameters = `acctIds=${accountIds.join('&acctIds=')}`;
    const orders = await dataService.sendRequest('GET', '/api/v1/account-order-type-info', queryParameters, null, 'accountOrderTypeInfo');
    return orders;
  }
}

export { UniqueFieldName };