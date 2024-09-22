public inherited sharing abstract class VeevaGASConfigBase {

    protected VeevaGASColumnsConfig columnConfig;
    
    public abstract String getMaxRowLimit();
    public abstract List<Map<String, String>> getResultSetColumnInfo();
    
    protected VeevaGASColumnsConfig getConfiguredColumns(String customSettingName, Map<String, List<String>> baseFields, List<String> defaultResultFields, String firstColumn, Integer maxColumnsLimit){
        VeevaGASColumnsConfig columnConfig;
        Map<String, List<String>> configuredColumns = new Map<String, List<String>>();
        List<String> resultSetColumns = new List<String>();
        Set<String> uniqueFields = new Set<String>();
        String columnsStr = getCustomSettingValue(customSettingName);
        Boolean customColumnsAdded = false;
        //Extract columns from custom setting value
        List<String> columns = String.isNotBlank(columnsStr) ? columnsStr.split(';') : new List<String>();
        if (String.isNotBlank(firstColumn) && addToConfiguredColumns(configuredColumns, firstColumn)){
            resultSetColumns.add(firstColumn);
            uniqueFields.add(firstColumn.toLowerCase());
        }
        for (String column : columns){
            //Separate Object and Column Name
            if (!uniqueFields.contains(column.toLowerCase().trim()) && addToConfiguredColumns(configuredColumns, column)) {
                resultSetColumns.add(column.trim());
                uniqueFields.add(column.toLowerCase().trim());
                customColumnsAdded = true;
            }
            //Limit custom columns
            if (maxColumnsLimit != 0 && (resultSetColumns.size() == maxColumnsLimit)){
                break;
            }
        }
        //Set default fields if none configured
        if (!customColumnsAdded){
            for(String defaultField : defaultResultFields){
                if (addToConfiguredColumns(configuredColumns, defaultField)){
                    resultSetColumns.add(defaultField);
                }
            }
        }
        columnConfig = setUpCustomizedColumns(resultSetColumns, configuredColumns, baseFields);
        return columnConfig;
    }

    private String getCustomSettingValue(String customSettingName) {
        Global_Account_Search_Settings_vod__c gasSettings = Global_Account_Search_Settings_vod__c.getInstance();
        String customSettingValue = String.valueOf(gasSettings.get(customSettingName));
        if (String.isNotBlank(customSettingValue)) {
            // Message_Key;;Message_Category
            List<String> veevaMessageInfo = customSettingValue.split(';;');
            String veevaMessageText = null;
            if (veevaMessageInfo.size() == 2) {
                customSettingValue = VeevaMessageController.getMsgWithDefault(veevaMessageInfo[0], veevaMessageInfo[1], null);
            }
        }
        return customSettingValue;
    }

    private VeevaGASColumnsConfig setUpCustomizedColumns(List<String> orderedColumns, Map<String, List<String>> configuredColumns, Map<String, List<String>> baseFields){
        VeevaGASColumnsConfig columnConfig = new VeevaGASColumnsConfig(getRequiredObjectFieldNames(baseFields), orderedColumns);
        for (String objectName : baseFields.keySet()){
            List<String> objectQryFields = new List<String>();
            List<String> objectBaseFields = baseFields.get(objectName);
            List<String> objectConfiguredFields = new List<String>();
            if(configuredColumns.containsKey(objectName)){
                objectConfiguredFields = configuredColumns.get(objectName);
            }
            for (String field : objectBaseFields){
                if (!objectConfiguredFields.contains(field)){
                    objectQryFields.add(field);
                }
            }
            objectQryFields.addAll(objectConfiguredFields);
            //set the query fields for this object in the column config object
            columnConfig.addObjectFields(objectName, objectQryFields);
        }
        return columnConfig;
    }

    private Boolean addToConfiguredColumns(Map<String, List<String>> configuredColumns, String column){
        Boolean columnAdded = false;
        List<String> columnNameArr = column != null ? column.split('\\.') : new List<String>();
        if (columnNameArr.size() >= 2 && String.isNotBlank(columnNameArr[0]) && String.isNotBlank(columnNameArr[1])) {
            String objectName = columnNameArr[0].trim().toLowerCase();
            List<String> fieldsForObject = configuredColumns.get(objectName);
            if (fieldsForObject == null) {
                fieldsForObject = new List<String>();
            }
            fieldsForObject.add(column.trim());
            configuredColumns.put(objectName, fieldsForObject);
            columnAdded = true;
        }
        return columnAdded;
    }

    public List<String> getAccountObjectFields(){
        List<String> allAccountObjectFields = columnConfig.getObjectResultFields('account');
        return allAccountObjectFields;
    }

    public List<String> getAddressObjectFields(){
        List<String> allAddressObjectFields = columnConfig.getObjectResultFields('address_vod__c');
        return allAddressObjectFields;
    }

    public List<String> getAccountQueryFields(){
        List<String> allAccountQueryFields = columnConfig.getObjectQueryFields('account');
        return allAccountQueryFields;
    }

    public List<String> getAddressQueryFields(){
        List<String> allAddressQueryFields = columnConfig.getObjectQueryFields('address_vod__c');
        return allAddressQueryFields;
    }

    public List<String> getParentAccountAddressFieldsForQuery(){
        return columnConfig.getParentAddressFields(true);
    }

    public List<String> getParentAccountAddressFields(){
        return columnConfig.getParentAddressFields(false);
    }
    
    private Map<String, List<String>> getRequiredObjectFieldNames(Map<String, List<String>> baseFields){
        Map<String, List<String>> objReqdFields = new Map<String, List<String>>();
        for (String objectName : baseFields.keySet()){
            List<String> fieldNames = new List<String>();
            for (String field : baseFields.get(objectName)){
                fieldNames.add(field.split('\\.')[1]);
            }
            objReqdFields.put(objectName, fieldNames);
        }
        return objReqdFields;
    }
}