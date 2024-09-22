public with sharing class VeevaTerrBudgetTransactionTriggerHandler extends VeevaTriggerHandler {

    private List<Territory_Budget_Transaction_vod__c> newTerritoryBudgetTransactions = new List<Territory_Budget_Transaction_vod__c>();
    private List<Territory_Budget_Transaction_vod__c> oldTerritoryBudgetTransactions = new List<Territory_Budget_Transaction_vod__c>();
    private Map<ID, Territory_Budget_Transaction_vod__c> newTerritoryBudgetTransactionsMap = new Map<ID, Territory_Budget_Transaction_vod__c>();
    private Map<ID, Territory_Budget_Transaction_vod__c> oldTerritoryBudgetTransactionsMap = new Map<ID, Territory_Budget_Transaction_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newTerritoryBudgetTransactions = (List<Territory_Budget_Transaction_vod__c>) triggerNew;
        this.oldTerritoryBudgetTransactions = (List<Territory_Budget_Transaction_vod__c>) triggerOld;
        this.newTerritoryBudgetTransactionsMap = (Map<ID, Territory_Budget_Transaction_vod__c>) triggerNewMap;
        this.oldTerritoryBudgetTransactionsMap = (Map<ID, Territory_Budget_Transaction_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Territory_Budget_Transaction_vod__c';
    }

    protected override void afterInsert() {
        updateParentTerritoryBudgets(oldTerritoryBudgetTransactions, newTerritoryBudgetTransactions);
    }

    protected override void afterUpdate() {
        updateParentTerritoryBudgets(oldTerritoryBudgetTransactions, newTerritoryBudgetTransactions);
    }

    protected override void afterDelete() {
        updateParentTerritoryBudgets(oldTerritoryBudgetTransactions, newTerritoryBudgetTransactions);
    }

    protected override void afterUndelete() {
        updateParentTerritoryBudgets(oldTerritoryBudgetTransactions, newTerritoryBudgetTransactions);
    }

    private void updateParentTerritoryBudgets(List<Territory_Budget_Transaction_vod__c> triggerOld, List<Territory_Budget_Transaction_vod__c> triggerNew) {
        Set<String> territoryBudgetIds = new Set<String>();
        if (triggerNew != null) {
            for (Territory_Budget_Transaction_vod__c tbt : triggerNew) {
                territoryBudgetIds.add(tbt.Territory_Budget_vod__c);
            }
        }
        if (triggerOld != null) {
            for (Territory_Budget_Transaction_vod__c tbt : triggerOld) {
                territoryBudgetIds.add(tbt.Territory_Budget_vod__c);
            }
        }

        if (territoryBudgetIds.size() > 0) {
            if (MultiCurrencyUtil.isMultiCurrencyOrg()) {
                multiCurrencyOrgStrategy(territoryBudgetIds);
            } else {
                singleCurrencyOrgStrategy(territoryBudgetIds);
            }
        }
    }

    private void singleCurrencyOrgStrategy(Set<String> territoryBudgetIds) {

        Map<Id, Territory_Budget_vod__c> territoryBudgets = new Map<Id, Territory_Budget_vod__c>([SELECT Id, Start_Value_vod__c, Start_Quantity_vod__c FROM Territory_Budget_vod__c WHERE Id IN :territoryBudgetIds]);
        List<sObject> budgetCalculations = [SELECT Territory_Budget_vod__c, MAX(Transaction_Date_vod__c)maxTransactionDate, SUM(Value_vod__c)sumValue, SUM(Quantity_vod__c)sumQuantity FROM Territory_Budget_Transaction_vod__c WHERE Territory_Budget_vod__c IN :territoryBudgetIds GROUP BY Territory_Budget_vod__c];
        if (budgetCalculations.size() > 0) {
            for (sObject budgetCalculation : budgetCalculations) {
                Id budgetId = (Id)budgetCalculation.get('Territory_Budget_vod__c');
                Territory_Budget_vod__c territoryBudget = territoryBudgets.get(budgetId);
                territoryBudget.Last_Transaction_vod__c = (Date) budgetCalculation.get('maxTransactionDate');
                territoryBudget.Current_Value_vod__c = nullSafeAddition(territoryBudget.Start_Value_vod__c, (Double) budgetCalculation.get('sumValue'));
                territoryBudget.Current_Quantity_vod__c = nullSafeAddition(territoryBudget.Start_Quantity_vod__c, (Double) budgetCalculation.get('sumQuantity'));
            }
        } else {
            for (Territory_Budget_vod__c territoryBudget : territoryBudgets.values()) {
                territoryBudget.Last_Transaction_vod__c = null;
                territoryBudget.Current_Value_vod__c = null;
                territoryBudget.Current_Quantity_vod__c = null;
            }
        }
        update territoryBudgets.values();
    }

    private void multiCurrencyOrgStrategy(Set<String> territoryBudgetIds) {
        Map<Id, Territory_Budget_vod__c> territoryBudgets = queryForTerritoryBudgetsInMultiCurrencyOrg(territoryBudgetIds);
        List<Territory_Budget_Transaction_vod__c> budgetTransactions = queryForTerritoryTransactionsInMultiCurrencyOrg(territoryBudgetIds);
        aggregateTransactionValuesUnderParent(territoryBudgets, budgetTransactions);
    }

    // we can't inline CurrencyIsoCode in a SOQL query because then it won't compile in a single currency org
    private Map<Id, Territory_Budget_vod__c> queryForTerritoryBudgetsInMultiCurrencyOrg(Set<String> territoryBudgetIds) {
        String queryString = String.format('SELECT Id, Start_Value_vod__c, Start_Quantity_vod__c, CurrencyIsoCode FROM Territory_Budget_vod__c WHERE Id IN ({0})', 
            new List<Object>{'\'' + String.join(new List<String>(territoryBudgetIds), '\',\'') + '\''}
        );

        return new Map<Id, Territory_Budget_vod__c>((List<Territory_Budget_vod__c>) Database.query(queryString));
    }

    // we can't inline CurrencyIsoCode in a SOQL query because then it won't compile in a single currency org
    private List<Territory_Budget_Transaction_vod__c> queryForTerritoryTransactionsInMultiCurrencyOrg(Set<String> territoryBudgetIds) {
        String queryString =  String.format('Select Territory_Budget_vod__c, Transaction_Date_vod__c, Value_vod__c, Quantity_vod__c, CurrencyIsoCode FROM Territory_Budget_Transaction_vod__c WHERE Territory_Budget_vod__c IN ({0})', 
            new List<Object>{'\'' + String.join(new List<String>(territoryBudgetIds), '\',\'') + '\''}
        );

        return Database.query(queryString);
    }

    private void aggregateTransactionValuesUnderParent(Map<Id, Territory_Budget_vod__c> territoryBudgets, List<Territory_Budget_Transaction_vod__c> budgetTransactions) {

        // If a query includes a GROUP BY or HAVING clause, currency data returned by using an aggregate function, such as SUM() or MAX(), is in the org’s default currency.
        // Thus for multicurrency orgs we should NOT use aggregate functions and instead do the aggregation ourselves
        Map<Id, List<Territory_Budget_Transaction_vod__c>> territoryBudgetToAssociatedTransactions = new  Map<Id, List<Territory_Budget_Transaction_vod__c>>();

        for (Territory_Budget_Transaction_vod__c budgetTransaction : budgetTransactions) {
            if (territoryBudgetToAssociatedTransactions.containsKey(budgetTransaction.Territory_Budget_vod__c)) {
                territoryBudgetToAssociatedTransactions.get(budgetTransaction.Territory_Budget_vod__c).add(budgetTransaction);
            } else {
                territoryBudgetToAssociatedTransactions.put(budgetTransaction.Territory_Budget_vod__c, new List<Territory_Budget_Transaction_vod__c>{ budgetTransaction });
            }
        }

        for (Id territoryBudgetId : territoryBudgets.keySet()) {

            List<Territory_Budget_Transaction_vod__c> associatedTransactions = territoryBudgetToAssociatedTransactions.get(territoryBudgetId);
            if (associatedTransactions != null) {
                Date maxTransactionDate = null;
                Double sumValue = null;
                Double sumQuantity = null;
                // we can't directly access this field but we CAN assume in a multicurrency org that every record has a CurrencyIsoCode
                String budgetCurrencyIsoCode = (String) territoryBudgets.get(territoryBudgetId).get('CurrencyIsoCode');

                for (Territory_Budget_Transaction_vod__c associatedTransaction : associatedTransactions) {
                    maxTransactionDate = getMaxDateForTransactions(maxTransactionDate, associatedTransaction);
                    sumValue = getValueSumOfTransactions(sumValue, budgetCurrencyIsoCode, associatedTransaction);
                    sumQuantity = getQuantitySumOfTransactions(sumQuantity, associatedTransaction);
                }

                Territory_Budget_vod__c territoryBudgetObj = territoryBudgets.get(territoryBudgetId);
                territoryBudgetObj.Last_Transaction_vod__c = maxTransactionDate;
                // we know that Start_Value_vod__c is of the same currency iso as its budget record
                territoryBudgetObj.Current_Value_vod__c = nullSafeAddition(territoryBudgetObj.Start_Value_vod__c, sumValue);
                territoryBudgetObj.Current_Quantity_vod__c = nullSafeAddition(territoryBudgetObj.Start_Quantity_vod__c, sumQuantity);
            } else {
                // if no transactions exist for the budget, we want to clear the "rollup" transaction values on the budget 
                Territory_Budget_vod__c territoryBudgetObj = territoryBudgets.get(territoryBudgetId);
                territoryBudgetObj.Last_Transaction_vod__c = null;
                territoryBudgetObj.Current_Value_vod__c = null;
                territoryBudgetObj.Current_Quantity_vod__c = null;
            }
        }
        
        update territoryBudgets.values();
    }

    private Date getMaxDateForTransactions(Date maxDateSoFar, Territory_Budget_Transaction_vod__c associatedTransaction) {

        if (associatedTransaction.Transaction_Date_vod__c == null) {
            return maxDateSoFar;
        }

        if (maxDateSoFar == null) {
            return associatedTransaction.Transaction_Date_vod__c;
        } 

        if (associatedTransaction.Transaction_Date_vod__c > maxDateSoFar) {
            return associatedTransaction.Transaction_Date_vod__c;
        }

        return maxDateSoFar;
    }

    private Double getValueSumOfTransactions(Double sumValueSoFar, String budgetCurrencyIsoCode, Territory_Budget_Transaction_vod__c associatedTransaction) {

        if (associatedTransaction.Value_vod__c == null) {
            return sumValueSoFar;
        }

        String transactionCurrencyIsoCode = (String) associatedTransaction.get('CurrencyIsoCode');
        Double valueToAdd = (budgetCurrencyIsoCode != transactionCurrencyIsoCode) ? MultiCurrencyUtil.convertCurrency(
            transactionCurrencyIsoCode, 
            budgetCurrencyIsoCode, 
            associatedTransaction.Value_vod__c
        ) : associatedTransaction.Value_vod__c;

        if (sumValueSoFar == null) {
            return valueToAdd;
        }
        
        return sumValueSoFar + valueToAdd;
    }

    private Double getQuantitySumOfTransactions(Double sumQuantitySoFar, Territory_Budget_Transaction_vod__c associatedTransaction) {

        if (associatedTransaction.Quantity_vod__c == null) {
            return sumQuantitySoFar;
        }

        if (sumQuantitySoFar == null) {
            return associatedTransaction.Quantity_vod__c;
        }
        
        return sumQuantitySoFar + associatedTransaction.Quantity_vod__c;        
    }

    private Double nullSafeAddition(Decimal startingValue, Double sumValue) {

        if (startingValue == null && sumValue == null) {
            return null;
        }

        if (startingValue == null) {
            return sumValue;
        }

        if (sumValue == null) {
            return startingValue;
        }

        return sumValue + startingValue;
    }
}