public class PW_PermisionForEMLocalDateTimeFeature
{

    PW_Field_PermissionForAUserAndObject eventpermissions {get;set;}
    PW_Field_PermissionForAUserAndObject medicaleventpermissions {get;set;}
    PW_Field_PermissionForAUserAndObject Preferencespermissions {get;set;}
    
    PW_CRUD_PermissionsForAUserAndObject eventCRUDpermissions {get;set;}
    PW_CRUD_PermissionsForAUserAndObject medicalEventCRUDpermissions {get;set;}
    PW_CRUD_PermissionsForAUserAndObject preferencesCRUDpermissions {get;set;}
    
    
    public Boolean IsNewFeatureOn{get;set;}
    
    public PW_PermisionForEMLocalDateTimeFeature(Boolean autoInitialize, Id userID)
    {
        if(autoInitialize)
        {
        
            Initialize(userID, Pw_Constants.FLS_CHECK_FIELD_LIST_EVENT, Pw_Constants.FLS_CHECK_FIELD_LIST_MEDICAL_EVENT,Pw_Constants.FLS_CHECK_FIELD_LIST_PREFERENCE);
                
        }
        
    }
    
    public void Initialize(Id UserID, List<string> fieldslistEvent, List<string> fieldslistEventMedicalEvent, List<string> fieldsPreferencesList)
    {
        
        
        //Step 1
        InitializeCRUDPermissions(UserID);
        
        //Step 2
        InitializeFLSPermissions(UserID, fieldslistEvent, fieldslistEventMedicalEvent, fieldsPreferencesList );
        
        // Step 3
        InitializeIsNewFeatureVar();
                
          
        
    
    }
    
    void InitializeCRUDPermissions(Id UserID)
    {
    
        //Initializing CRUD Permissions
        eventCRUDpermissions= new PW_CRUD_PermissionsForAUserAndObject();
        eventCRUDpermissions.Initialize('EM_Event_vod__c', UserID);
        
        medicalEventCRUDpermissions= new PW_CRUD_PermissionsForAUserAndObject();
        medicalEventCRUDpermissions.Initialize('Medical_Event_vod__c', UserID);
        
        preferencesCRUDpermissions= new PW_CRUD_PermissionsForAUserAndObject();
        preferencesCRUDpermissions.Initialize('Preferences_vod__c', UserID);
        
    }
    
    void InitializeFLSPermissions(Id UserID, List<string> fieldslistEvent, List<string> fieldslistEventMedicalEvent, List<string> fieldsPreferencesList)
    {
    
        //Initializing FLS Permissions
        eventpermissions = new PW_Field_PermissionForAUserAndObject ();
        eventpermissions.initialize(UserID, fieldslistEvent , 'EM_Event_vod__c');
        
        medicaleventpermissions = new PW_Field_PermissionForAUserAndObject ();
        medicaleventpermissions.initialize(UserID, fieldslistEventMedicalEvent , 'Medical_Event_vod__c');
       
        
        Preferencespermissions = new PW_Field_PermissionForAUserAndObject ();
        Preferencespermissions.initialize(UserID, fieldsPreferencesList, 'Preferences_vod__c');
        
    }
    
    void InitializeIsNewFeatureVar()
    {
        IsNewFeatureOn = false;
        
        System.Debug ('Event CRUD' + eventCRUDpermissions.createPermission + eventCRUDpermissions.readPermission + eventCRUDpermissions.updatePermission);
        System.Debug ('Medical Event CRUD' + medicalEventCRUDpermissions.createPermission + medicalEventCRUDpermissions.readPermission + medicalEventCRUDpermissions.updatePermission);
        System.Debug (' Preferences CRUD' + preferencesCRUDpermissions.readPermission + preferencesCRUDpermissions.updatePermission);
        System.Debug ('FLS event'+ eventpermissions.AreAllFieldsEditable());         
        System.Debug ('FLS medical event'+medicaleventpermissions.AreAllFieldsEditable());
        System.Debug ('FLS Preferences' +Preferencespermissions.AreAllFieldsEditable());
        
        
        
        // CHECK  Event CRUD
        if(eventCRUDpermissions.createPermission && eventCRUDpermissions.readPermission && eventCRUDpermissions.updatePermission)
        {
            // CHECK  Medical Event CRUD
            
            if(medicalEventCRUDpermissions.createPermission && medicalEventCRUDpermissions.readPermission && medicalEventCRUDpermissions.updatePermission)
            {
            
                // CHECK Preferences CRUD
                
                if(preferencesCRUDpermissions.readPermission && preferencesCRUDpermissions.updatePermission)
                {
                
                    // Check Field Level Security
        
                    if(eventpermissions.AreAllFieldsEditable() && medicaleventpermissions.AreAllFieldsEditable() && Preferencespermissions.AreAllFieldsEditable() )
                    {
                        IsNewFeatureOn = true;
                    }
                    else
                    {
                        IsNewFeatureOn = false;
                    }
                }
            }
        }
        
    }   
  

}