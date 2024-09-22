public class MRK_VisibilityRuleEngine{
    
    //Map that contains the Sharing Rule Matrix. 
    
    /*
      Creates a populated Sharing Rule sObject ready for insert. 
   */
    
    public static sObject createShareObj(String objectType, Id parentId,
                                  Id userOrGroupId, String accessLevel,
                                  String rowCause){
   
       sObject shrObj  = DynamicSharingSObjectCreator.createObject(objectType);
       shrObj.put('ParentId', parentId);
       shrObj.put('UserOrGroupId', userOrGroupId);
       shrObj.put('AccessLevel', accessLevel);
       
       if (rowCause != null || rowCause != ''){
          shrObj.put('RowCause', rowCause); //concatenate the ShareRule Name.
       }                           
       
       System.debug('VisibilityDebug 4.0: Creating the Share Objects with the Following Values:');   
       System.debug('VisibilityDebug 4.0: ParentId: ' + parentId ); 
       System.debug('VisibilityDebug 4.0: UserOrGroupId: ' + userOrGroupId ); 
       System.debug('VisibilityDebug 4.0: AccessLevel: ' + AccessLevel ); 
       System.debug('VisibilityDebug 4.0: RowCause: ' + rowCause ); 
                                   
       return shrObj;

   }    
    
   /* creates an Share sObject at runtime given the appropriate share type. */
    
   public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        if (targetType == null) {
            // TODO: throw an exception
        }
        
        // Instantiate an sObject with the type passed in as an argument
        //  at run time.
        return targetType.newSObject(); 
    }
   


}