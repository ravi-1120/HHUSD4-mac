import EmExpenseConstant from 'c/emExpenseConstant';
import EmConcurService from 'c/emConcurService';

const isStatusSendingOrSubmitted = async (concurSvc, recordId, objectApiName = EmExpenseConstant.EXPENSE_HEADER) => {
  const concurStatus = await concurSvc?.getConcurStatus(recordId, objectApiName);
  return EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(concurStatus);
};

const addConcurStatusToQueryFields = (queryFields, concurStatus) => {
  if (!queryFields.includes(concurStatus)) {
    queryFields.push(concurStatus);
  }
  return queryFields;
};

const hideDropdownButtons = async (row, id, status, pageCtrl) => {
  if (!id || !status) {
    return false;
  }
  const concurSvc = new EmConcurService(pageCtrl.dataSvc, pageCtrl.uiApi);
  return EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(status) || isStatusSendingOrSubmitted(concurSvc, id);
};

const handleNoButtonDropdown = async (row, doneCallback, pageCtrl) => {
  const actions = [];
  const noActionsMessage = await pageCtrl.getMessageWithDefault('NO_ACTIONS', 'Common', 'No actions available');
  actions.push({ label: noActionsMessage, name: 'noActions', disabled: true });
  row.actions = actions;
  doneCallback(actions);
};

export { isStatusSendingOrSubmitted, hideDropdownButtons, addConcurStatusToQueryFields, handleNoButtonDropdown };