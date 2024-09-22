import ReferenceController from 'c/referenceController';
import PicklistController from 'c/picklistController';
import FieldController from 'c/fieldController';
import BooleanController from 'c/booleanController';
import VeevaSectionController from 'c/veevaSectionController';
import VeevaBaseController from 'c/veevaBaseController';
import VeevaSideBarController from 'c/veevaSideBarController';

export default class ControllerFactory {
  static itemController = (item, pageCtrl, record) => {
    let result;
    if (item.field) {
      const field = pageCtrl.objectInfo.getFieldInfo(item.field);
      if (field && field.dataType) {
        switch (field.dataType) {
          case 'Reference':
            result = new ReferenceController(item, pageCtrl, field, record);
            break;
          case 'Boolean':
            result = new BooleanController(item, pageCtrl, field, record);
            break;
          case 'Picklist':
          case 'MultiPicklist':
            result = new PicklistController(item, pageCtrl, field, record);
            break;
          default:
            result = new FieldController(item, pageCtrl, field, record);
        }
      }
    }
    return result || new VeevaBaseController(item, pageCtrl, record);
  };

  static sectionController = (meta, pageCtrl) => new VeevaSectionController(meta, pageCtrl);
  static sideBarController = (meta, pageCtrl) => new VeevaSideBarController(meta, pageCtrl);
}