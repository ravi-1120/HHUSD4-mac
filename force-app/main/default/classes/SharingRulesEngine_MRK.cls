public class SharingRulesEngine_MRK{

   /*
      Creates new Sharing Rule sObject 
   */
    
    public sObject createShareObj(String objectType, String parentId,
                                 String userOrGroupId, String accessLevel,
                                 String rowCause){
   
       sObject shrObj  = DynamicSharingSObjectCreator.createObject(objectType);
       shrObj.put('ParentId', parentId);
       shrObj.put('UserOrGroupId', userOrGroupId);
       shrObj.put('AccessLevel', accessLevel);
       
       if (rowCause != null || rowCause != ''){
          shrObj.put('RowCause', rowCause); //concatenate the ShareRule Name.
       }                           
       return shrObj;

   }    
    
    
 
    
    
}