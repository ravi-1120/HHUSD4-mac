public inherited sharing class VeevaGASSearchClause {
    private final Map<Schema.SObjectType, List<VeevaGASSearchCondition>> conditionsByObjectType;

    public VeevaGASSearchClause(List<VeevaGASSearchCondition> conditions) {
        conditionsByObjectType = getConditionsByObjectType(conditions);
    }

    public String generateSOSLClause(String objectName) {
        List<VeevaGASSearchCondition> objectConditions = getObjectConditions(objectName);
        Map<VeevaGASSearchExpressionKey, List<VeevaGASSearchCondition>> conditionsByExpressionKey = getConditionsByExpressionKey(objectConditions);

        List<String> expressions = new List<String>();
        for (VeevaGASSearchExpressionKey key : conditionsByExpressionKey.keySet()) {
            List<String> valuesForExpressionKey = getUniqueValues(conditionsByExpressionKey.get(key));
            String expression = generateExpression(key, valuesForExpressionKey);
            if (String.isNotBlank(expression)) {
                expressions.add(expression);
            }
        }
        return String.join(expressions, ' AND ');
    }

    private String generateExpression(VeevaGASSearchExpressionKey expressionKey, List<String> conditionsForExpressionKey) {
        if (expressionKey == null || conditionsForExpressionKey == null || conditionsForExpressionKey.isEmpty()) {
            return '';
        }

        String expressionString = '{0} {1} ({2})';
        String fieldName = expressionKey.fieldName;
        String operator = getOperator(expressionKey.operator);
        String expressionValues = String.join(conditionsForExpressionKey, ', ');
        return String.format(expressionString, new List<String>{ fieldName, operator, expressionValues });
    }

    private List<VeevaGASSearchCondition> getObjectConditions(String objectName) {
        List<VeevaGASSearchCondition> objectConditions = conditionsByObjectType.get(getObjectType(objectName));
        if (objectConditions == null) {
            objectConditions = new List<VeevaGASSearchCondition>();
        }
        return objectConditions;
    }

    private static List<String> getUniqueValues(List<VeevaGASSearchCondition> conditions) {
        Set<String> valueSet = new Set<String>();
        for (VeevaGASSearchCondition condition : conditions) {
            valueSet.add(condition.getValue());
        }
        return new List<String>(valueSet);
    }

    private static String getOperator(VeevaGASSearchConditionOperator operator) {
        switch on operator {
            when EQUALS {
                return 'IN';
            }
            when NOT_EQUALS {
                return 'NOT IN';
            }
            when INCLUDES {
                return 'INCLUDES';
            }
            when EXCLUDES {
                return 'EXCLUDES';
            }
            when else {
                return 'IN';
            }
        }
    }

    private static Schema.SObjectType getObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        Schema.SObjectType objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
        return objectType;
    }

    private static Map<Schema.SObjectType, List<VeevaGASSearchCondition>> getConditionsByObjectType(List<VeevaGASSearchCondition> conditions) {
        Map<Schema.SObjectType, List<VeevaGASSearchCondition>> conditionsByObjectType = new Map<Schema.SObjectType, List<VeevaGASSearchCondition>>();
        for (VeevaGASSearchCondition condition : conditions) {
            List<VeevaGASSearchCondition> objectConditions = conditionsByObjectType.get(condition.getObject());
            if (objectConditions == null) {
                objectConditions = new List<VeevaGASSearchCondition>();
                conditionsByObjectType.put(condition.getObject(), objectConditions);
            }
            objectConditions.add(condition);
        }
        return conditionsByObjectType;
    }

    private static Map<VeevaGASSearchExpressionKey, List<VeevaGASSearchCondition>> getConditionsByExpressionKey(
        List<VeevaGASSearchCondition> conditions
    ) {
        Map<VeevaGASSearchExpressionKey, List<VeevaGASSearchCondition>> conditionsByExpressionKey = new Map<VeevaGASSearchExpressionKey, List<VeevaGASSearchCondition>>();
        for (VeevaGASSearchCondition condition : conditions) {
            VeevaGASSearchExpressionKey expressionKey = condition.getExpressionKey();
            List<VeevaGASSearchCondition> expressionKeyConditions = conditionsByExpressionKey.get(expressionKey);
            if (expressionKeyConditions == null) {
                expressionKeyConditions = new List<VeevaGASSearchCondition>();
                conditionsByExpressionKey.put(expressionKey, expressionKeyConditions);
            }
            expressionKeyConditions.add(condition);
        }
        return conditionsByExpressionKey;
    }
}