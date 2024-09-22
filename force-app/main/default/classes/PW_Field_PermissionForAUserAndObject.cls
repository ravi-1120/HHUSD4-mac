public class PW_Field_PermissionForAUserAndObject
{  
    Id UserId{get;set;}
    List<String> lstQualifiedFieldNames {get;set;}
    String ObjectName {get; set;}
    
    List<UserFieldAccess> lstUserFieldAccess {get;set;}
    Map<String,UserFieldAccess> fieldAccessMap {get;set;}

    public void Initialize(Id usrId, List<String> lstQualFieldNames, String ObjName )   
    {
        UserId = usrId;
        lstQualifiedFieldNames = lstQualFieldNames;
        ObjectName = ObjName;
 
        fieldAccessMap = new Map<String,UserFieldAccess>();
        lstUserFieldAccess = new List<UserFieldAccess> ();

        for(UserFieldAccess ufa : [SELECT Durableid, FieldDefinition.QualifiedApiName, User.Id, IsAccessible,IsCreatable,IsUpdatable FROM UserFieldAccess
                WHERE FieldDefinition.EntityDefinition.QualifiedApiName = :ObjectName
                AND FieldDefinition.QualifiedApiName In :lstQualifiedFieldNames  
                AND User.Id= :UserId]){
            lstUserFieldAccess.add(ufa);
            fieldAccessMap.put(ufa.FieldDefinition.QualifiedApiName,ufa);
        }


        
    }   
    
    public UserFieldAccess GetAccessUsingFieldName(String FieldName)
    {
        if(fieldAccessMap.containsKey(FieldName)){
  
            UserFieldAccess ufa = fieldAccessMap.get(FieldName);
            
            return ufa;
            
        }
        
        return null;
  
    }
    
    public Boolean AreAllFieldsEditable()
    {
       Boolean flag = true;
        
        if(lstUserFieldAccess.Size()<=0)
        {
            return false;
        }
        
        if(lstUserFieldAccess.Size()!=lstQualifiedFieldNames.Size() )  
        {
            return false;
        }
        
        
        for (UserFieldAccess ufa: lstUserFieldAccess )
        {
        
            if(ufa.IsUpdatable == false)
            {
                flag = false;
                break;
            }
            
        }
        
        
        return flag;
    
    }


}