public class DynamicSharingSObjectCreator{
    
      public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
         
        // Instantiate an sObject with the type passed in as an argument
        //  at run time.
        return targetType.newSObject(); 
    }
    
}