public class KnowledgeNewContrl {
    @AuraEnabled        
    public static Map<String, String> fetchRecordTypeValues(String sObjectType){ 
        Map<String, String> mapRTs = new Map<String, String>();
        List<Schema.RecordTypeInfo> recordtypes = Schema.getGlobalDescribe().get(sObjectType).getDescribe().getRecordTypeInfos();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master' && rt.getName().trim() != '' & rt.isAvailable() && rt.getName() != 'Template')
            mapRTs.put(rt.getRecordTypeId(), rt.getName());
        }         
        return mapRTs;
    }
    
	@AuraEnabled
    public static Knowledge__kav getTemplateValues(String rtId)
    {
        //Template Articles naming convention --> RecordTypeName<space>Template.
        //Ex: If Record Type Name = PQC FAQ , then Title of Template article should be PCC FAQ Template
        String strTemplateName = [SELECT Name FROM RecordType WHERE Id = :rtID].Name + ' Template';
        //List<Knowledge__kav> lstKav = Database.query('SELECT '+ strSelectedFields +' FROM Knowledge__kav WHERE Title = :strTemplateName LIMIT 1];
        List<Knowledge__kav> lstKav = Database.query('SELECT ' + getFieldsToClone() + ' FROM Knowledge__kav WHERE Title = :strTemplateName AND RecordType.Name = \'Template\' LIMIT 1');
        System.debug('lstKav -->'+lstKav);
        if(!lstKav.isEmpty())
        {
            lstKav[0].Id = null;
            Knowledge__kav kaToPopulate = lstKav[0];
            return kaToPopulate;
        }
        return null;
    }
    
     @AuraEnabled
    public static String getProfileName(){
        User userList = [SELECT Id, Profile.Name
                               FROM User 
                               WHERE Id =: UserInfo.getUserId()];
        
        return userList.Profile.Name;
    }
    
    public static String getFieldsToClone()
    {
        list<string> lstSelectFields = new list<string>();
        String strSelectedFields = '';
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Knowledge__kav').getDescribe().Fields.getMap();
        if (fieldMap != null)
        {
            List<String> lstFieldsToExclude = new List<String>{'Id', 
                										'ArticleNumber', 
                										'MasterVersionId',
                										'MSD_CORE_KnwlArtCat__c', 
                                                        'MSD_CORE_Audience__c', 
                                                        'RecordTypeId', 
                                                        'ArticleCreatedDate', 
                                                        'CreatedDate', 
                                                        'LastModifiedDate', 
                                                        'OwnerId', 
                                                        'Title', 
                                                        'UrlName',
                                                        'PublishStatus',
                                                        'ArticleCreatedById',
                                                        'CreatedById',
                                        				'LastModifiedById','IsVisibleInPkb','IsVisibleInCsp','IsVisibleInPrm','Summary'
                                                        };
            for (Schema.SObjectField objFieldToken : fieldMap.values())
            { // loop through all field tokens (objFieldToken)
                Schema.DescribeFieldResult objFieldDes = objFieldToken.getDescribe(); // describe each field (objFieldDes)
                if (!lstFieldsToExclude.contains(objFieldDes.getName()) && objFieldDes.isCreateable())
                {
                    lstSelectFields.add(objFieldDes.getName());
                }
            }
        }
        if (!lstSelectFields.isEmpty())
        {
            for (string strField : lstSelectFields)
            {
                strSelectedFields += strField + ',';
            }
            strSelectedFields = strSelectedFields.removeEnd(',');
        }
        return strSelectedFields;
    }
}