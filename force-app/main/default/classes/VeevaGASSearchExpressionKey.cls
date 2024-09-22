public inherited sharing class VeevaGASSearchExpressionKey {
    public final String objectName { get; private set; }
    public final String fieldName { get; private set; }
    public Boolean isImplicitFilter { get; private set; }
    public final VeevaGASSearchConditionOperator operator { get; private set; }

    public VeevaGASSearchExpressionKey(String objectName, String fieldName, Boolean isImplicitFilter, VeevaGASSearchConditionOperator operator) {
        this.objectName = objectName;
        this.fieldName = fieldName;
        this.operator = operator;
        this.isImplicitFilter = isImplicitFilter;
    }

    public boolean equals(Object obj) {
        if (obj instanceof VeevaGASSearchExpressionKey) {
            VeevaGASSearchExpressionKey other = (VeevaGASSearchExpressionKey) obj;
            return this.objectName.equalsIgnoreCase(other.objectName) &&
                this.fieldName.equalsIgnoreCase(other.fieldName) &&
                (this.isImplicitFilter == other.isImplicitFilter) &&
                this.operator.equals(other.operator);
        }
        return false;
    }

    public Integer hashCode() {
        Integer result = this.objectName.toLowerCase().hashCode() + this.fieldName.toLowerCase().hashCode() + this.operator.hashCode();
        result = 31 * result + (isImplicitFilter ? 1 : 0);
        return result;
    }
}