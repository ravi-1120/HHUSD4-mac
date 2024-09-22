public class MSD_CORE_RequestCaseClone {

    @InvocableMethod()
    public static List<outputWrapper> sObjectClone(List<inputWrapper> iWrpList)
    {
        String query;
        List<outputWrapper> oWrpList = new List<outputWrapper>();
        List<String> childObjectsAPIName = new List<String>{'Case_Document_MVN__c','MSD_CORE_AE_Product__c'};
        Map<String,String> childMap = new Map<String,String>();
        Map<String,String> childSubMap = new Map<String,String>();
        String clonedInteractionCaseRecId;
        if(!iWrpList.isEmpty())
        { 
            outputWrapper ow = new outputWrapper();
            inputWrapper iw = iWrpList[0];
            Map<String, Schema.SObjectType> schemaObjMap = Schema.getGlobalDescribe();
            Schema.SObjectType sObjectTypeObj = schemaObjMap.get(iw.objectAPIName); 
            Schema.DescribeSObjectResult sObjectResult = sObjectTypeObj.getDescribe();
            List<String> fields = getSobjectFields(iw.objectAPIName,iw.fieldSetName);
            if(!iw.deepClone)
            {
            	query = 'SELECT '+String.join(fields,',')+' FROM '+iw.objectAPIName+' WHERE ID = \'' + iw.recordId +'\'' ;    
            }
            else
            { 
                for (Schema.ChildRelationship cr: sObjectResult.getChildRelationships()) 
                {
                    if(cr.getField().getDescribe().isAccessible()&& cr.getRelationshipName()!=null){
                        if(childObjectsAPIName.contains(String.valueof(cr.getChildSObject())))
                        {   
                            childMap.put(String.valueof(cr.getChildSObject()),String.valueof(cr.getRelationshipName()));
                            childSubMap.put(String.valueof(cr.getRelationshipName()),String.valueof(cr.getField())); 
                        }
                    }
                }
                List<String> subqueries = childSubQueries(iw.recordId,childMap,childSubMap,schemaObjMap);
                query ='SELECT ' + String.join(fields, ',')+','+String.join(subqueries, ',') +' FROM ' +iw.objectAPIName +' WHERE Id = \''+iw.recordId+'\'';                
            	
            }
            
            if(!String.isBlank(query))
            {
                try
                {
                    if(iw.objectAPIName.toUpperCase() == 'CASE' && iw.cloneType == 'New Interaction')
                    {
                        List<String> pfields = getSobjectFields(iw.objectAPIName,iw.parentFieldSetName);
                     	String query1 = 'SELECT '+String.join(pfields,',')+' FROM '+iw.objectAPIName+' WHERE ID = \'' + iw.parentRecordId +'\'' ;
                        try
                        {
                            Sobject orgInteractionCaseRecord = Database.query(query1);
                            Sobject clonedInteractionCaseRecord = orgInteractionCaseRecord.clone(false, false, false, false);
                            
                            clonedInteractionCaseRecord.put('MSD_CORE_Is_Cloned__c', true);
                            clonedInteractionCaseRecord.put('MSD_CORE_Org_Case_Cloned__c', (String)orgInteractionCaseRecord.get('CaseNumber'));
                            insert clonedInteractionCaseRecord;
                            clonedInteractionCaseRecId = clonedInteractionCaseRecord.Id;
                        }
                        catch(Exception e)
                        {
                            ow.oRecordId = null;
                            ow.outputMessage = 'Error:'+e.getMessage();
                            ow.outputType = 'Error';
                            oWrpList.add(ow);
                        }        
                    }
                    Sobject orgRequestCaseRecord = Database.query(query);
                    Sobject clonedRequestCaseRecord = orgRequestCaseRecord.clone(false, false, false, false);
                    
                    if(iw.objectAPIName.toUpperCase() == 'CASE')
                    {
                    	clonedRequestCaseRecord.put('MSD_CORE_Is_Cloned__c', true);
                    	clonedRequestCaseRecord.put('MSD_CORE_Org_Case_Cloned__c', (String)orgRequestCaseRecord.get('CaseNumber'));
                        
                        if(iw.cloneType == 'New Interaction' && !String.isBlank(clonedInteractionCaseRecId) )
                        {
                         	clonedRequestCaseRecord.put('ParentId', clonedInteractionCaseRecId);
                            clonedRequestCaseRecord.put('Status', 'Open');
                        }
                    }
                    insert clonedRequestCaseRecord ;
                    List<sObject> childObjects =cloneChildRecs(orgRequestCaseRecord, clonedRequestCaseRecord, childMap  ,childSubMap);
                    insert childObjects;
                    
                    ow.oRecordId = clonedRequestCaseRecord.Id;
                    ow.outputMessage = 'Successfully Created';
                    ow.outputType = 'Success';
                    oWrpList.add(ow);
                }
                catch(Exception e)
                {
                    ow.oRecordId = null;
                    ow.outputMessage = 'Error:'+e.getMessage();
                    ow.outputType = 'Error';
                    oWrpList.add(ow);
                }      
            }
            else
            {
                ow.oRecordId = null;
                ow.outputMessage = 'Query not found.Contact Admin';
                ow.outputType = 'Error';
                oWrpList.add(ow);
                
            }
            /*if(!iw.deepClone)
            {
                try
                {
                    query = 'SELECT '+String.join(fields,',')+' FROM '+iw.objectAPIName+' WHERE ID = \'' + iw.recordId +'\'' ;
                    SObject parentRecord = Database.query(query);
                    SObject clonedRecord = parentRecord.clone(false, false, false, false);
                    if(iw.objectAPIName.toUpperCase() == 'CASE')
                    {
                    	clonedRecord.put('MSD_CORE_Is_Cloned__c', true);
                    	clonedRecord.put('MSD_CORE_Org_Case_Cloned__c', (String)parentRecord.get('CaseNumber'));
                    }
                    
                    insert clonedRecord ;
                    System.debug('clonedRecord'+clonedRecord.Id);
                    ow.oRecordId = clonedRecord.Id;
                    ow.outputMessage = 'Successfully Created';
                    ow.outputType = 'Success';
                    oWrpList.add(ow);
                }
                catch(Exception e)
                {
                    ow.oRecordId = null;
                    ow.outputMessage = 'Error:'+e.getMessage();
                    ow.outputType = 'Error';
                    oWrpList.add(ow);
                }  
            }
            else
            {
                Map<String,String> childMap = new Map<String,String>();
                Map<String,String> childSubMap = new Map<String,String>();
                for (Schema.ChildRelationship cr: sObjectResult.getChildRelationships()) 
                {
                    if(cr.getField().getDescribe().isAccessible()&& cr.getRelationshipName()!=null){
                        if(childObjectsAPIName.contains(String.valueof(cr.getChildSObject())))
                        {   
                            childMap.put(String.valueof(cr.getChildSObject()),String.valueof(cr.getRelationshipName()));
                            childSubMap.put(String.valueof(cr.getRelationshipName()),String.valueof(cr.getField())); 
                        }
                    }
                } 
                try{
                    List<String> subqueries = childSubQueries(iw.recordId,childMap,childSubMap,schemaObjMap);
                    query ='SELECT ' + String.join(fields, ',')+','+String.join(subqueries, ',') +' FROM ' +iw.objectAPIName +' WHERE Id = \''+iw.recordId+'\'';
                    Sobject parentRecord = Database.query(query);
                    String parentRecId = parentRecord.Id;
                    Sobject clonedRecord = parentRecord.clone(false, false, false, false);
                    if(iw.objectAPIName.toUpperCase() == 'CASE')
                    {
                    	clonedRecord.put('MSD_CORE_Is_Cloned__c', true);
                    	clonedRecord.put('MSD_CORE_Org_Case_Cloned__c', (String)parentRecord.get('CaseNumber'));
                    }
                    
                    insert clonedRecord ;
                    List<sObject> childObjects =cloneChildRecs(parentRecord, clonedRecord, childMap  ,childSubMap);
                    insert childObjects;
                    
                    ow.oRecordId = clonedRecord.Id;
                    ow.outputMessage = 'Successfully Created';
                    ow.outputType = 'Success';
                    oWrpList.add(ow);
                }
                catch(Exception e)
                {
                    ow.oRecordId = null;
                    ow.outputMessage = 'Error:'+e.getMessage();
                    ow.outputType = 'Error';
                    oWrpList.add(ow);
                }      
            }*/  
        }
        return oWrpList;
    }
    
    private static List<String> childSubQueries(String parentRecId, Map<String,String> childrelatedListObjects, Map<String,String> childrelatedListObjects1, Map <String, Schema.SObjectType> schemaMap)
    {
        List<String> subqueries = new List<String>();
        for(String childObject : childrelatedListObjects.keySet())
        {
            List<String> childFields = getSobjectFields(childObject,' ');
            if(!childFields.isEmpty())
            {
                String query = '(SELECT ' +String.join(childFields, ',')  + ' FROM ' + childrelatedListObjects.get(childObject)+' WHERE '+childRelatedListObjects1.get(childrelatedListObjects.get(childObject))+'= \''+parentRecId+'\''+')';
                subqueries.add(query);
            }
            
        }
        return subqueries;
    }
    
    private static List<sObject> cloneChildRecs(Sobject parent,Sobject child,Map<String , String> childRelatedListObjects,Map<String , String> childRelatedListObjects1)
    { 
        List<sObject> childObjects = new List<SObject>();
        for (String childObjectDefinition : childRelatedListObjects.values()) {
            List<sObject> parentRecords = parent.getSObjects(childObjectDefinition);
            if (parentRecords != null) {
                List<sObject> records = parentRecords.deepClone(false,false,false);
                for (sObject record : records) {
                    record.put(childRelatedListObjects1.get(childObjectDefinition), child.Id);
                }
                childObjects.addAll(records);
            }
        }
        return childObjects;
    }
    
    private static List<String> getSobjectFields(String ObjectApiName,String fieldSetName)
    {
        List<String> fields = new List<String>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectApiName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        if(!String.isBlank(fieldSetName))
        {
            Map<String, Schema.FieldSet> fieldSetMap = DescribeSObjectResultObj.FieldSets.getMap();
            Schema.FieldSet fieldSetObj = fieldSetMap.get(fieldSetName);
            List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
            for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList)
            {
                fields.add(fieldSetMemberObj.getFieldPath());
            } 
        }
        else 
        {
            Map<String, Schema.SobjectField> fieldsMap = DescribeSObjectResultObj.fields.getMap();
            Set<String> fieldsKeySet = fieldsMap.keySet();
            List<String> listkeySet = new List<String>(fieldsKeySet);
            fields.addAll(listkeySet);
            
        }
        fields.sort();
        return fields;
        
    }
    public class inputWrapper
    {
        @InvocableVariable(required = true)
        public String recordId;
        @InvocableVariable(required = true)
        public String objectAPIName; 
        @InvocableVariable(required = true)
        public Boolean deepClone; 
        @InvocableVariable(required = true)
        public String cloneType; 
        @InvocableVariable(required = true)
        public String fieldSetName;
        @InvocableVariable
        public String parentFieldSetName;
        @InvocableVariable(required = true)
        public String parentRecordId; 
    }
    
    public class outputWrapper
    {
        @InvocableVariable
        public String outputMessage;
        @InvocableVariable
        public String outputType;
        @InvocableVariable
        public String oRecordId;
    }
    
}