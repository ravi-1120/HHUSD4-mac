public class PW_CRUD_PermissionsForAUserAndObject
{
    public Boolean createPermission {get;set;}
    public Boolean readPermission {get;set;}
    public Boolean updatePermission {get;set;}
    public Boolean deletePermission {get;set;}
    public String objType {get;set;}
    public Id userID {get;set;}

    public void Initialize(String objType, Id userID)
    {
        createPermission = false;
        readPermission = false;
        updatePermission = false;
        deletePermission = false;
        
        List<ObjectPermissions> objectPermissionrecord =  [SELECT ParentId, Parent.Name, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, SObjectType FROM ObjectPermissions WHERE SObjectType = :objType AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE Assignee.Id = :userID)];
        
        if(objectPermissionrecord.Size()<=0)
        {
            return;
        }
        
        for (ObjectPermissions permission: objectPermissionrecord)
        {
            if(permission.PermissionsCreate)
            {
                createPermission = true;
            }
            if(permission.PermissionsRead)
            {
                readPermission  =   true;
            }
            if(permission.PermissionsEdit)
            {
                updatePermission = true;
            }
            if(permission.PermissionsDelete)
            {
                deletePermission = true;
            }
            
        }
        
    }   

}