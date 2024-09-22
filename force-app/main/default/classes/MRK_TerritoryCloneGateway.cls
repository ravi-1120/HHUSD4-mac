public class MRK_TerritoryCloneGateway{
 
     /*
       KRB - 4/25/2014 REL 5.1 - Object Data Access Methods for the 
             Territory_Clone_MRK__c Object. 
     */
    
    public static Map<Id, Territory_Clone_MRK__c> retrieveAllTerritoriesByIdList(List<Id> terrCloneIdList){
        
        //What will be returned...
        Map<Id, Territory_Clone_MRK__c> tempMap = new Map<Id, Territory_Clone_MRK__c>();
        
        tempMap = new Map<Id, Territory_Clone_MRK__c>(
                    [
                       SELECT Id, 
                              Name,
                              Parent_Territory_SFID_MRK__c,
                              Territory_SFID_MRK__c 
                       FROM   Territory_Clone_MRK__c
                       WHERE  Id in: terrCloneIdList
                    ]
                   );
        
       return tempMap;
    }
   
     /*
     * KRB - 3/20/2014 - REL 5.0
     */
    
    public static Map<Id, Territory_Clone_MRK__c> retrieveCloneTerritoriesMapByTerritorySFIDList(List<Id> terrIds){
        
        //What will be returned...
        Map<Id, Territory_Clone_MRK__c> tempMap = new Map<Id, Territory_Clone_MRK__c>();
        
        tempMap = new Map<Id, Territory_Clone_MRK__c>(
                    [
                       SELECT Id, 
                              Name,
                              Parent_Territory_SFID_MRK__c,
                              Territory_SFID_MRK__c 
                       FROM   Territory_Clone_MRK__c
                       WHERE  Territory_SFID_MRK__c in: terrIds
                    ]
                   );
        
       return tempMap;
    }
    
    
    //Territory_SFID_MRK__c FROM Territory_Clone_MRK__c
        /*
     * KRB - 3/20/2014 - REL 5.0
     */
    
    public static Map<id,String> retrieveMapAllCloneTerritoriesOrigSFIDAndName(){
        
        Map<id,String> tempMap = new Map<id,String>();
        
        List<Territory_Clone_MRK__c> tempList = new List<Territory_Clone_MRK__c>();
        
        tempList = new List<Territory_Clone_MRK__c>(
                    [
                        SELECT Territory_SFID_MRK__c, Name
                        FROM Territory_Clone_MRK__c
                    ]
                   );
        
        for (Territory_Clone_MRK__c tcRec : tempList){
            tempMap.put(tcRec.Territory_SFID_MRK__c, tcRec.Name);
        }
        
       return tempMap;
    }

    
    
    /*
     * KRB - 3/20/2014 - REL 5.0
     */
   /* 
    public static Map<id, list<id>> retrieveAllTerritoriesWithParentChildRelationship(){
        
        map<id, list<id>> parentIdToChildrenIdListTerrClonedMap = new map<id, list<id>>();
        
        List<Territory_Clone_MRK__c> tempMap = new List<Territory_Clone_MRK__c>();
        
        tempMap = new List<Territory_Clone_MRK__c>(
                    [
                        SELECT Id, Territory_SFID_MRK__c, Parent_Territory_SFID_MRK__c, Name
                        FROM Territory_Clone_MRK__c
                    ]
                   );
        
        
        for(Territory_Clone_MRK__c terr : tempMap){
   
           if(parentIdToChildrenIdListTerrClonedMap.get(terr.Parent_Territory_SFID_MRK__c) == null){
                parentIdToChildrenIdListTerrClonedMap.put(terr.Parent_Territory_SFID_MRK__c, new list<id>{terr.Territory_SFID_MRK__c});
              }else{
                parentIdToChildrenIdListTerrClonedMap.get(terr.Parent_Territory_SFID_MRK__c).add(terr.Territory_SFID_MRK__c);
              }
           }
 
        
       return parentIdToChildrenIdListTerrClonedMap;
    }
*/
}