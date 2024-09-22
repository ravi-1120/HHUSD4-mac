import BaseButtonController from './controllers/baseButtonController';
import EventButtonController from './controllers/eventButtonController';
import EventSpeakerButtonController from './controllers/eventSpeakerButtonController';
import ExpenseHeaderButtonController from './controllers/expenseHeaderButtonController';

const getButtonController = (meta, pageCtrl) => {
  let ctrl;
  switch (pageCtrl.objectApiName) {
    case 'EM_Event_vod__c':
      ctrl = new EventButtonController(meta, pageCtrl);
      break;
    case 'EM_Event_Speaker_vod__c':
      ctrl = new EventSpeakerButtonController(meta, pageCtrl);
      break;
    case 'Expense_Header_vod__c':
      ctrl = new ExpenseHeaderButtonController(meta, pageCtrl);
      break;
    default:
      ctrl = new BaseButtonController(meta, pageCtrl);
  }
  return ctrl;
};


export default getButtonController;