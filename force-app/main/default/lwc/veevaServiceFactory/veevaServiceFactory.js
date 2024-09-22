import Container from 'c/container';
import VeevaSessionService from 'c/veevaSessionService';
import VeevaUserInterfaceAPI from 'c/veevaUserInterfaceAPI';
import VeevaDataService from 'c/veevaDataService';
import VeevaMessageService from 'c/veevaMessageService';
import BaseDataService from 'c/baseDataService';
import VeevaMetaStore from 'c/veevaMetaStore';
import VeevaMetricsSender from 'c/veevaMetricsSender';
import VeevaApplicationMetricsService from 'c/veevaApplicationMetricsService';
import VeevaBypassProxyDataStore from 'c/veevaBypassProxyDataStore';

export const SERVICES = Object.freeze({
  BASE_DATA: 'baseDataService',
  DATA: 'dataSvc',
  MESSAGE: 'messageSvc',
  META: 'metaStore',
  SESSION: 'sessionSvc',
  UI_API: 'userInterfaceSvc',
  METRIC_SENDER: 'metricsSender',
  APP_METRIC_SERVICE: 'applicationMetricsSvc',
  BYPASS_PROXY_DATA_STORE: 'bypassProxyDataStore'
});

const _container = Container.SERVICES;
_container.singleton(SERVICES.SESSION, VeevaSessionService);
_container.singleton(SERVICES.DATA, VeevaDataService, [SERVICES.SESSION]);
_container.singleton(SERVICES.UI_API, VeevaUserInterfaceAPI);
_container.singleton(SERVICES.BASE_DATA, BaseDataService, [SERVICES.DATA]);
_container.singleton(SERVICES.MESSAGE, VeevaMessageService);
_container.singleton(SERVICES.META, VeevaMetaStore, [SERVICES.UI_API]);
_container.singleton(SERVICES.METRIC_SENDER, VeevaMetricsSender, [SERVICES.SESSION]);
_container.singleton(SERVICES.APP_METRIC_SERVICE, VeevaApplicationMetricsService, [SERVICES.METRIC_SENDER, SERVICES.SESSION]);
_container.singleton(SERVICES.BYPASS_PROXY_DATA_STORE, VeevaBypassProxyDataStore);

export const getService = name => _container.get(name);

export default getService;