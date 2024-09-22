/**************************************************************************************
 * Trigger: RT
 * Date: 09/07/2012
 * Author: KRB
 * Description: A RecordType Utility Class.
 * 
 * History:
 *  09/07/2012 KRB - Original Creation. 
 *  04/22/2013 KRB - Added Call Records Types.
 */





public class RT {
    /**
     * KRB - 09/07/2012 - A RecordType Utility Class.
     */
    public enum Name {
        //Add the DeveloperName, comma separated list...
        Editable,
        Read_Only,
        Rep_Enabled,
        Headquarters,
        Headquarters_Editable,
        CallReport_vod,
        MSD_CORE_Remote_Detail, 
        Event_vod,
        
        //DCR Related    
        Account_vod,
        Child_Account_vod,
        Address_vod,
            
        //Child Account Record Types
        Customer_Master_Relationship_MRK,
        Rep_Generated_Relationship_MRK,
            
        //Account Record Types:
        Hospital_vod,
        Organization_vod,
        Pharmacy_vod,
        HBP,
        HCP
 
    }
    
    private static final String SEPARATOR = '::::';
    private static Map<String, Id> CACHE;
    /**
     * Get the Id that can be set on or compared with an SOBject's RecordTypeId field.
     * Backed by a cache of all record type ids for the duration of a request.
     */
    public static Id getId(SObjectType sobType, Name developerName) {
        if (CACHE == null) {
            CACHE = new Map<String, Id>();
            for (RecordType rt :  [
                  select Id, SObjectType, DeveloperName
                  from RecordType
                  where DeveloperName in :getNames()
                  ]) {
                CACHE.put(rt.SObjectType + SEPARATOR + rt.DeveloperName, rt.Id);
            }
        }
        return CACHE.get(String.valueOf(sobType) + SEPARATOR + developerName.name());
    }
    private static Set<String> getNames() {
      Set<String> names = new Set<String>();
      for (Name name : Name.values()) {
        names.add(name.name());
      }
      return names;
    }
    
    public static List<RecordType> retrieveRecordTypeListforObjectType(String objectType){
              
        List<RecordType> recordType = new List<RecordType>( 
          [SELECT Id, SObjectType, DeveloperName
           FROM   RecordType
           WHERE  SObjectType =: objectType
          ]);
       
        return recordType;
    }
    
}