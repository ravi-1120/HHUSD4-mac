public class VeevaExpenseTriggerHandler extends VeevaTriggerHandler {
    @TestVisible private List<Expense_vod__c> oldExpenses;
    @TestVisible private List<Expense_vod__c> newExpenses;
    @TestVisible private Map<ID, Expense_vod__c> oldExpensesMap;

        
    @TestVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        oldExpenses = (List<Expense_vod__c>) triggerOld;
        newExpenses = (List<Expense_vod__c>) triggerNew;
        oldExpensesMap = (Map<ID, Expense_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'Expense_vod__c ';
    }
    
    protected override void beforeDelete() {
        checkLockedCall(oldExpenses);
    }

    protected override void beforeUpdate() {
        checkLockedCall(newExpenses);
    }

    protected override void afterInsert() {
        updateExpenseAmount(newExpenses);
    }

    protected override void afterUpdate() {
        updateExpenseAmount(newExpenses);
    }

    protected override void afterDelete() {
        updateExpenseAmount(oldExpenses);
    }

    private void checkLockedCall(List<Expense_vod__c> expenses) {
        Set<Id> callIds = new Set<Id>();
        for (Expense_vod__c oldExpense : oldExpenses) {
            if (oldExpense.Call2_vod__c != null) {
                callIds.add(oldExpense.Call2_vod__c);
            }      
        }
        Map<Id, Call2_vod__c> lockedCallMap = new Map<Id, Call2_vod__c>([SELECT Id FROM Call2_vod__c
                                                                        WHERE Id IN : callIds 
                                                                        AND Status_vod__c = 'Submitted_vod' 
                                                                        AND Override_Lock_vod__c != true]);

        VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE();
        String noUpdSubError = bnd.getErrorMsg('NO_UPD_SUB');
        for(SObject expense : expenses){
            Expense_vod__c oldExpense = oldExpensesMap.get(expense.Id); 
            if(expense.get('Override_Lock_vod__c') != true && oldExpense.get('Call2_vod__c') != null && lockedCallMap.keySet().contains(oldExpense.get('Call2_vod__c').toString())) {
                expense.addError(noUpdSubError);
            }
        }
    }
    
    private void updateExpenseAmount(List<Expense_vod__c> expenses) {
        Map<Id, Call2_vod__c> callsToUpdate = new Map<Id, Call2_vod__c>();                                                     
        for (Expense_vod__c expense : expenses) {
            if (expense.Call2_vod__c != null) {
                callsToUpdate.put(expense.Call2_vod__c, new Call2_vod__c(Id =expense.Call2_vod__c, Expense_Amount_vod__c = null, Override_lock_vod__c = true));
            }    
        }

        expenses = [SELECT Call2_vod__c, Amount_vod__c FROM Expense_vod__c WHERE Call2_vod__c in :callsToUpdate.keySet() AND Amount_vod__c != null];
        for (Expense_vod__c expense : expenses) {
            if (callsToUpdate.get(expense.Call2_vod__c).Expense_Amount_vod__c == null){
                callsToUpdate.get(expense.Call2_vod__c).Expense_Amount_vod__c = expense.Amount_vod__c;
            } else {
                callsToUpdate.get(expense.Call2_vod__c).Expense_Amount_vod__c += expense.Amount_vod__c;
            }
        }
        update callsToUpdate.values();
    }
}