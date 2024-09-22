/**
 * @description MSD_CORE_Pipeline
 */
public without sharing class MSD_CORE_Pipeline {

    /**
     * @description getPhaseDetail
     * @return List<MSD_CORE_Study_detail__c>
     * @param PhaseType
     * @param pageSize
     * @param offset
     * @param searchKey
     * @param therapeuticArea
     * @param sortby
     */
    @AuraEnabled()
    //public static List<MSD_CORE_Study_detail__c> getPhaseDetail(String PhaseType,Integer pageSize, Integer offset, String searchKey, String therapeuticArea, String sortby){// Used this method for Bug_Web_019 and we are not using method getPhaseDetail1
    public static List<MSD_CORE_Study_detail__c> getPhaseDetail(String searchKey, String sortby){// Used this method for Bug_Web_019 and we are not using method getPhaseDetail1
        List<MSD_CORE_Study_detail__c> studyList= new List<MSD_CORE_Study_detail__c>();
        string key = '';
        
        if(!String.isBlank(searchKey)){
            key =' \''+'%' + searchKey +'%' +'\'';
            searchKey =' AND ( Name like' +  key + ' OR MSD_CORE_Therapeutic__c  like ' + key + ' ) ';
        }

        String soql = 'SELECT ID,Name,MSD_CORE_Descrption__c, MSD_CORE_Therapeutic__c, MSD_CORE_Medical_Therapeutic_Area__r.Name, MSD_CORE_Phase__c,MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_Text_color__c,MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_BG_color__c, MSD_CORE_Tumor__r.Name, MSD_CORE_View_Resource_URL__c FROM MSD_CORE_Study_detail__c ';
        soql += ' WHERE Id != null '+ searchKey;
        soql +=  ' ORDER BY '+ sortBy + ' ASC ';
        
        studyList = Database.query(soql);
        return studyList;
    }

    /**
     * @description getPhaseCount
     * @return List<MSD_CORE_Study_detail__c>
     */
   @AuraEnabled(cacheable=true)
   public static list<MSD_CORE_Study_detail__c> getPhaseCount() {
       String strSqlQuery = 'Select count(id) , MSD_CORE_Phase__c  from MSD_CORE_Study_detail__c  GROUP BY MSD_CORE_Phase__c';
       return Database.query(strSqlQuery);
   }

   /**
     * @description getPhaseDetail
     * @return List<MSD_CORE_Study_detail__c>
     * @param PhaseType
     * @param pageSize
     * @param offset
     * @param searchKey
     * @param therapeuticArea
     * @param sortby
     */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Study_detail__c> getStudyDetails(
        String searchKey, 
        String therapeuticArea, 
        String sortBy, 
        Integer pageSize, 
        Integer offset, 
        String resourceType
    ) {
        String soql = 'SELECT ID, Name, MSD_CORE_Descrption__c, MSD_CORE_Therapeutic__c, '
                    + 'MSD_CORE_Resource_Type__c, MSD_CORE_Medical_Therapeutic_Area__r.Name, '
                    + 'MSD_CORE_Phase__c, MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_Text_color__c, '
                    + 'MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_BG_color__c, MSD_CORE_Tumor__r.Name '
                    + 'FROM MSD_CORE_Study_detail__c '
                    + 'WHERE MSD_CORE_Resource_Type__c = :resourceType ';
        
        if (!String.isBlank(searchKey)) {
            String key = '%' + searchKey + '%';
            soql += 'AND (Name LIKE :key OR MSD_CORE_Therapeutic__c LIKE :key) ';
        }
        
        // Filter by therapeutic area if provided
        if (!String.isBlank(therapeuticArea)) {
            soql += 'AND MSD_CORE_Therapeutic__c = :therapeuticArea ';
        }

        // Validate and apply sorting
        Set<String> validSortFields = new Set<String>{'Name', 'MSD_CORE_Therapeutic__c', 'CreatedDate'};
        if (String.isBlank(sortBy) || !validSortFields.contains(sortBy)) {
            sortBy = 'Name'; // Default sorting if invalid or empty
        }
        
        soql += 'ORDER BY ' + sortBy + ' ASC LIMIT :pageSize OFFSET :offset';

        return Database.query(soql);
    }


 }