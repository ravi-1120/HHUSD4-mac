import { SERVICES, getService } from 'c/veevaServiceFactory';

import AddToListController from './model/accountViewControls/addToListController';
import CreateNewListController from './model/accountViewControls/createNewListController';
import CreateNewViewController from './model/accountViewControls/createNewViewController';
import DeleteListController from './model/accountViewControls/deleteListController';
import DeleteViewController from './model/accountViewControls/deleteViewController';
import EditListController from './model/accountViewControls/editListController';
import EditViewController from './model/accountViewControls/editViewController';
import RemoveFromListController from './model/accountViewControls/removeFromListController';
import NewOrderActionController from './model/accountActionControls/newOrderActionController';
import NewAccountActionController from './model/accountActionControls/newAccountActionController';
import SendEmailActionController from './model/accountActionControls/sendEmailActionController';
import ScheduleCallActionController from './model/accountActionControls/scheduleCallActionController';

const MESSAGE_SVC = getService(SERVICES.MESSAGE);
const MESSAGE_REQUEST = MESSAGE_SVC.createMessageRequest();
const REQUIRED_OBJECT_NAMES = [];
const CUSTOM_SETTINGS = [];
const NAV_ITEMS = [];

register(AddToListController);
register(CreateNewListController);
register(CreateNewViewController);
register(DeleteListController);
register(DeleteViewController);
register(EditListController);
register(EditViewController);
register(RemoveFromListController);
register(NewOrderActionController);
register(NewAccountActionController);
register(SendEmailActionController);
register(ScheduleCallActionController);

export default class MyAccountsButtonControllerFactory {
  /**
   * Get all of the objectApiNames required by {@link MyAccountsButtonControllerFactory} to construct button controllers.
   */
  static getObjectApiNames() {
    // get unique required object names
    return [...new Set(REQUIRED_OBJECT_NAMES)];
  }

  /**
   * Get all Message Requests required by {@link MyAccountsButtonControllerFactory} to construct button controllers.
   */
  static getMessageRequest() {
    return MESSAGE_REQUEST;
  }

  /**
   * Get all Custom Settings required by {@link MyAccountsButtonControllerFactory} to construct button controllers.
   */
  static getCustomSettings() {
    return CUSTOM_SETTINGS;
  }

  /**
   * Get all Nav Items required by {@link MyAccountsButtonControllerFactory} to construct button controllers.
   */
  static getNavItems() {
    return NAV_ITEMS;
  }

  /**
   * Creates all Account View Controls button controllers.
   *
   * @param {Object} viewDefinition apex view definition that is a child class of VeevaMyAccountsBaseView
   * @param {Map<String, VeevaObjectInfo>} objectInfoMap Map of VeevaObjectInfo containing object infos for objects specified in {@link MyAccountsButtonControllerFactory.getObjectApiNames}
   * @param {Map<String, String>} messageMap contains a message map
   */
  static createAccountViewControls(viewDefinition, objectInfoMap, messageMap) {
    if (objectInfoMap == null || messageMap == null) {
      return [];
    }
    if (viewDefinition.source === 'LOCATION') {
      return [
        new CreateNewViewController(objectInfoMap, messageMap),
        new EditViewController(objectInfoMap, messageMap),
        new DeleteViewController(objectInfoMap, messageMap),
      ];
    }
    if (viewDefinition.type === 'ACCOUNT_LIST') {
      return [
        new CreateNewViewController(objectInfoMap, messageMap),
        new CreateNewListController(objectInfoMap, messageMap),
        new AddToListController(objectInfoMap, messageMap),
        new EditListController(objectInfoMap, messageMap),
        new RemoveFromListController(objectInfoMap, messageMap),
        new DeleteListController(objectInfoMap, messageMap),
      ];
    }
    return [
      new CreateNewViewController(objectInfoMap, messageMap),
      new CreateNewListController(objectInfoMap, messageMap),
      new AddToListController(objectInfoMap, messageMap),
      new EditViewController(objectInfoMap, messageMap),
      new DeleteViewController(objectInfoMap, messageMap),
    ];
  }

  /**
   * Creates all Account Action Controls button controllers.
   *
   * @param {Object} viewDefinition apex view definition that is a child class of VeevaMyAccountsBaseView
   * @param {Map<String, VeevaObjectInfo>} objectInfoMap Map of VeevaObjectInfo containing object infos for objects specified in {@link MyAccountsButtonControllerFactory.getObjectApiNames}
   * @param {Map<String, String>} messageMap contains a message map
   * @param {Map<String, any>} settings contains a settings map, String setting name to the setting value (string, number, boolean)
   * @param {Map<String, Object>} navItems contains a map of navItems by developerName see: https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_resources_all_nav_items.htm
   */
  static createAccountActionControls(viewDefinition, objectInfoMap, messageMap, settings, navItems) {
    if(viewDefinition == null && objectInfoMap == null || messageMap == null || settings == null) {
      return [];
    }

    if (viewDefinition.source === 'LOCATION') {
      return [new ScheduleCallActionController(objectInfoMap, messageMap, settings, navItems)];
    }

    // New Order and Mass Update currently un-supported.  Un-comment the following lines when they are implemented.
    return [
      new NewAccountActionController(objectInfoMap, messageMap, settings),
      new NewOrderActionController(objectInfoMap, messageMap, settings),
      new SendEmailActionController(objectInfoMap, messageMap, settings),
      new ScheduleCallActionController(objectInfoMap, messageMap, settings, navItems),
    ];
  }
}


/**
 * Registers controller classes to retrieve any static information that we need when constructing each class at runtime.
 */
function register(controllerClass) {
  controllerClass.MESSAGE_REQUEST.getMessageRequests().forEach(request => {
    MESSAGE_REQUEST.addRequest(request.key, request.category, request.defaultMessage, request.label);
  });
  controllerClass.REQUIRED_OBJECTS.forEach(requireObjectName => {
    REQUIRED_OBJECT_NAMES.push(requireObjectName);
  });
  controllerClass.CUSTOM_SETTINGS?.forEach(setting => {
    CUSTOM_SETTINGS.push(setting)
  });
  controllerClass.NAV_ITEMS?.forEach(navItem => {
    NAV_ITEMS.push(navItem)
  });
}