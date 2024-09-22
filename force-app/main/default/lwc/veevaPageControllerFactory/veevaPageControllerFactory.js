// will replace veevaPageControllerFactory.js under /main during deployment
import Container from 'c/container';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaPageController from 'c/veevaPageController';
import MedicalInquiryController from 'c/medicalInquiryController';
import AccountPlanCloneController from 'c/accountPlanCloneController';
import MedicalInsightController from 'c/medicalInsightController';
import DocumentedInterestController from 'c/documentedInterestController';
import ScientificInterestController from 'c/scientificInterestController';
import MyInsightsController from 'c/myInsightsController';

const dataSvc = getService(SERVICES.DATA);
const userInterfaceSvc = getService(SERVICES.UI_API);
const messageSvc = getService(SERVICES.MESSAGE);
const sessionSvc = getService(SERVICES.SESSION);
const metaStore = getService(SERVICES.META);
const appMetricsService = getService(SERVICES.APP_METRIC_SERVICE);
const PAGE_CONTROLLER_ARGS = [dataSvc, userInterfaceSvc, messageSvc, metaStore, appMetricsService];

const _container = Container.PAGE_CONTROLLERS;
_container.register('pageCtrl', VeevaPageController, PAGE_CONTROLLER_ARGS);
_container.register('Medical_Inquiry_vod__c', MedicalInquiryController, PAGE_CONTROLLER_ARGS);
_container.register('Documented_Interest_vod__c', DocumentedInterestController, PAGE_CONTROLLER_ARGS);
_container.register('Scientific_Interest_vod__c', ScientificInterestController, PAGE_CONTROLLER_ARGS);
_container.register('HTML_Report_vod__c--MyInsights', MyInsightsController, [dataSvc, userInterfaceSvc, messageSvc, sessionSvc, metaStore, appMetricsService]);

_container.register('Account_Plan_vod__c--CLONE', AccountPlanCloneController, PAGE_CONTROLLER_ARGS);
_container.register('Medical_Insight_vod__c', MedicalInsightController, PAGE_CONTROLLER_ARGS);

const getPageController = name => {
  let pageController = _container.get(name);
  if (!pageController) {
    pageController = getService(name);
  }

  if (!pageController) {
    pageController = _container.get('pageCtrl'); // fallback to pageCtrl
  }
  
  return pageController;
};

// eslint-disable-next-line import/prefer-default-export
export { getPageController };